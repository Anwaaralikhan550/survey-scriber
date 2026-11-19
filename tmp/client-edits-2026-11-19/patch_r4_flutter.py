def rw(p, fn):
    t = open(p, encoding='utf-8', newline='').read()
    nl = '\r\n' if '\r\n' in t else '\n'
    t = fn(t.replace('\r\n', '\n'))
    open(p, 'w', encoding='utf-8', newline='').write(t.replace('\n', nl))


def sub(t, a, b):
    assert t.count(a) == 1, (t.count(a), a[:70])
    return t.replace(a, b, 1)


def api(t):
    t = sub(t, "  const ReviewEntry({required this.decision, required this.version, required this.by, required this.createdAt, required this.invalidated, this.comment});",
            "  const ReviewEntry({required this.decision, required this.version, required this.by, required this.createdAt, required this.invalidated, this.comment, this.reviewerName});")
    t = sub(t, "  final String? comment;\n}\n\n/// One edit round", "  final String? comment;\n\n  /// The name a link holder typed (never verified). Null for the owner and for a link holder who gave none.\n  final String? reviewerName;\n\n  /// \"Omar Khan (name not verified)\" for a link holder with a name, otherwise [fallback].\n  String who({String fallback = 'a reviewer'}) => by == 'owner' ? 'you' : (reviewerName == null ? fallback : '$reviewerName (name not verified)');\n}\n\n/// One edit round")
    t = sub(t, "        comment: raw['comment'] as String?,\n      );\n\n  static FinalRound _round", "        comment: raw['comment'] as String?,\n        reviewerName: raw['reviewerName'] as String?,\n      );\n\n  static FinalRound _round")
    t = sub(t, "    this.finalVersion,\n    this.finalisedAt,\n    this.rounds = const [],\n  });\n\n  const ReviewInfo.draft", "    this.finalVersion,\n    this.finalisedAt,\n    this.rounds = const [],\n    this.reviewerApprovalName,\n  });\n\n  const ReviewInfo.draft")
    t = sub(t, "  final int? reviewerApprovalVersion;\n", "  final int? reviewerApprovalVersion;\n\n  /// The name the approving link holder typed (not verified).\n  final String? reviewerApprovalName;\n")
    t = sub(t, "        reviewerApprovalVersion: (b['reviewerApproval'] as Map?)?['version'] as int?,\n", "        reviewerApprovalVersion: (b['reviewerApproval'] as Map?)?['version'] as int?,\n        reviewerApprovalName: (b['reviewerApproval'] as Map?)?['reviewerName'] as String?,\n")
    return t


rw('lib/features/report_editing/data/report_editing_api.dart', api)


def page(t):
    t = sub(t, "      return 'A reviewer approved version ${r.reviewerApprovalVersion ?? r.version}. The final approval is yours.';",
            "      return '${r.reviewerApprovalName == null ? 'A reviewer' : '${r.reviewerApprovalName} (name not verified)'} approved version ${r.reviewerApprovalVersion ?? r.version}. The final approval is yours.';")
    t = sub(t, "(${amend.by == 'owner' ? 'you' : 'a reviewer'}, version ${amend.version})", "(${amend.who()}, version ${amend.version})")
    return t


rw('lib/features/report_editing/presentation/pages/desktop_editing_page.dart', page)
print('ok')
