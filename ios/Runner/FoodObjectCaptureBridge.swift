import Flutter
import RealityKit
import SwiftUI
import UIKit

final class FoodObjectCaptureBridge: NSObject {
  static let channelName = "food_object_capture"

  private weak var rootViewController: UIViewController?
  private var pendingResult: FlutterResult?
  @available(iOS 17.0, *)
  private var activeCoordinator: FoodObjectCaptureCoordinator?

  init(rootViewController: UIViewController?) {
    self.rootViewController = rootViewController
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAvailability":
      Task { @MainActor in
        result(Self.availabilityPayload())
      }
    case "startCapture":
      Task { @MainActor in
        startCapture(result: result)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  @MainActor
  private func startCapture(result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "capture_in_progress",
          message: "A native object capture session is already running.",
          details: nil
        )
      )
      return
    }

    guard #available(iOS 17.0, *) else {
      result(
        FlutterError(
          code: "unsupported_ios",
          message: "Native food capture requires iOS 17 or later.",
          details: nil
        )
      )
      return
    }

    guard ObjectCaptureSession.isSupported else {
      result(
        FlutterError(
          code: "unsupported_device",
          message: "This iPhone does not support Apple's native Object Capture session.",
          details: nil
        )
      )
      return
    }

    guard let presenter = topViewController(from: rootViewController) else {
      result(
        FlutterError(
          code: "presentation_failed",
          message: "Unable to present the native capture screen.",
          details: nil
        )
      )
      return
    }

    pendingResult = result

    do {
      let coordinator = try FoodObjectCaptureCoordinator(
        onResolve: { [weak self] payload in
          self?.complete(with: payload)
        },
        onFailure: { [weak self] error in
          self?.fail(with: error)
        }
      )
      activeCoordinator = coordinator

      let controller = UIHostingController(
        rootView: FoodObjectCaptureContainerView(coordinator: coordinator)
      )
      controller.modalPresentationStyle = .fullScreen
      presenter.present(controller, animated: true) {
        coordinator.startSession()
      }
    } catch {
      pendingResult = nil
      result(
        FlutterError(
          code: "session_setup_failed",
          message: "Failed to prepare the native capture session.",
          details: error.localizedDescription
        )
      )
    }
  }

  @MainActor
  private func complete(with payload: [String: Any]) {
    let result = pendingResult
    pendingResult = nil
    activeCoordinator = nil

    topViewController(from: rootViewController)?.dismiss(animated: true) {
      result?(payload)
    }
  }

  @MainActor
  private func fail(with error: FlutterError) {
    let result = pendingResult
    pendingResult = nil
    activeCoordinator = nil

    topViewController(from: rootViewController)?.dismiss(animated: true) {
      result?(error)
    }
  }

  @MainActor
  private func topViewController(from controller: UIViewController?) -> UIViewController? {
    var current = controller
    while let presented = current?.presentedViewController {
      current = presented
    }
    return current
  }

  @MainActor
  private static func availabilityPayload() -> [String: Any] {
    let version = ProcessInfo.processInfo.operatingSystemVersion
    let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    let iosSupported = version.majorVersion >= 17
    let sessionSupported: Bool
    if #available(iOS 17.0, *) {
      sessionSupported = ObjectCaptureSession.isSupported
    } else {
      sessionSupported = false
    }

    return [
      "iosVersion": versionString,
      "iosSupported": iosSupported,
      "sessionSupported": sessionSupported,
      "message": sessionSupported
        ? "Native iPhone object capture is available on this device."
        : "This device does not expose Apple's native Object Capture session. Use a supported iPhone with iOS 17+ and LiDAR-class hardware."
    ]
  }
}

@available(iOS 17.0, *)
@MainActor
private final class FoodObjectCaptureCoordinator: ObservableObject {
  let session = ObjectCaptureSession()

  @Published var stateDescription = "Preparing camera"
  @Published var guidance = "Move slowly around the dish with steady soft light."
  @Published var feedbackMessages: [String] = []
  @Published var shotsTaken = 0
  @Published var canCaptureImage = false

