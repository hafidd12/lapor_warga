import 'dart:math';
import 'package:flutter/foundation.dart';
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
  static const String _reportPhotoBucket = 'report-photos';
  static const String _reportSelectColumns =
      'id, citizen_id, citizen_name, title, description, category, priority, status, votes_count, report_photo_url, location_label, completion_photo_url, completed_at, completed_by_id, completed_by_name, created_at, updated_at';

  Future<BackendSnapshot> fetchSnapshot({String? rtRw}) async {
    final users = await fetchUsers();
    const reports = <Report>[];
    final announcements = await fetchAnnouncements(rtRw: rtRw);
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
    return _fetchReportsFromQuery(
      _client
          .from('reports')
          .select(_reportSelectColumns)
          .order('created_at', ascending: false),
    );
  }

  Future<List<Report>> fetchReportsForCurrentUser(String currentUserId) async {
    final normalizedUserId = currentUserId.trim();
    if (normalizedUserId.isEmpty) {
      return const [];
    }

    final query = _client
        .from('reports')
        .select(_reportSelectColumns)
        .eq('citizen_id', normalizedUserId)
        .order('created_at', ascending: false);

    final reportRows = _rows(await query);
    final reportIds = reportRows
        .map((row) => _stringValue(row['id']))
        .whereType<String>()
        .toList();

    final upvotesByReport = <String, List<String>>{};
    if (reportIds.isNotEmpty) {
      final upvoteRows = _rows(
        await _client
            .from('report_votes')
            .select('report_id, user_id')
            .inFilter('report_id', reportIds),
      );

      for (final row in upvoteRows) {
        final reportId = _stringValue(row['report_id']);
        final userId = _stringValue(row['user_id']);
        if (reportId == null || userId == null) continue;
        upvotesByReport.putIfAbsent(reportId, () => []).add(userId);
      }
    }

    return reportRows
        .map((row) => _reportFromRow(row, upvotesByReport[row['id']] ?? []))
        .toList();
  }

  Future<List<Report>> fetchReportsForAdminRtRw(String rtRw) async {
    final normalizedRtRw = rtRw.trim();
    if (normalizedRtRw.isEmpty) return const [];

    final citizenRows = _rows(
      await _client
          .from('profiles')
          .select('id')
          .eq('role', 'warga')
          .eq('rt_rw', normalizedRtRw),
    );
    final citizenIds = citizenRows
        .map((row) => _stringValue(row['id']))
        .whereType<String>()
        .toList();
    if (citizenIds.isEmpty) return const [];

    return _fetchReportsFromQuery(
      _client
          .from('reports')
          .select(_reportSelectColumns)
          .inFilter('citizen_id', citizenIds)
          .order('created_at', ascending: false),
    );
  }

  Future<List<Announcement>> fetchAnnouncements({String? rtRw}) async {
    final normalizedRtRw = rtRw?.trim() ?? '';
    if (normalizedRtRw.isEmpty) {
      return const [];
    }

    final query = _client
        .from('announcements')
        .select(
          'id, title, content, author_id, author_name, rt_rw, created_at, updated_at',
        )
        .eq('rt_rw', normalizedRtRw);

    final data = await query.order('created_at', ascending: false);

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
        (a, b) =>
            _intValue(a['sort_order']).compareTo(_intValue(b['sort_order'])),
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
    _logRegistrationCodes(
      'fetchRegistrationCodes query=select(id, code, rt_rw, rt, rw, created_by, created_by_name, registration_type, created_at, used_at, is_active).order(created_at, desc)',
    );
    final data = await _client
        .from('registration_codes')
        .select(
          'id, code, rt_rw, rt, rw, created_by, created_by_name, registration_type, created_at, used_at, is_active',
        )
        .order('created_at', ascending: false);

    _logRegistrationCodes('fetchRegistrationCodes raw=${data.toString()}');

    return _rows(data).map(_registrationCodeFromRow).toList();
  }

  Future<Report> createReport({
    required AppUser currentUser,
    required String title,
    required String description,
    required String category,
    required ReportPriority priority,
    Uint8List? reportPhotoBytes,
    String? reportPhotoName,
    String? reportPhotoUrl,
    String? locationLabel,
  }) async {
    final resolvedReportPhotoUrl = reportPhotoBytes != null
        ? await _uploadReportPhoto(
            currentUser: currentUser,
            reportPhotoBytes: reportPhotoBytes,
            reportPhotoName: reportPhotoName,
          )
        : reportPhotoUrl;

    final data = await _client
        .from('reports')
        .insert({
          'citizen_id': currentUser.id,
          'citizen_name': currentUser.name,
          'title': title,
          'description': description,
          'category': category,
          'priority': _priorityValue(priority),
          'report_photo_url': resolvedReportPhotoUrl,
          'location_label': locationLabel,
        })
        .select()
        .single();

    return _reportFromRow(Map<String, dynamic>.from(data), const []);
  }

  Future<List<Report>> _fetchReportsFromQuery(dynamic query) async {
    final reportRows = _rows(await query);
    final reportIds = reportRows
        .map((row) => _stringValue(row['id']))
        .whereType<String>()
        .toList();

    final upvotesByReport = <String, List<String>>{};
    if (reportIds.isNotEmpty) {
      final upvoteRows = _rows(
        await _client
            .from('report_votes')
            .select('report_id, user_id')
            .inFilter('report_id', reportIds),
      );

      for (final row in upvoteRows) {
        final reportId = _stringValue(row['report_id']);
        final userId = _stringValue(row['user_id']);
        if (reportId == null || userId == null) continue;
        upvotesByReport.putIfAbsent(reportId, () => []).add(userId);
      }
    }

    return reportRows
        .map((row) => _reportFromRow(row, upvotesByReport[row['id']] ?? []))
        .toList();
  }

  Future<String> _uploadReportPhoto({
    required AppUser currentUser,
    required Uint8List reportPhotoBytes,
    required String? reportPhotoName,
  }) async {
    if (reportPhotoBytes.isEmpty) {
      throw const BackendServiceException('Foto laporan tidak valid.');
    }

    final extension = _extractFileExtension(reportPhotoName);
    final normalizedName = _sanitizeStorageSegment(
      _extractFileNameStem(reportPhotoName ?? 'report-photo'),
    );
    final storagePath =
        'reports/${currentUser.id}/${DateTime.now().microsecondsSinceEpoch}_${_randomSuffix()}_$normalizedName$extension';

    await _client.storage
        .from(_reportPhotoBucket)
        .uploadBinary(
          storagePath,
          reportPhotoBytes,
          fileOptions: const FileOptions(upsert: false),
        );

    return _client.storage
        .from(_reportPhotoBucket)
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
  }

  Future<String> uploadCompletionPhoto({
    required AppUser currentUser,
    required Uint8List completionPhotoBytes,
    required String? completionPhotoName,
  }) async {
    if (completionPhotoBytes.isEmpty) {
      throw const BackendServiceException('Foto penyelesaian tidak valid.');
    }

    final extension = _extractFileExtension(completionPhotoName);
    final normalizedName = _sanitizeStorageSegment(
      _extractFileNameStem(completionPhotoName ?? 'completion-photo'),
    );
    final storagePath =
        'reports/${currentUser.id}/${DateTime.now().microsecondsSinceEpoch}_${_randomSuffix()}_$normalizedName$extension';

    await _client.storage
        .from('completion-photos')
        .uploadBinary(
          storagePath,
          completionPhotoBytes,
          fileOptions: const FileOptions(upsert: false),
        );

    return _client.storage
        .from('completion-photos')
        .createSignedUrl(storagePath, 60 * 60 * 24 * 365);
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
          'completed_by_id': currentUser.id,
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
          .from('report_votes')
          .delete()
          .eq('report_id', report.id)
          .eq('user_id', userId);
      return;
    }

    await _client.from('report_votes').insert({
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
          'rt_rw': currentUser.rtRw,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
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

  Future<Announcement> updateAnnouncement({
    required String id,
    required String title,
    required String content,
  }) async {
    final data = await _client
        .from('announcements')
        .update({
          'title': title,
          'content': content,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select()
        .single();

    return _announcementFromRow(Map<String, dynamic>.from(data));
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
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
        {'poll_id': pollId, 'option_text': options[i], 'sort_order': i},
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
    RegistrationCodeType registrationType = RegistrationCodeType.warga,
  }) async {
    final splitRtRw = _splitRtRw(rtRw);
    _logRegistrationCodes(
      'createRegistrationCode input code="$code" rtRw="$rtRw" splitRt="${splitRtRw.$1}" splitRw="${splitRtRw.$2}" type=${registrationType.name} creator=${currentUser.id}',
    );
    final data = await _client
        .from('registration_codes')
        .insert({
          'code': code.toUpperCase(),
          'rt_rw': rtRw,
          'rt': splitRtRw.$1,
          'rw': splitRtRw.$2,
          'registration_type': _registrationTypeValue(registrationType),
          'created_by': currentUser.id,
          'created_by_name': currentUser.name,
        })
        .select()
        .single();

    _logRegistrationCodes('createRegistrationCode raw=${data.toString()}');

    return _registrationCodeFromRow(Map<String, dynamic>.from(data));
  }

  String generateWargaRegistrationCode(String rtRw) {
    final splitRtRw = _splitRtRw(rtRw);
    _logRegistrationCodes(
      'generateWargaRegistrationCode input rtRw="$rtRw" splitRt="${splitRtRw.$1}" splitRw="${splitRtRw.$2}"',
    );
    if (splitRtRw.$1.isEmpty || splitRtRw.$2.isEmpty) {
      throw const BackendServiceException(
        'Format RT/RW tidak valid untuk generate kode warga.',
      );
    }

    final generated = 'WRG${splitRtRw.$1}-${splitRtRw.$2}';
    _logRegistrationCodes('generateWargaRegistrationCode result="$generated"');
    return generated;
  }

  Future<RegistrationCode?> findRegistrationCodeByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    _logRegistrationCodes(
      'findRegistrationCodeByCode input="$code" normalized="$normalizedCode"',
    );
    if (normalizedCode.isEmpty) return null;

    _logRegistrationCodes(
      'findRegistrationCodeByCode query=select(code, rt_rw, rt, rw, created_by, created_by_name, registration_type, created_at, used_at, is_active).eq(code, "$normalizedCode").maybeSingle()',
    );
    try {
      final data = await _client
          .from('registration_codes')
          .select(
            'code, rt_rw, rt, rw, created_by, created_by_name, registration_type, created_at, used_at, is_active',
          )
          .eq('code', normalizedCode)
          .maybeSingle();

      _logRegistrationCodes('QUERY RESULT: $data');
      _logRegistrationCodes(
        'findRegistrationCodeByCode raw=${data == null ? "null" : data.toString()}',
      );

      if (data == null) return null;
      final parsed = _registrationCodeFromRow(Map<String, dynamic>.from(data));
      _logRegistrationCodes(
        'findRegistrationCodeByCode parsed code=${parsed.code} type=${parsed.registrationType.name} active=${parsed.isActive} usedAt=${parsed.usedAt}',
      );
      return parsed;
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('POSTGREST ERROR');
      debugPrint('message: ${error.message}');
      debugPrint('details: ${error.details}');
      debugPrint('hint: ${error.hint}');
      debugPrint('code: ${error.code}');
      debugPrintStack(stackTrace: stackTrace);
      _logRegistrationCodes(
        'findRegistrationCodeByCode postgrestError message=${error.message} details=${error.details} hint=${error.hint} code=${error.code}',
      );
      rethrow;
    }
  }

  Future<RegistrationCode> createOrGetWargaRegistrationCode({
    required AppUser currentUser,
    required String rtRw,
  }) async {
    final code = generateWargaRegistrationCode(rtRw);
    _logRegistrationCodes(
      'createOrGetWargaRegistrationCode input rtRw="$rtRw" generatedCode="$code" user=${currentUser.id}',
    );
    final existing = await findRegistrationCodeByCode(code);
    if (existing != null) {
      _logRegistrationCodes(
        'createOrGetWargaRegistrationCode existing id=${existing.id} code=${existing.code} type=${existing.registrationType.name} active=${existing.isActive}',
      );
      return existing;
    }

    _logRegistrationCodes(
      'createOrGetWargaRegistrationCode creating new code="$code"',
    );
    return createRegistrationCode(
      code: code,
      rtRw: rtRw,
      currentUser: currentUser,
      registrationType: RegistrationCodeType.warga,
    );
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
      completedById: _stringValue(row['completed_by_id']),
      completedBy: _stringValue(row['completed_by_name']),
    );
  }

  Announcement _announcementFromRow(Map<String, dynamic> row) {
    return Announcement(
      id: _stringValue(row['id']) ?? '',
      title: _stringValue(row['title']) ?? '',
      content: _stringValue(row['content']) ?? '',
      authorId: _stringValue(row['author_id']) ?? '',
      authorName: _stringValue(row['author_name']) ?? 'Admin',
      rtRw: _stringValue(row['rt_rw']) ?? '',
      createdAt: _dateTimeValue(row['created_at']) ?? DateTime.now(),
      updatedAt: _dateTimeValue(row['updated_at']),
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
    final rt = _stringValue(row['rt']);
    final rw = _stringValue(row['rw']);
    _logRegistrationCodes(
      "_registrationCodeFromRow raw id=${row['id']} code=${row['code']} type=${row['registration_type']} rt=${row['rt']} rw=${row['rw']} rtRw=${row['rt_rw']} active=${row['is_active']} usedAt=${row['used_at']}",
    );
    return RegistrationCode(
      id: _stringValue(row['id']) ?? '',
      code: _stringValue(row['code']) ?? '',
      rtRw: _stringValue(row['rt_rw']) ?? _composeRtRw(rt ?? '', rw ?? ''),
      rt: rt,
      rw: rw,
      createdBy: _stringValue(row['created_by']) ?? '',
      createdByName: _stringValue(row['created_by_name']) ?? 'Admin',
      registrationType: _parseRegistrationType(row['registration_type']),
      createdAt: _dateTimeValue(row['created_at']) ?? DateTime.now(),
      usedAt: _dateTimeValue(row['used_at']),
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

  String _registrationTypeValue(RegistrationCodeType type) {
    return switch (type) {
      RegistrationCodeType.warga => 'warga',
      RegistrationCodeType.admin => 'admin',
    };
  }

  RegistrationCodeType _parseRegistrationType(dynamic value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'admin' => RegistrationCodeType.admin,
      _ => RegistrationCodeType.warga,
    };
  }

  (String, String) _splitRtRw(String rtRw) {
    final parts = rtRw.split('/');
    final rt = parts.isNotEmpty ? parts.first.trim() : '';
    final rw = parts.length > 1 ? parts[1].trim() : '';
    return (rt, rw);
  }

  String _composeRtRw(String rt, String rw) {
    if (rt.isEmpty || rw.isEmpty) return '';
    return '$rt/$rw';
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

  String _extractFileExtension(String? fileName) {
    final name = fileName?.trim() ?? '';
    if (name.isEmpty) return '.jpg';

    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) {
      return '.jpg';
    }
    return name.substring(index).toLowerCase();
  }

  String _extractFileNameStem(String fileName) {
    final name = fileName.trim();
    if (name.isEmpty) return 'report-photo';

    final index = name.lastIndexOf('.');
    if (index <= 0) return name;
    return name.substring(0, index);
  }

  String _sanitizeStorageSegment(String value) {
    final cleaned = value
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'[^a-zA-Z0-9/_-]+'), '_');
    return cleaned
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/+|/+$'), '');
  }

  String _randomSuffix() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(8, (_) => chars[random.nextInt(chars.length)]).join();
  }

  void _logRegistrationCodes(String message) {
    debugPrint('[BackendService][registration_codes] $message');
  }
}
