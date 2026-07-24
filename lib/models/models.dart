import 'package:flutter/foundation.dart';

enum UserRole { warga, admin }

enum VerificationStatus { pending, verified, rejected }

enum NotificationType {
  verification,
  announcement,
  voting,
  votingResult,
  report,
  newReport,
}

enum RegistrationCodeType { warga, admin }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String avatarUrl;
  final VerificationStatus verificationStatus;
  final String? ktpNumber;
  final String? registrationCode; // Kode Registrasi RT
  final String? ktpImagePath; // Path foto KTP
  final String? phone;
  final String? rtRw;
  final String? address;
  final String? jabatan; // For RT: "RT" or "RW"
  final DateTime? registeredAt;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.avatarUrl,
    this.verificationStatus = VerificationStatus.pending,
    this.ktpNumber,
    this.registrationCode,
    this.ktpImagePath,
    this.phone,
    this.rtRw,
    this.address,
    this.jabatan,
    this.registeredAt,
  });

  factory AppUser.fromProfileRow(Map<String, dynamic> row) {
    final name = _stringValue(row['name']) ?? 'Pengguna';
    final email = _stringValue(row['email']) ?? '';
    final avatarUrl =
        _stringValue(row['avatar_url']) ??
        'https://api.dicebear.com/7.x/adventurer/svg?seed=$name';

    return AppUser(
      id: _stringValue(row['id']) ?? '',
      name: name,
      email: email,
      role: _parseUserRole(row['role']),
      avatarUrl: avatarUrl,
      verificationStatus: _parseVerificationStatus(row['verification_status']),
      ktpNumber: _stringValue(row['ktp_number']),
      registrationCode: _stringValue(row['registration_code']),
      ktpImagePath: _stringValue(row['ktp_image_path']),
      phone: _stringValue(row['phone']),
      rtRw: _stringValue(row['rt_rw']),
      address: _stringValue(row['address']),
      jabatan: _stringValue(row['jabatan']),
      registeredAt: _dateTimeValue(row['registered_at']),
    );
  }

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    VerificationStatus? verificationStatus,
    String? ktpNumber,
    String? registrationCode,
    String? ktpImagePath,
    String? phone,
    String? rtRw,
    String? address,
    String? jabatan,
    DateTime? registeredAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      ktpNumber: ktpNumber ?? this.ktpNumber,
      registrationCode: registrationCode ?? this.registrationCode,
      ktpImagePath: ktpImagePath ?? this.ktpImagePath,
      phone: phone ?? this.phone,
      rtRw: rtRw ?? this.rtRw,
      address: address ?? this.address,
      jabatan: jabatan ?? this.jabatan,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static UserRole _parseUserRole(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    return text == 'admin' ? UserRole.admin : UserRole.warga;
  }

  static VerificationStatus _parseVerificationStatus(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    switch (text) {
      case 'verified':
        return VerificationStatus.verified;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'pending':
      default:
        return VerificationStatus.pending;
    }
  }
}

class RegistrationCodeLookupResult {
  final String code;
  final RegistrationCodeType registrationType;
  final String rt;
  final String rw;
  final String rtRw;
  final bool isActive;
  final DateTime? usedAt;

  const RegistrationCodeLookupResult({
    required this.code,
    required this.registrationType,
    required this.rt,
    required this.rw,
    required this.rtRw,
    required this.isActive,
    this.usedAt,
  });

  factory RegistrationCodeLookupResult.fromRow(Map<String, dynamic> row) {
    debugPrint('[RegistrationCodeLookupResult] fromRow raw=$row');
    final code = _stringValue(row['code']) ?? '';
    final rt = _stringValue(row['rt']) ?? _extractCodePart(code, 1) ?? '';
    final rw = _stringValue(row['rw']) ?? _extractCodePart(code, 2) ?? '';
    final rtRw = _stringValue(row['rt_rw']) ?? _composeRtRw(rt, rw);

    final result = RegistrationCodeLookupResult(
      code: code,
      registrationType: _parseRegistrationCodeType(row['registration_type']),
      rt: rt,
      rw: rw,
      rtRw: rtRw,
      isActive: row['is_active'] == true,
      usedAt: _dateTimeValue(row['used_at']),
    );

    debugPrint(
      '[RegistrationCodeLookupResult] parsed code=${result.code} type=${result.registrationType.name} rt=${result.rt} rw=${result.rw} rtRw=${result.rtRw} active=${result.isActive} usedAt=${result.usedAt}',
    );
    return result;
  }

