import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'supabase_service.dart';

class BackendServiceException implements Exception {
  const BackendServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackendSnapshot {
  const BackendSnapshot({
    required this.users,
    required this.reports,
    required this.announcements,
    required this.polls,
    required this.activities,
    required this.registrationCodes,
  });

  final List<AppUser> users;
  final List<Report> reports;
  final List<Announcement> announcements;
  final List<Poll> polls;
  final List<AdminActivity> activities;
  final List<RegistrationCode> registrationCodes;
}

class BackendService {
  BackendService({SupabaseClient? client})
    : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<BackendSnapshot> fetchSnapshot() async {
    final users = await fetchUsers();
    final reports = await fetchReports();
    final announcements = await fetchAnnouncements();
    final polls = await fetchPolls();
    final activities = await fetchActivities();
    final registrationCodes = await fetchRegistrationCodes();

    return BackendSnapshot(
      users: users,
      reports: reports,
      announcements: announcements,
      polls: polls,
      activities: activities,
      registrationCodes: registrationCodes,
    );
  }

  Future<List<AppUser>> fetchUsers() async {
    final data = await _client
        .from('profiles')
        .select(
          'id, name, email, role, avatar_url, verification_status, ktp_number, registration_code, ktp_image_path, phone, rt_rw, address, jabatan, registered_at, created_at, updated_at',
        )
        .order('registered_at', ascending: false);

    return _rows(data).map(AppUser.fromProfileRow).toList();
  }

  Future<List<Report>> fetchReports() async {
    final reportRows = _rows(
      await _client
          .from('reports')
          .select(
            'id, citizen_id, citizen_name, title, description, category, priority, status, votes_count, report_photo_url, location_label, completion_photo_url, completed_at, completed_by_name, created_at',
          )
          .order('created_at', ascending: false),
    );
    final upvoteRows = _rows(
      await _client.from('report_upvotes').select('report_id, user_id'),
    );

    final upvotesByReport = <String, List<String>>{};
    for (final row in upvoteRows) {
      final reportId = _stringValue(row['report_id']);
      final userId = _stringValue(row['user_id']);
      if (reportId == null || userId == null) continue;
      upvotesByReport.putIfAbsent(reportId, () => []).add(userId);
    }

    return reportRows
        .map((row) => _reportFromRow(row, upvotesByReport[row['id']] ?? []))
        .toList();
  }

  Future<List<Announcement>> fetchAnnouncements() async {
    final data = await _client
        .from('announcements')
        .select('id, title, content, author_name, created_at')
        .order('created_at', ascending: false);

    return _rows(data).map(_announcementFromRow).toList();
  }

  Future<List<Poll>> fetchPolls() async {
    final pollRows = _rows(
      await _client
          .from('polls')
          .select('id, question, created_at')
          .eq('is_active', true)
          .order('created_at', ascending: false),
    );
    final optionRows = _rows(
      await _client
          .from('poll_options')
          .select('id, poll_id, option_text, sort_order')
          .order('sort_order'),
    );
    final voteRows = _rows(
      await _client.from('poll_votes').select('poll_id, option_id, user_id'),
    );

    final optionTextById = <String, String>{};
    final optionsByPoll = <String, List<Map<String, dynamic>>>{};
    for (final row in optionRows) {
      final optionId = _stringValue(row['id']);
      final pollId = _stringValue(row['poll_id']);
      final optionText = _stringValue(row['option_text']);
      if (optionId == null || pollId == null || optionText == null) continue;
      optionTextById[optionId] = optionText;
      optionsByPoll.putIfAbsent(pollId, () => []).add(row);
    }

    final votesByPoll = <String, Map<String, int>>{};
    final userVotesByPoll = <String, Map<String, String>>{};
    for (final row in voteRows) {
      final pollId = _stringValue(row['poll_id']);
      final optionId = _stringValue(row['option_id']);
      final userId = _stringValue(row['user_id']);
      final optionText = optionTextById[optionId];
      if (pollId == null || userId == null || optionText == null) continue;
      votesByPoll.putIfAbsent(pollId, () => {});
      votesByPoll[pollId]![optionText] =
          (votesByPoll[pollId]![optionText] ?? 0) + 1;
      userVotesByPoll.putIfAbsent(pollId, () => {})[userId] = optionText;
    }

    return pollRows.map((row) {
      final pollId = _stringValue(row['id']) ?? '';
      final optionRows = optionsByPoll[pollId] ?? [];
      optionRows.sort(
        (a, b) => _intValue(a['sort_order']).compareTo(
          _intValue(b['sort_order']),
        ),
      );
      final options = optionRows
          .map((option) => _stringValue(option['option_text']) ?? '')
          .where((option) => option.isNotEmpty)
          .toList();
      final votes = {for (final option in options) option: 0};
      votes.addAll(votesByPoll[pollId] ?? {});

      return Poll(
        id: pollId,
        question: _stringValue(row['question']) ?? '',
        options: options,
        votes: votes,
        userVotes: userVotesByPoll[pollId] ?? {},
      );
    }).toList();
  }