  private let sessionRootDirectory: URL
  private let imagesDirectory: URL
  private let onResolve: ([String: Any]) -> Void
  private let onFailure: (FlutterError) -> Void
  private var observationTasks: [Task<Void, Never>] = []
  private var hasResolved = false

  init(
    onResolve: @escaping ([String: Any]) -> Void,
    onFailure: @escaping (FlutterError) -> Void
  ) throws {
    self.onResolve = onResolve
    self.onFailure = onFailure

    let baseDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("food-object-capture", isDirectory: true)
    let sessionName = "session-\(Int(Date().timeIntervalSince1970))"
    let sessionRootDirectory = baseDirectory.appendingPathComponent(sessionName, isDirectory: true)
    let imagesDirectory = sessionRootDirectory.appendingPathComponent("images", isDirectory: true)

    try FileManager.default.createDirectory(
      at: imagesDirectory,
      withIntermediateDirectories: true
    )

    self.sessionRootDirectory = sessionRootDirectory
    self.imagesDirectory = imagesDirectory
    startObservers()
  }

  deinit {
    observationTasks.forEach { $0.cancel() }
  }

  func startSession() {
    var configuration = ObjectCaptureSession.Configuration()
    configuration.isOverCaptureEnabled = true
    session.start(imagesDirectory: imagesDirectory, configuration: configuration)
    _ = session.startDetecting()
    syncSessionState()
  }

  func startCapturing() {
    session.startCapturing()
    guidance = "Orbit the dish slowly. Capture the plate edges and the food height."
  }

  func captureImage() {
    guard session.canRequestImageCapture else { return }
    session.requestImageCapture()
  }

  func finish() {
    guidance = "Finishing capture and saving the dataset."
    session.finish()
  }

  func cancel() {
    session.cancel()
    resolve(cancelled: true)
  }

  private func startObservers() {
    observationTasks.append(
      Task { [weak self] in
        guard let self else { return }
        for await state in session.stateUpdates {
          self.handle(state: state)
        }
      }
    )

    observationTasks.append(
      Task { [weak self] in
        guard let self else { return }
        for await feedback in session.feedbackUpdates {
          self.handle(feedback: feedback)
        }
      }
    )

    observationTasks.append(
      Task { [weak self] in
        guard let self else { return }
        for await shotCount in session.numberOfShotsTakenUpdates {
          self.shotsTaken = shotCount
        }
      }
    )

    observationTasks.append(
      Task { [weak self] in
        guard let self else { return }
        for await value in session.canRequestImageCaptureUpdates {
          self.canCaptureImage = value
        }
      }
    )
  }

  private func syncSessionState() {
    shotsTaken = session.numberOfShotsTaken
    canCaptureImage = session.canRequestImageCapture
    stateDescription = label(for: session.state)
    feedbackMessages = session.feedback.map(feedbackLabel(for:)).sorted()
  }

  private func handle(state: ObjectCaptureSession.CaptureState) {
    stateDescription = label(for: state)

    switch state {
    case .ready:
      guidance = "Detection is ready. Keep the dish centered and begin capture."
    case .detecting:
      guidance = "Walk around the dish until the camera feed stabilizes."
    case .capturing:
      guidance = "Take shots from low, mid, and high angles with heavy overlap."
    case .finishing:
      guidance = "Processing the capture session data."
    case .completed:
      resolve(cancelled: false)
    case .failed(let error):
      handle(error: error)
    case .initializing:
      guidance = "Preparing the native object capture session."
    @unknown default:
      guidance = "The capture session changed state. Continue scanning cautiously."
    }
  }

  private func handle(feedback: Set<ObjectCaptureSession.Feedback>) {
    feedbackMessages = feedback.map(feedbackLabel(for:)).sorted()
    if let first = feedbackMessages.first {
      guidance = first
    }
  }

