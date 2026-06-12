enum UserRole { warga, admin }

enum VerificationStatus { pending, verified, rejected }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String avatarUrl;
  final VerificationStatus verificationStatus;
  final String? ktpNumber;
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
    this.phone,
    this.rtRw,
    this.address,
    this.jabatan,
    this.registeredAt,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    VerificationStatus? verificationStatus,
    String? ktpNumber,
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
      phone: phone ?? this.phone,
      rtRw: rtRw ?? this.rtRw,
      address: address ?? this.address,
      jabatan: jabatan ?? this.jabatan,
      registeredAt: registeredAt ?? this.registeredAt,
    );
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
      completedBy: completedBy ?? this.completedBy,
    );
  }
}

class Announcement {
  final String id;
  final String title;
  final String content;
  final String author;
  final DateTime createdAt;

  Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.createdAt,
  });
}

class Poll {
  final String id;
  final String question;
  final List<String> options;
  final Map<String, int> votes; // option -> vote count
  final Map<String, String> userVotes; // userId -> voted option

  Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.userVotes,
  });

  int get totalVotes => votes.values.fold(0, (sum, val) => sum + val);

  Poll copyWith({
    String? id,
    String? question,
    List<String>? options,
    Map<String, int>? votes,
    Map<String, String>? userVotes,
  }) {
    return Poll(
      id: id ?? this.id,
      question: question ?? this.question,
      options: options ?? this.options,
      votes: votes ?? this.votes,
      userVotes: userVotes ?? this.userVotes,
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