  Future<List<AdminActivity>> fetchActivities() async {
    final data = await _client
        .from('admin_activities')
        .select('id, description, type, photo_url, related_id, created_at')
        .order('created_at', ascending: false);

    return _rows(data).map(_activityFromRow).toList();
  }

  Future<List<RegistrationCode>> fetchRegistrationCodes() async {
    final data = await _client
        .from('registration_codes')
        .select('id, code, rt_rw, created_by, created_by_name, created_at, is_active')
        .order('created_at', ascending: false);

    return _rows(data).map(_registrationCodeFromRow).toList();
  }

  Future<Report> createReport({
    required AppUser currentUser,
    required String title,
    required String description,
    required String category,
    required ReportPriority priority,
    String? reportPhotoUrl,
    String? locationLabel,
  }) async {
    final data = await _client
        .from('reports')
        .insert({
          'citizen_id': currentUser.id,
          'citizen_name': currentUser.name,
          'title': title,
          'description': description,
          'category': category,
          'priority': _priorityValue(priority),
          'report_photo_url': reportPhotoUrl,
          'location_label': locationLabel,
        })
        .select()
        .single();

    return _reportFromRow(Map<String, dynamic>.from(data), const []);
  }

  Future<void> setReportStatus(String reportId, ReportStatus status) async {
    await _client
        .from('reports')
        .update({'status': _statusValue(status)})
        .eq('id', reportId);
  }

  Future<void> completeReport({
    required String reportId,
    required String photoUrl,
    required AppUser currentUser,
  }) async {
    await _client
        .from('reports')
        .update({
          'status': 'resolved',
          'completion_photo_url': photoUrl,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
          'completed_by': currentUser.id,
          'completed_by_name': currentUser.name,
        })
        .eq('id', reportId);

    await createActivity(
      description: 'Menyelesaikan laporan',
      type: 'report_completed',
      photoUrl: photoUrl,
      relatedTable: 'reports',
      relatedId: reportId,
      currentUser: currentUser,
    );
  }

  Future<void> toggleReportUpvote({
    required Report report,
    required String userId,
  }) async {
    if (report.upvotedByUserIds.contains(userId)) {
      await _client
          .from('report_upvotes')
          .delete()
          .eq('report_id', report.id)
          .eq('user_id', userId);
      return;
    }

    await _client.from('report_upvotes').insert({
      'report_id': report.id,
      'user_id': userId,
    });
  }

  Future<Announcement> createAnnouncement({
    required String title,
    required String content,
    required AppUser currentUser,
  }) async {
    final data = await _client
        .from('announcements')
        .insert({
          'title': title,
          'content': content,
          'author_id': currentUser.id,
          'author_name': currentUser.name,
        })
        .select()
        .single();

    await createActivity(
      description: 'Membuat pengumuman: $title',
      type: 'announcement',
      relatedTable: 'announcements',
      relatedId: _stringValue(data['id']),
      currentUser: currentUser,
    );

    return _announcementFromRow(Map<String, dynamic>.from(data));
  }

  Future<Poll> createPoll({
    required String question,
    required List<String> options,
    required AppUser currentUser,
  }) async {
    final pollData = await _client
        .from('polls')
        .insert({
          'question': question,
          'created_by': currentUser.id,
          'created_by_name': currentUser.name,
        })
        .select()
        .single();

    final pollId = _stringValue(pollData['id']) ?? '';
    await _client.from('poll_options').insert([
      for (var i = 0; i < options.length; i++)
        {
          'poll_id': pollId,
          'option_text': options[i],
          'sort_order': i,
        },
    ]);

    await createActivity(
      description: 'Membuat voting: $question',
      type: 'poll',
      relatedTable: 'polls',
      relatedId: pollId,
      currentUser: currentUser,
    );

    return Poll(
      id: pollId,
      question: question,
      options: options,
      votes: {for (final option in options) option: 0},
      userVotes: const {},
    );
  }

  Future<void> voteInPoll({
    required String pollId,
    required String option,
    required String userId,
  }) async {
    final optionData = await _client
        .from('poll_options')
        .select('id')
        .eq('poll_id', pollId)
        .eq('option_text', option)
        .single();

    await _client.from('poll_votes').upsert({
      'poll_id': pollId,
      'option_id': optionData['id'],
      'user_id': userId,
    }, onConflict: 'poll_id,user_id');
  }

  Future<void> setWargaVerification({
    required String userId,
    required VerificationStatus status,
    required AppUser currentUser,
    required String wargaName,
  }) async {
    await _client
        .from('profiles')
        .update({'verification_status': _verificationValue(status)})
        .eq('id', userId);

    await createActivity(
      description: status == VerificationStatus.verified
          ? 'Memverifikasi warga baru: $wargaName'
          : 'Menolak pendaftaran warga: $wargaName',
      type: 'verification',
      relatedTable: 'profiles',
      relatedId: userId,
      currentUser: currentUser,
    );
  }

  Future<void> removeWarga({
    required String userId,
    required AppUser currentUser,
    required String wargaName,
  }) async {
    await _client.from('profiles').delete().eq('id', userId);

    await createActivity(
      description: 'Mengeluarkan warga: $wargaName',
      type: 'warga_removed',
      relatedTable: 'profiles',
      relatedId: userId,
      currentUser: currentUser,
    );
  }