  private func handle(error: Error) {
    if let sessionError = error as? ObjectCaptureSession.Error,
       case .cancelled = sessionError {
      resolve(cancelled: true)
      return
    }

    onFailure(
      FlutterError(
        code: "capture_failed",
        message: "Native object capture failed.",
        details: error.localizedDescription
      )
    )
  }

  private func resolve(cancelled: Bool) {
    guard !hasResolved else { return }
    hasResolved = true
    observationTasks.forEach { $0.cancel() }

    onResolve([
      "cancelled": cancelled,
      "shotsTaken": shotsTaken,
      "state": stateDescription,
      "sessionDirectory": sessionRootDirectory.path,
      "imagesDirectory": imagesDirectory.path,
      "note": "This prototype captures an Apple-native image dataset for later reconstruction and cleanup. It does not guarantee a perfect final 3D food model on-device."
    ])
  }

  private func label(for state: ObjectCaptureSession.CaptureState) -> String {
    switch state {
    case .initializing:
      return "Initializing"
    case .ready:
      return "Ready"
    case .detecting:
      return "Detecting"
    case .capturing:
      return "Capturing"
    case .finishing:
      return "Finishing"
    case .completed:
      return "Completed"
    case .failed:
      return "Failed"
    @unknown default:
      return "Unknown"
    }
  }

  private func feedbackLabel(for feedback: ObjectCaptureSession.Feedback) -> String {
    switch feedback {
    case .objectTooClose:
      return "Move slightly back from the dish."
    case .objectTooFar:
      return "Move closer so the plate fills more of the frame."
    case .movingTooFast:
      return "Slow down. Fast motion hurts alignment."
    case .environmentLowLight, .environmentTooDark:
      return "Increase soft light before continuing."
    case .outOfFieldOfView:
      return "Keep the full plate inside the camera frame."
    case .objectNotFlippable:
      return "Keep this as a single top-side scan pass."
    case .overCapturing:
      return "You have enough overlap. Finish when coverage looks complete."
    case .objectNotDetected:
      return "Center the dish and improve contrast against the table."
    @unknown default:
      return "Adjust the scene and continue scanning."
    }
  }
}

@available(iOS 17.0, *)
private struct FoodObjectCaptureContainerView: View {
  @ObservedObject var coordinator: FoodObjectCaptureCoordinator

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        ObjectCaptureView(session: coordinator.session)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
          .overlay(alignment: .topLeading) {
            VStack(alignment: .leading, spacing: 6) {
              Label(coordinator.stateDescription, systemImage: "camera.metering.center.weighted")
                .font(.headline)
              Text("Shots: \(coordinator.shotsTaken)")
                .font(.subheadline)
            }
            .padding(12)
            .foregroundStyle(.white)
            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(16)
          }
          .frame(maxWidth: .infinity, minHeight: 320)

        VStack(alignment: .leading, spacing: 10) {
          Text(coordinator.guidance)
            .font(.body.weight(.medium))

          if !coordinator.feedbackMessages.isEmpty {
            ForEach(coordinator.feedbackMessages, id: \.self) { message in
              Label(message, systemImage: "exclamationmark.triangle.fill")
                .font(.footnote)
                .foregroundStyle(.orange)
            }
          } else {
            Label("Capture dataset only. Reconstruction and cleanup still happen later.", systemImage: "info.circle")
              .font(.footnote)
              .foregroundStyle(.secondary)
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        HStack(spacing: 12) {
          Button("Start Capture") {
            coordinator.startCapturing()
          }
          .buttonStyle(.borderedProminent)

          Button("Take Shot") {
            coordinator.captureImage()
          }
          .buttonStyle(.bordered)
          .disabled(!coordinator.canCaptureImage)

          Button("Finish") {
            coordinator.finish()
          }
          .buttonStyle(.bordered)
          .disabled(coordinator.shotsTaken == 0)
        }

        Spacer(minLength: 0)
      }
      .padding(20)
      .navigationTitle("Food Capture Prototype")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            coordinator.cancel()
          }
        }
      }
    }
  }
}