  static String? _extractCodePart(String code, int partIndex) {
    final match = RegExp(
      r'^RT(\d+)-(\d+)$',
      caseSensitive: false,
    ).firstMatch(code.trim());
    if (match == null) return null;
    return match.group(partIndex);
  }

  static String _composeRtRw(String rt, String rw) {
    if (rt.isEmpty || rw.isEmpty) return '';
    return '$rt/$rw';
  }

  static RegistrationCodeType _parseRegistrationCodeType(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    return text == 'admin'
        ? RegistrationCodeType.admin
        : RegistrationCodeType.warga;
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class AppNotification {
  final String id;
  final String recipientId;
  final String? senderId;
  final NotificationType type;
  final String title;
  final String message;
  final String? relatedTable;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  String get userId => recipientId;
  String? get targetId => relatedId;
  String? get targetType => relatedTable;

  AppNotification({
    required this.id,
    String? userId,
    String? recipientId,
    this.senderId,
    required this.type,
    required this.title,
    required this.message,
    this.relatedTable,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  }) : recipientId = (recipientId ?? userId ?? '').trim();

  factory AppNotification.fromRow(Map<String, dynamic> row) {
    final type = _parseNotificationType(row['type']);

    return AppNotification(
      id: _stringValue(row['id']) ?? '',
      recipientId: _stringValue(row['recipient_id']) ?? '',
      senderId: _stringValue(row['sender_id']),
      type: type,
      title: _stringValue(row['title']) ?? _defaultTitle(type),
      message: _stringValue(row['message']) ?? '',
      relatedTable: _stringValue(row['related_table']),
      relatedId: _stringValue(row['related_id']),
      isRead:
          row['is_read'] == true ||
          row['is_read'] == 1 ||
          row['is_read'] == 'true',
      createdAt:
          _dateTimeValue(row['created_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      readAt: null,
    );
  }

  static String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _dateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static NotificationType _parseNotificationType(dynamic value) {
    final text = value?.toString().toLowerCase().trim();
    switch (text) {
      case 'announcement':
        return NotificationType.announcement;
      case 'voting':
        return NotificationType.voting;
      case 'voting_result':
      case 'voting-result':
      case 'votingresult':
        return NotificationType.votingResult;
      case 'report':
        return NotificationType.report;
      case 'new_report':
      case 'new-report':
      case 'newreport':
        return NotificationType.newReport;
      case 'verification':
      default:
        return NotificationType.verification;
    }
  }

  static String _defaultTitle(NotificationType type) {
    switch (type) {
      case NotificationType.announcement:
        return 'Pengumuman baru';
      case NotificationType.voting:
        return 'Voting baru dibuka';
      case NotificationType.votingResult:
        return 'Hasil voting tersedia';
      case NotificationType.report:
        return 'Status laporan berubah';
      case NotificationType.newReport:
        return 'Laporan baru masuk';
      case NotificationType.verification:
        return 'Verifikasi akun';
    }
  }
}

enum ReportPriority { low, medium, high }

enum ReportStatus { submitted, processed, resolved }

class Report {
  final String id;
  final String citizenName;
  final String title;
  final String description;
  final String category;
  final ReportPriority priority;
  final ReportStatus status;
  final DateTime createdAt;
  final int votesCount;
  final List<String> upvotedByUserIds;
  final String? reportPhotoUrl;
  final String? locationLabel;
  final String? completionPhotoUrl;
  final DateTime? completedAt;
  final String? completedById;
  final String? completedBy;

  Report({
    required this.id,
    required this.citizenName,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.votesCount = 0,
    this.upvotedByUserIds = const [],
    this.reportPhotoUrl,
    this.locationLabel,
    this.completionPhotoUrl,
    this.completedAt,
    this.completedById,
    this.completedBy,
  });

  Report copyWith({
    String? id,
    String? citizenName,
    String? title,
    String? description,
    String? category,
    ReportPriority? priority,
    ReportStatus? status,
    DateTime? createdAt,
    int? votesCount,
    List<String>? upvotedByUserIds,
    String? reportPhotoUrl,
    String? locationLabel,
    String? completionPhotoUrl,
    DateTime? completedAt,
    String? completedById,
    String? completedBy,
  }) {
    return Report(
      id: id ?? this.id,
      citizenName: citizenName ?? this.citizenName,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      votesCount: votesCount ?? this.votesCount,
      upvotedByUserIds: upvotedByUserIds ?? this.upvotedByUserIds,
      reportPhotoUrl: reportPhotoUrl ?? this.reportPhotoUrl,
      locationLabel: locationLabel ?? this.locationLabel,
      completionPhotoUrl: completionPhotoUrl ?? this.completionPhotoUrl,
      completedAt: completedAt ?? this.completedAt,
      completedById: completedById ?? this.completedById,
      completedBy: completedBy ?? this.completedBy,
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String rtRw;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get author => authorName;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    this.authorId = '',
    String? author,
    String? authorName,
    this.rtRw = '',
    required this.createdAt,
    this.updatedAt,
  }) : authorName = _normalizedDisplayName(authorName ?? author);

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    String? authorId,
    String? author,
    String? authorName,
    String? rtRw,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      author: author,
      authorName: authorName ?? this.authorName,
      rtRw: rtRw ?? this.rtRw,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String _normalizedDisplayName(String? value) {
    final text = value?.trim() ?? '';
    return text.isEmpty ? 'Admin' : text;
  }
}

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final List<String> optionIds;
  final Map<String, int> votes; // option -> vote count
  final Map<String, String> userVotes; // userId -> voted option
  final bool isActive;

  Poll({
    required this.id,
    required this.question,
    required this.options,
    this.optionIds = const [],
    required this.votes,
    required this.userVotes,
    this.isActive = true,
  });

  int get totalVotes => votes.values.fold(0, (sum, val) => sum + val);

  String? optionIdForLabel(String optionLabel) {
    final index = options.indexOf(optionLabel);
    if (index == -1 || index >= optionIds.length) return null;

    final optionId = optionIds[index].trim();
    return optionId.isEmpty ? null : optionId;
  }

  Poll copyWith({
    String? id,
    String? question,
    List<String>? options,
    List<String>? optionIds,
    Map<String, int>? votes,
    Map<String, String>? userVotes,
    bool? isActive,
  }) {
    return Poll(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      optionIds: optionIds ?? this.optionIds,
      votes: votes ?? this.votes,
      userVotes: userVotes ?? this.userVotes,
      isActive: isActive ?? this.isActive,
    );
  }
}

class AdminActivity {
  final String id;
  final String description;
  final String
  type; // 'verification', 'announcement', 'report_completed', 'poll', 'warga_removed'
  final DateTime createdAt;
  final String? photoUrl;
  final String? relatedId;

  AdminActivity({
    required this.id,
    required this.description,
    required this.type,
    required this.createdAt,
    this.photoUrl,
    this.relatedId,
  });
}

class RegistrationCode {
  final String id;
  final String code; // Kode unik, misal "RT05-XY7K"
  final String rtRw; // Nomor RT/RW terkait, misal "005/002"
  final String? rt;
  final String? rw;
  final String createdBy; // ID admin yang membuat
  final String createdByName; // Nama admin yang membuat
  final RegistrationCodeType registrationType;
  final DateTime createdAt;
  final DateTime? usedAt;
  final bool isActive;

  RegistrationCode({
    required this.id,
    required this.code,
    required this.rtRw,
    this.rt,
    this.rw,
    required this.createdBy,
    required this.createdByName,
    this.registrationType = RegistrationCodeType.warga,
    required this.createdAt,
    this.usedAt,
    this.isActive = true,
  });

  RegistrationCode copyWith({
    String? id,
    String? code,
    String? rtRw,
    String? rt,
    String? rw,
    String? createdBy,
    String? createdByName,
    RegistrationCodeType? registrationType,
    DateTime? createdAt,
    DateTime? usedAt,
    bool? isActive,
  }) {
    return RegistrationCode(
      id: id ?? this.id,
      code: code ?? this.code,
      rtRw: rtRw ?? this.rtRw,
      rt: rt ?? this.rt,
      rw: rw ?? this.rw,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
      registrationType: registrationType ?? this.registrationType,
      createdAt: createdAt ?? this.createdAt,
      usedAt: usedAt ?? this.usedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