  Future<RegistrationCode> createRegistrationCode({
    required String code,
    required String rtRw,
    required AppUser currentUser,
  }) async {
    final data = await _client
        .from('registration_codes')
        .insert({
          'code': code.toUpperCase(),
          'rt_rw': rtRw,
          'created_by': currentUser.id,
          'created_by_name': currentUser.name,
        })
        .select()
        .single();

    return _registrationCodeFromRow(Map<String, dynamic>.from(data));
  }

  Future<void> setRegistrationCodeActive({
    required String codeId,
    required bool isActive,
  }) async {
    await _client
        .from('registration_codes')
        .update({'is_active': isActive})
        .eq('id', codeId);
  }

  Future<void> deleteRegistrationCode(String codeId) async {
    await _client.from('registration_codes').delete().eq('id', codeId);
  }

  Future<void> createActivity({
    required String description,
    required String type,
    required AppUser currentUser,
    String? photoUrl,
    String? relatedTable,
    String? relatedId,
  }) async {
    await _client.from('admin_activities').insert({
      'actor_id': currentUser.id,
      'description': description,
      'type': type,
      'photo_url': photoUrl,
      'related_table': relatedTable,
      'related_id': relatedId,
    });
  }

  List<Map<String, dynamic>> _rows(Object? data) {
    return (data as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Report _reportFromRow(Map<String, dynamic> row, List<String> upvotedBy) {
    return Report(
      id: _stringValue(row['id']) ?? '',
      citizenName: _stringValue(row['citizen_name']) ?? 'Warga',
      title: _stringValue(row['title']) ?? '',
      description: _stringValue(row['description']) ?? '',
      category: _stringValue(row['category']) ?? 'Lainnya',
      priority: _parseReportPriority(row['priority']),
      status: _parseReportStatus(row['status']),
      createdAt: _dateTimeValue(row['created_at']) ?? DateTime.now(),
      votesCount: _intValue(row['votes_count']),
      upvotedByUserIds: upvotedBy,
      reportPhotoUrl: _stringValue(row['report_photo_url']),
      locationLabel: _stringValue(row['location_label']),
      completionPhotoUrl: _stringValue(row['completion_photo_url']),
      completedAt: _dateTimeValue(row['completed_at']),
      completedBy: _stringValue(row['completed_by_name']),
    );
  }

  Announcement _announcementFromRow(Map<String, dynamic> row) {
    return Announcement(
      id: _stringValue(row['id']) ?? '',
      title: _stringValue(row['title']) ?? '',
      content: _stringValue(row['content']) ?? '',
      author: _stringValue(row['author_name']) ?? 'Admin',
      createdAt: _dateTimeValue(row['created_at']) ?? DateTime.now(),
    );
  }

  AdminActivity _activityFromRow(Map<String, dynamic> row) {
    return AdminActivity(
      id: _stringValue(row['id']) ?? '',
      description: _stringValue(row['description']) ?? '',
      type: _stringValue(row['type']) ?? 'verification',
      createdAt: _dateTimeValue(row['created_at']) ?? DateTime.now(),
      photoUrl: _stringValue(row['photo_url']),
      relatedId: _stringValue(row['related_id']),
    );
  }

  RegistrationCode _registrationCodeFromRow(Map<String, dynamic> row) {
    return RegistrationCode(
      id: _stringValue(row['id']) ?? '',
      code: _stringValue(row['code']) ?? '',
      rtRw: _stringValue(row['rt_rw']) ?? '',
      createdBy: _stringValue(row['created_by']) ?? '',
      createdByName: _stringValue(row['created_by_name']) ?? 'Admin',
      createdAt: _dateTimeValue(row['created_at']) ?? DateTime.now(),
      isActive: row['is_active'] == true,
    );
  }

  String _priorityValue(ReportPriority priority) {
    return switch (priority) {
      ReportPriority.low => 'low',
      ReportPriority.medium => 'medium',
      ReportPriority.high => 'high',
    };
  }

  String _statusValue(ReportStatus status) {
    return switch (status) {
      ReportStatus.submitted => 'submitted',
      ReportStatus.processed => 'processed',
      ReportStatus.resolved => 'resolved',
    };
  }

  String _verificationValue(VerificationStatus status) {
    return switch (status) {
      VerificationStatus.pending => 'pending',
      VerificationStatus.verified => 'verified',
      VerificationStatus.rejected => 'rejected',
    };
  }

  ReportPriority _parseReportPriority(dynamic value) {
    return switch (value?.toString()) {
      'high' => ReportPriority.high,
      'low' => ReportPriority.low,
      _ => ReportPriority.medium,
    };
  }

  ReportStatus _parseReportStatus(dynamic value) {
    return switch (value?.toString()) {
      'processed' => ReportStatus.processed,
      'resolved' => ReportStatus.resolved,
      _ => ReportStatus.submitted,
    };
  }

  String? _stringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  DateTime? _dateTimeValue(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
