import 'package:flutter/services.dart';

class FoodCaptureChannel {
  FoodCaptureChannel._();

  static const MethodChannel _channel = MethodChannel('food_object_capture');

  static Future<Map<String, dynamic>> getAvailability() async {
    final value =
        await _channel.invokeMapMethod<String, dynamic>('getAvailability');
    return Map<String, dynamic>.from(value ?? const <String, dynamic>{});
  }

  static Future<Map<String, dynamic>> startCapture() async {
    final value =
        await _channel.invokeMapMethod<String, dynamic>('startCapture');
    return Map<String, dynamic>.from(value ?? const <String, dynamic>{});
  }
}
