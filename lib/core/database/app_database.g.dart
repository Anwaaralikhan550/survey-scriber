// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SurveysTable extends Surveys with TableInfo<$SurveysTable, Survey> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
      'type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jobRefMeta = const VerificationMeta('jobRef');
  @override
  late final GeneratedColumn<String> jobRef = GeneratedColumn<String>(
      'job_ref', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _addressMeta =
      const VerificationMeta('address');
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
      'address', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _clientNameMeta =
      const VerificationMeta('clientName');
  @override
  late final GeneratedColumn<String> clientName = GeneratedColumn<String>(
      'client_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _progressMeta =
      const VerificationMeta('progress');
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
      'progress', aliasedName, false,
      type: DriftSqlType.double,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _photoCountMeta =
      const VerificationMeta('photoCount');
  @override
  late final GeneratedColumn<int> photoCount = GeneratedColumn<int>(
      'photo_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _noteCountMeta =
      const VerificationMeta('noteCount');
  @override
  late final GeneratedColumn<int> noteCount = GeneratedColumn<int>(
      'note_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _totalSectionsMeta =
      const VerificationMeta('totalSections');
  @override
  late final GeneratedColumn<int> totalSections = GeneratedColumn<int>(
      'total_sections', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _completedSectionsMeta =
      const VerificationMeta('completedSections');
  @override
  late final GeneratedColumn<int> completedSections = GeneratedColumn<int>(
      'completed_sections', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
      'started_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  static const VerificationMeta _parentSurveyIdMeta =
      const VerificationMeta('parentSurveyId');
  @override
  late final GeneratedColumn<String> parentSurveyId = GeneratedColumn<String>(
      'parent_survey_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reinspectionNumberMeta =
      const VerificationMeta('reinspectionNumber');
  @override
  late final GeneratedColumn<int> reinspectionNumber = GeneratedColumn<int>(
      'reinspection_number', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _aiSummaryMeta =
      const VerificationMeta('aiSummary');
  @override
  late final GeneratedColumn<String> aiSummary = GeneratedColumn<String>(
      'ai_summary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _riskSummaryMeta =
      const VerificationMeta('riskSummary');
  @override
  late final GeneratedColumn<String> riskSummary = GeneratedColumn<String>(
      'risk_summary', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _repairRecommendationsMeta =
      const VerificationMeta('repairRecommendations');
  @override
  late final GeneratedColumn<String> repairRecommendations =
      GeneratedColumn<String>('repair_recommendations', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        title,
        type,
        status,
        jobRef,
        address,
        clientName,
        progress,
        photoCount,
        noteCount,
        totalSections,
        completedSections,
        createdAt,
        updatedAt,
        startedAt,
        completedAt,
        parentSurveyId,
        reinspectionNumber,
        aiSummary,
        riskSummary,
        repairRecommendations
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surveys';
  @override
  VerificationContext validateIntegrity(Insertable<Survey> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
          _typeMeta, type.isAcceptableOrUnknown(data['type']!, _typeMeta));
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('job_ref')) {
      context.handle(_jobRefMeta,
          jobRef.isAcceptableOrUnknown(data['job_ref']!, _jobRefMeta));
    }
    if (data.containsKey('address')) {
      context.handle(_addressMeta,
          address.isAcceptableOrUnknown(data['address']!, _addressMeta));
    }
    if (data.containsKey('client_name')) {
      context.handle(
          _clientNameMeta,
          clientName.isAcceptableOrUnknown(
              data['client_name']!, _clientNameMeta));
    }
    if (data.containsKey('progress')) {
      context.handle(_progressMeta,
          progress.isAcceptableOrUnknown(data['progress']!, _progressMeta));
    }
    if (data.containsKey('photo_count')) {
      context.handle(
          _photoCountMeta,
          photoCount.isAcceptableOrUnknown(
              data['photo_count']!, _photoCountMeta));
    }
    if (data.containsKey('note_count')) {
      context.handle(_noteCountMeta,
          noteCount.isAcceptableOrUnknown(data['note_count']!, _noteCountMeta));
    }
    if (data.containsKey('total_sections')) {
      context.handle(
          _totalSectionsMeta,
          totalSections.isAcceptableOrUnknown(
              data['total_sections']!, _totalSectionsMeta));
    }
    if (data.containsKey('completed_sections')) {
      context.handle(
          _completedSectionsMeta,
          completedSections.isAcceptableOrUnknown(
              data['completed_sections']!, _completedSectionsMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('parent_survey_id')) {
      context.handle(
          _parentSurveyIdMeta,
          parentSurveyId.isAcceptableOrUnknown(
              data['parent_survey_id']!, _parentSurveyIdMeta));
    }
    if (data.containsKey('reinspection_number')) {
      context.handle(
          _reinspectionNumberMeta,
          reinspectionNumber.isAcceptableOrUnknown(
              data['reinspection_number']!, _reinspectionNumberMeta));
    }
    if (data.containsKey('ai_summary')) {
      context.handle(_aiSummaryMeta,
          aiSummary.isAcceptableOrUnknown(data['ai_summary']!, _aiSummaryMeta));
    }
    if (data.containsKey('risk_summary')) {
      context.handle(
          _riskSummaryMeta,
          riskSummary.isAcceptableOrUnknown(
              data['risk_summary']!, _riskSummaryMeta));
    }
    if (data.containsKey('repair_recommendations')) {
      context.handle(
          _repairRecommendationsMeta,
          repairRecommendations.isAcceptableOrUnknown(
              data['repair_recommendations']!, _repairRecommendationsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Survey map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Survey(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      type: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}type'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      jobRef: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}job_ref']),
      address: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address']),
      clientName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}client_name']),
      progress: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}progress'])!,
      photoCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}photo_count'])!,
      noteCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}note_count'])!,
      totalSections: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}total_sections'])!,
      completedSections: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}completed_sections'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}started_at']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}completed_at']),
      parentSurveyId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}parent_survey_id']),
      reinspectionNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}reinspection_number'])!,
      aiSummary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}ai_summary']),
      riskSummary: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}risk_summary']),
      repairRecommendations: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}repair_recommendations']),
    );
  }

  @override
  $SurveysTable createAlias(String alias) {
    return $SurveysTable(attachedDatabase, alias);
  }
}

class Survey extends DataClass implements Insertable<Survey> {
  final String id;
  final String title;
  final String type;
  final String status;
  final String? jobRef;
  final String? address;
  final String? clientName;
  final double progress;
  final int photoCount;
  final int noteCount;
  final int totalSections;
  final int completedSections;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Parent survey ID for re-inspections (links to original survey)
  final String? parentSurveyId;

  /// Re-inspection number (1, 2, 3...) for tracking iteration
  final int reinspectionNumber;

  /// AI-generated executive summary text (persisted when user accepts)
  final String? aiSummary;

  /// AI-generated risk summary text (persisted when user accepts)
  final String? riskSummary;

  /// AI-generated repair recommendations text (persisted when user accepts)
  final String? repairRecommendations;
  const Survey(
      {required this.id,
      required this.title,
      required this.type,
      required this.status,
      this.jobRef,
      this.address,
      this.clientName,
      required this.progress,
      required this.photoCount,
      required this.noteCount,
      required this.totalSections,
      required this.completedSections,
      required this.createdAt,
      this.updatedAt,
      this.startedAt,
      this.completedAt,
      this.parentSurveyId,
      required this.reinspectionNumber,
      this.aiSummary,
      this.riskSummary,
      this.repairRecommendations});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['type'] = Variable<String>(type);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || jobRef != null) {
      map['job_ref'] = Variable<String>(jobRef);
    }
    if (!nullToAbsent || address != null) {
      map['address'] = Variable<String>(address);
    }
    if (!nullToAbsent || clientName != null) {
      map['client_name'] = Variable<String>(clientName);
    }
    map['progress'] = Variable<double>(progress);
    map['photo_count'] = Variable<int>(photoCount);
    map['note_count'] = Variable<int>(noteCount);
    map['total_sections'] = Variable<int>(totalSections);
    map['completed_sections'] = Variable<int>(completedSections);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || parentSurveyId != null) {
      map['parent_survey_id'] = Variable<String>(parentSurveyId);
    }
    map['reinspection_number'] = Variable<int>(reinspectionNumber);
    if (!nullToAbsent || aiSummary != null) {
      map['ai_summary'] = Variable<String>(aiSummary);
    }
    if (!nullToAbsent || riskSummary != null) {
      map['risk_summary'] = Variable<String>(riskSummary);
    }
    if (!nullToAbsent || repairRecommendations != null) {
      map['repair_recommendations'] = Variable<String>(repairRecommendations);
    }
    return map;
  }

  SurveysCompanion toCompanion(bool nullToAbsent) {
    return SurveysCompanion(
      id: Value(id),
      title: Value(title),
      type: Value(type),
      status: Value(status),
      jobRef:
          jobRef == null && nullToAbsent ? const Value.absent() : Value(jobRef),
      address: address == null && nullToAbsent
          ? const Value.absent()
          : Value(address),
      clientName: clientName == null && nullToAbsent
          ? const Value.absent()
          : Value(clientName),
      progress: Value(progress),
      photoCount: Value(photoCount),
      noteCount: Value(noteCount),
      totalSections: Value(totalSections),
      completedSections: Value(completedSections),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      parentSurveyId: parentSurveyId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentSurveyId),
      reinspectionNumber: Value(reinspectionNumber),
      aiSummary: aiSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(aiSummary),
      riskSummary: riskSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(riskSummary),
      repairRecommendations: repairRecommendations == null && nullToAbsent
          ? const Value.absent()
          : Value(repairRecommendations),
    );
  }

  factory Survey.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Survey(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      type: serializer.fromJson<String>(json['type']),
      status: serializer.fromJson<String>(json['status']),
      jobRef: serializer.fromJson<String?>(json['jobRef']),
      address: serializer.fromJson<String?>(json['address']),
      clientName: serializer.fromJson<String?>(json['clientName']),
      progress: serializer.fromJson<double>(json['progress']),
      photoCount: serializer.fromJson<int>(json['photoCount']),
      noteCount: serializer.fromJson<int>(json['noteCount']),
      totalSections: serializer.fromJson<int>(json['totalSections']),
      completedSections: serializer.fromJson<int>(json['completedSections']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      parentSurveyId: serializer.fromJson<String?>(json['parentSurveyId']),
      reinspectionNumber: serializer.fromJson<int>(json['reinspectionNumber']),
      aiSummary: serializer.fromJson<String?>(json['aiSummary']),
      riskSummary: serializer.fromJson<String?>(json['riskSummary']),
      repairRecommendations:
          serializer.fromJson<String?>(json['repairRecommendations']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'type': serializer.toJson<String>(type),
      'status': serializer.toJson<String>(status),
      'jobRef': serializer.toJson<String?>(jobRef),
      'address': serializer.toJson<String?>(address),
      'clientName': serializer.toJson<String?>(clientName),
      'progress': serializer.toJson<double>(progress),
      'photoCount': serializer.toJson<int>(photoCount),
      'noteCount': serializer.toJson<int>(noteCount),
      'totalSections': serializer.toJson<int>(totalSections),
      'completedSections': serializer.toJson<int>(completedSections),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'parentSurveyId': serializer.toJson<String?>(parentSurveyId),
      'reinspectionNumber': serializer.toJson<int>(reinspectionNumber),
      'aiSummary': serializer.toJson<String?>(aiSummary),
      'riskSummary': serializer.toJson<String?>(riskSummary),
      'repairRecommendations':
          serializer.toJson<String?>(repairRecommendations),
    };
  }

  Survey copyWith(
          {String? id,
          String? title,
          String? type,
          String? status,
          Value<String?> jobRef = const Value.absent(),
          Value<String?> address = const Value.absent(),
          Value<String?> clientName = const Value.absent(),
          double? progress,
          int? photoCount,
          int? noteCount,
          int? totalSections,
          int? completedSections,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent(),
          Value<DateTime?> startedAt = const Value.absent(),
          Value<DateTime?> completedAt = const Value.absent(),
          Value<String?> parentSurveyId = const Value.absent(),
          int? reinspectionNumber,
          Value<String?> aiSummary = const Value.absent(),
          Value<String?> riskSummary = const Value.absent(),
          Value<String?> repairRecommendations = const Value.absent()}) =>
      Survey(
        id: id ?? this.id,
        title: title ?? this.title,
        type: type ?? this.type,
        status: status ?? this.status,
        jobRef: jobRef.present ? jobRef.value : this.jobRef,
        address: address.present ? address.value : this.address,
        clientName: clientName.present ? clientName.value : this.clientName,
        progress: progress ?? this.progress,
        photoCount: photoCount ?? this.photoCount,
        noteCount: noteCount ?? this.noteCount,
        totalSections: totalSections ?? this.totalSections,
        completedSections: completedSections ?? this.completedSections,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
        startedAt: startedAt.present ? startedAt.value : this.startedAt,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        parentSurveyId:
            parentSurveyId.present ? parentSurveyId.value : this.parentSurveyId,
        reinspectionNumber: reinspectionNumber ?? this.reinspectionNumber,
        aiSummary: aiSummary.present ? aiSummary.value : this.aiSummary,
        riskSummary: riskSummary.present ? riskSummary.value : this.riskSummary,
        repairRecommendations: repairRecommendations.present
            ? repairRecommendations.value
            : this.repairRecommendations,
      );
  Survey copyWithCompanion(SurveysCompanion data) {
    return Survey(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      type: data.type.present ? data.type.value : this.type,
      status: data.status.present ? data.status.value : this.status,
      jobRef: data.jobRef.present ? data.jobRef.value : this.jobRef,
      address: data.address.present ? data.address.value : this.address,
      clientName:
          data.clientName.present ? data.clientName.value : this.clientName,
      progress: data.progress.present ? data.progress.value : this.progress,
      photoCount:
          data.photoCount.present ? data.photoCount.value : this.photoCount,
      noteCount: data.noteCount.present ? data.noteCount.value : this.noteCount,
      totalSections: data.totalSections.present
          ? data.totalSections.value
          : this.totalSections,
      completedSections: data.completedSections.present
          ? data.completedSections.value
          : this.completedSections,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      parentSurveyId: data.parentSurveyId.present
          ? data.parentSurveyId.value
          : this.parentSurveyId,
      reinspectionNumber: data.reinspectionNumber.present
          ? data.reinspectionNumber.value
          : this.reinspectionNumber,
      aiSummary: data.aiSummary.present ? data.aiSummary.value : this.aiSummary,
      riskSummary:
          data.riskSummary.present ? data.riskSummary.value : this.riskSummary,
      repairRecommendations: data.repairRecommendations.present
          ? data.repairRecommendations.value
          : this.repairRecommendations,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Survey(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('jobRef: $jobRef, ')
          ..write('address: $address, ')
          ..write('clientName: $clientName, ')
          ..write('progress: $progress, ')
          ..write('photoCount: $photoCount, ')
          ..write('noteCount: $noteCount, ')
          ..write('totalSections: $totalSections, ')
          ..write('completedSections: $completedSections, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('parentSurveyId: $parentSurveyId, ')
          ..write('reinspectionNumber: $reinspectionNumber, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('riskSummary: $riskSummary, ')
          ..write('repairRecommendations: $repairRecommendations')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
        id,
        title,
        type,
        status,
        jobRef,
        address,
        clientName,
        progress,
        photoCount,
        noteCount,
        totalSections,
        completedSections,
        createdAt,
        updatedAt,
        startedAt,
        completedAt,
        parentSurveyId,
        reinspectionNumber,
        aiSummary,
        riskSummary,
        repairRecommendations
      ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Survey &&
          other.id == this.id &&
          other.title == this.title &&
          other.type == this.type &&
          other.status == this.status &&
          other.jobRef == this.jobRef &&
          other.address == this.address &&
          other.clientName == this.clientName &&
          other.progress == this.progress &&
          other.photoCount == this.photoCount &&
          other.noteCount == this.noteCount &&
          other.totalSections == this.totalSections &&
          other.completedSections == this.completedSections &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt &&
          other.parentSurveyId == this.parentSurveyId &&
          other.reinspectionNumber == this.reinspectionNumber &&
          other.aiSummary == this.aiSummary &&
          other.riskSummary == this.riskSummary &&
          other.repairRecommendations == this.repairRecommendations);
}

class SurveysCompanion extends UpdateCompanion<Survey> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> type;
  final Value<String> status;
  final Value<String?> jobRef;
  final Value<String?> address;
  final Value<String?> clientName;
  final Value<double> progress;
  final Value<int> photoCount;
  final Value<int> noteCount;
  final Value<int> totalSections;
  final Value<int> completedSections;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<String?> parentSurveyId;
  final Value<int> reinspectionNumber;
  final Value<String?> aiSummary;
  final Value<String?> riskSummary;
  final Value<String?> repairRecommendations;
  final Value<int> rowid;
  const SurveysCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.type = const Value.absent(),
    this.status = const Value.absent(),
    this.jobRef = const Value.absent(),
    this.address = const Value.absent(),
    this.clientName = const Value.absent(),
    this.progress = const Value.absent(),
    this.photoCount = const Value.absent(),
    this.noteCount = const Value.absent(),
    this.totalSections = const Value.absent(),
    this.completedSections = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.parentSurveyId = const Value.absent(),
    this.reinspectionNumber = const Value.absent(),
    this.aiSummary = const Value.absent(),
    this.riskSummary = const Value.absent(),
    this.repairRecommendations = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveysCompanion.insert({
    required String id,
    required String title,
    required String type,
    required String status,
    this.jobRef = const Value.absent(),
    this.address = const Value.absent(),
    this.clientName = const Value.absent(),
    this.progress = const Value.absent(),
    this.photoCount = const Value.absent(),
    this.noteCount = const Value.absent(),
    this.totalSections = const Value.absent(),
    this.completedSections = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.parentSurveyId = const Value.absent(),
    this.reinspectionNumber = const Value.absent(),
    this.aiSummary = const Value.absent(),
    this.riskSummary = const Value.absent(),
    this.repairRecommendations = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        title = Value(title),
        type = Value(type),
        status = Value(status),
        createdAt = Value(createdAt);
  static Insertable<Survey> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? type,
    Expression<String>? status,
    Expression<String>? jobRef,
    Expression<String>? address,
    Expression<String>? clientName,
    Expression<double>? progress,
    Expression<int>? photoCount,
    Expression<int>? noteCount,
    Expression<int>? totalSections,
    Expression<int>? completedSections,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<String>? parentSurveyId,
    Expression<int>? reinspectionNumber,
    Expression<String>? aiSummary,
    Expression<String>? riskSummary,
    Expression<String>? repairRecommendations,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (type != null) 'type': type,
      if (status != null) 'status': status,
      if (jobRef != null) 'job_ref': jobRef,
      if (address != null) 'address': address,
      if (clientName != null) 'client_name': clientName,
      if (progress != null) 'progress': progress,
      if (photoCount != null) 'photo_count': photoCount,
      if (noteCount != null) 'note_count': noteCount,
      if (totalSections != null) 'total_sections': totalSections,
      if (completedSections != null) 'completed_sections': completedSections,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (parentSurveyId != null) 'parent_survey_id': parentSurveyId,
      if (reinspectionNumber != null) 'reinspection_number': reinspectionNumber,
      if (aiSummary != null) 'ai_summary': aiSummary,
      if (riskSummary != null) 'risk_summary': riskSummary,
      if (repairRecommendations != null)
        'repair_recommendations': repairRecommendations,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveysCompanion copyWith(
      {Value<String>? id,
      Value<String>? title,
      Value<String>? type,
      Value<String>? status,
      Value<String?>? jobRef,
      Value<String?>? address,
      Value<String?>? clientName,
      Value<double>? progress,
      Value<int>? photoCount,
      Value<int>? noteCount,
      Value<int>? totalSections,
      Value<int>? completedSections,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<DateTime?>? startedAt,
      Value<DateTime?>? completedAt,
      Value<String?>? parentSurveyId,
      Value<int>? reinspectionNumber,
      Value<String?>? aiSummary,
      Value<String?>? riskSummary,
      Value<String?>? repairRecommendations,
      Value<int>? rowid}) {
    return SurveysCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      status: status ?? this.status,
      jobRef: jobRef ?? this.jobRef,
      address: address ?? this.address,
      clientName: clientName ?? this.clientName,
      progress: progress ?? this.progress,
      photoCount: photoCount ?? this.photoCount,
      noteCount: noteCount ?? this.noteCount,
      totalSections: totalSections ?? this.totalSections,
      completedSections: completedSections ?? this.completedSections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      parentSurveyId: parentSurveyId ?? this.parentSurveyId,
      reinspectionNumber: reinspectionNumber ?? this.reinspectionNumber,
      aiSummary: aiSummary ?? this.aiSummary,
      riskSummary: riskSummary ?? this.riskSummary,
      repairRecommendations:
          repairRecommendations ?? this.repairRecommendations,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (jobRef.present) {
      map['job_ref'] = Variable<String>(jobRef.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (clientName.present) {
      map['client_name'] = Variable<String>(clientName.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (photoCount.present) {
      map['photo_count'] = Variable<int>(photoCount.value);
    }
    if (noteCount.present) {
      map['note_count'] = Variable<int>(noteCount.value);
    }
    if (totalSections.present) {
      map['total_sections'] = Variable<int>(totalSections.value);
    }
    if (completedSections.present) {
      map['completed_sections'] = Variable<int>(completedSections.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (parentSurveyId.present) {
      map['parent_survey_id'] = Variable<String>(parentSurveyId.value);
    }
    if (reinspectionNumber.present) {
      map['reinspection_number'] = Variable<int>(reinspectionNumber.value);
    }
    if (aiSummary.present) {
      map['ai_summary'] = Variable<String>(aiSummary.value);
    }
    if (riskSummary.present) {
      map['risk_summary'] = Variable<String>(riskSummary.value);
    }
    if (repairRecommendations.present) {
      map['repair_recommendations'] =
          Variable<String>(repairRecommendations.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveysCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('type: $type, ')
          ..write('status: $status, ')
          ..write('jobRef: $jobRef, ')
          ..write('address: $address, ')
          ..write('clientName: $clientName, ')
          ..write('progress: $progress, ')
          ..write('photoCount: $photoCount, ')
          ..write('noteCount: $noteCount, ')
          ..write('totalSections: $totalSections, ')
          ..write('completedSections: $completedSections, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('parentSurveyId: $parentSurveyId, ')
          ..write('reinspectionNumber: $reinspectionNumber, ')
          ..write('aiSummary: $aiSummary, ')
          ..write('riskSummary: $riskSummary, ')
          ..write('repairRecommendations: $repairRecommendations, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveySectionsTable extends SurveySections
    with TableInfo<$SurveySectionsTable, SurveySection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveySectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionTypeMeta =
      const VerificationMeta('sectionType');
  @override
  late final GeneratedColumn<String> sectionType = GeneratedColumn<String>(
      'section_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionOrderMeta =
      const VerificationMeta('sectionOrder');
  @override
  late final GeneratedColumn<int> sectionOrder = GeneratedColumn<int>(
      'section_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyId,
        sectionType,
        title,
        sectionOrder,
        isCompleted,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_sections';
  @override
  VerificationContext validateIntegrity(Insertable<SurveySection> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('section_type')) {
      context.handle(
          _sectionTypeMeta,
          sectionType.isAcceptableOrUnknown(
              data['section_type']!, _sectionTypeMeta));
    } else if (isInserting) {
      context.missing(_sectionTypeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('section_order')) {
      context.handle(
          _sectionOrderMeta,
          sectionOrder.isAcceptableOrUnknown(
              data['section_order']!, _sectionOrderMeta));
    } else if (isInserting) {
      context.missing(_sectionOrderMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveySection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveySection(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      sectionType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_type'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      sectionOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}section_order'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $SurveySectionsTable createAlias(String alias) {
    return $SurveySectionsTable(attachedDatabase, alias);
  }
}

class SurveySection extends DataClass implements Insertable<SurveySection> {
  final String id;
  final String surveyId;
  final String sectionType;
  final String title;
  final int sectionOrder;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const SurveySection(
      {required this.id,
      required this.surveyId,
      required this.sectionType,
      required this.title,
      required this.sectionOrder,
      required this.isCompleted,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['section_type'] = Variable<String>(sectionType);
    map['title'] = Variable<String>(title);
    map['section_order'] = Variable<int>(sectionOrder);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SurveySectionsCompanion toCompanion(bool nullToAbsent) {
    return SurveySectionsCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      sectionType: Value(sectionType),
      title: Value(title),
      sectionOrder: Value(sectionOrder),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SurveySection.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveySection(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      sectionType: serializer.fromJson<String>(json['sectionType']),
      title: serializer.fromJson<String>(json['title']),
      sectionOrder: serializer.fromJson<int>(json['sectionOrder']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'sectionType': serializer.toJson<String>(sectionType),
      'title': serializer.toJson<String>(title),
      'sectionOrder': serializer.toJson<int>(sectionOrder),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SurveySection copyWith(
          {String? id,
          String? surveyId,
          String? sectionType,
          String? title,
          int? sectionOrder,
          bool? isCompleted,
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      SurveySection(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        sectionType: sectionType ?? this.sectionType,
        title: title ?? this.title,
        sectionOrder: sectionOrder ?? this.sectionOrder,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  SurveySection copyWithCompanion(SurveySectionsCompanion data) {
    return SurveySection(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      sectionType:
          data.sectionType.present ? data.sectionType.value : this.sectionType,
      title: data.title.present ? data.title.value : this.title,
      sectionOrder: data.sectionOrder.present
          ? data.sectionOrder.value
          : this.sectionOrder,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveySection(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionType: $sectionType, ')
          ..write('title: $title, ')
          ..write('sectionOrder: $sectionOrder, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surveyId, sectionType, title,
      sectionOrder, isCompleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveySection &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.sectionType == this.sectionType &&
          other.title == this.title &&
          other.sectionOrder == this.sectionOrder &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SurveySectionsCompanion extends UpdateCompanion<SurveySection> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String> sectionType;
  final Value<String> title;
  final Value<int> sectionOrder;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const SurveySectionsCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.sectionType = const Value.absent(),
    this.title = const Value.absent(),
    this.sectionOrder = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveySectionsCompanion.insert({
    required String id,
    required String surveyId,
    required String sectionType,
    required String title,
    required int sectionOrder,
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        sectionType = Value(sectionType),
        title = Value(title),
        sectionOrder = Value(sectionOrder),
        createdAt = Value(createdAt);
  static Insertable<SurveySection> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? sectionType,
    Expression<String>? title,
    Expression<int>? sectionOrder,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (sectionType != null) 'section_type': sectionType,
      if (title != null) 'title': title,
      if (sectionOrder != null) 'section_order': sectionOrder,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveySectionsCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String>? sectionType,
      Value<String>? title,
      Value<int>? sectionOrder,
      Value<bool>? isCompleted,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return SurveySectionsCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionType: sectionType ?? this.sectionType,
      title: title ?? this.title,
      sectionOrder: sectionOrder ?? this.sectionOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (sectionType.present) {
      map['section_type'] = Variable<String>(sectionType.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (sectionOrder.present) {
      map['section_order'] = Variable<int>(sectionOrder.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveySectionsCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionType: $sectionType, ')
          ..write('title: $title, ')
          ..write('sectionOrder: $sectionOrder, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveyAnswersTable extends SurveyAnswers
    with TableInfo<$SurveyAnswersTable, SurveyAnswer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyAnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
      'section_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldKeyMeta =
      const VerificationMeta('fieldKey');
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
      'field_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, surveyId, sectionId, fieldKey, value, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_answers';
  @override
  VerificationContext validateIntegrity(Insertable<SurveyAnswer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(_fieldKeyMeta,
          fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta));
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyAnswer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyAnswer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_id'])!,
      fieldKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $SurveyAnswersTable createAlias(String alias) {
    return $SurveyAnswersTable(attachedDatabase, alias);
  }
}

class SurveyAnswer extends DataClass implements Insertable<SurveyAnswer> {
  final String id;
  final String surveyId;
  final String sectionId;
  final String fieldKey;
  final String? value;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const SurveyAnswer(
      {required this.id,
      required this.surveyId,
      required this.sectionId,
      required this.fieldKey,
      this.value,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['section_id'] = Variable<String>(sectionId);
    map['field_key'] = Variable<String>(fieldKey);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SurveyAnswersCompanion toCompanion(bool nullToAbsent) {
    return SurveyAnswersCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      sectionId: Value(sectionId),
      fieldKey: Value(fieldKey),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SurveyAnswer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyAnswer(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      sectionId: serializer.fromJson<String>(json['sectionId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      value: serializer.fromJson<String?>(json['value']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'sectionId': serializer.toJson<String>(sectionId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'value': serializer.toJson<String?>(value),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SurveyAnswer copyWith(
          {String? id,
          String? surveyId,
          String? sectionId,
          String? fieldKey,
          Value<String?> value = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      SurveyAnswer(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        sectionId: sectionId ?? this.sectionId,
        fieldKey: fieldKey ?? this.fieldKey,
        value: value.present ? value.value : this.value,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  SurveyAnswer copyWithCompanion(SurveyAnswersCompanion data) {
    return SurveyAnswer(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyAnswer(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionId: $sectionId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, surveyId, sectionId, fieldKey, value, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyAnswer &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.sectionId == this.sectionId &&
          other.fieldKey == this.fieldKey &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SurveyAnswersCompanion extends UpdateCompanion<SurveyAnswer> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String> sectionId;
  final Value<String> fieldKey;
  final Value<String?> value;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const SurveyAnswersCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveyAnswersCompanion.insert({
    required String id,
    required String surveyId,
    required String sectionId,
    required String fieldKey,
    this.value = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        sectionId = Value(sectionId),
        fieldKey = Value(fieldKey),
        createdAt = Value(createdAt);
  static Insertable<SurveyAnswer> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? sectionId,
    Expression<String>? fieldKey,
    Expression<String>? value,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (sectionId != null) 'section_id': sectionId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveyAnswersCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String>? sectionId,
      Value<String>? fieldKey,
      Value<String?>? value,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return SurveyAnswersCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionId: sectionId ?? this.sectionId,
      fieldKey: fieldKey ?? this.fieldKey,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyAnswersCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionId: $sectionId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InspectionV2ScreensTable extends InspectionV2Screens
    with TableInfo<$InspectionV2ScreensTable, InspectionV2Screen> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectionV2ScreensTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionKeyMeta =
      const VerificationMeta('sectionKey');
  @override
  late final GeneratedColumn<String> sectionKey = GeneratedColumn<String>(
      'section_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _screenIdMeta =
      const VerificationMeta('screenId');
  @override
  late final GeneratedColumn<String> screenId = GeneratedColumn<String>(
      'screen_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _groupKeyMeta =
      const VerificationMeta('groupKey');
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
      'group_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nodeTypeMeta =
      const VerificationMeta('nodeType');
  @override
  late final GeneratedColumn<String> nodeType = GeneratedColumn<String>(
      'node_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('screen'));
  static const VerificationMeta _parentIdMeta =
      const VerificationMeta('parentId');
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
      'parent_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _displayOrderMeta =
      const VerificationMeta('displayOrder');
  @override
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
      'display_order', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _isCompletedMeta =
      const VerificationMeta('isCompleted');
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
      'is_completed', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_completed" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _phraseOutputMeta =
      const VerificationMeta('phraseOutput');
  @override
  late final GeneratedColumn<String> phraseOutput = GeneratedColumn<String>(
      'phrase_output', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyId,
        sectionKey,
        screenId,
        title,
        groupKey,
        nodeType,
        parentId,
        displayOrder,
        isCompleted,
        phraseOutput,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspection_v2_screens';
  @override
  VerificationContext validateIntegrity(Insertable<InspectionV2Screen> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('section_key')) {
      context.handle(
          _sectionKeyMeta,
          sectionKey.isAcceptableOrUnknown(
              data['section_key']!, _sectionKeyMeta));
    } else if (isInserting) {
      context.missing(_sectionKeyMeta);
    }
    if (data.containsKey('screen_id')) {
      context.handle(_screenIdMeta,
          screenId.isAcceptableOrUnknown(data['screen_id']!, _screenIdMeta));
    } else if (isInserting) {
      context.missing(_screenIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('group_key')) {
      context.handle(_groupKeyMeta,
          groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta));
    }
    if (data.containsKey('node_type')) {
      context.handle(_nodeTypeMeta,
          nodeType.isAcceptableOrUnknown(data['node_type']!, _nodeTypeMeta));
    }
    if (data.containsKey('parent_id')) {
      context.handle(_parentIdMeta,
          parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta));
    }
    if (data.containsKey('display_order')) {
      context.handle(
          _displayOrderMeta,
          displayOrder.isAcceptableOrUnknown(
              data['display_order']!, _displayOrderMeta));
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
          _isCompletedMeta,
          isCompleted.isAcceptableOrUnknown(
              data['is_completed']!, _isCompletedMeta));
    }
    if (data.containsKey('phrase_output')) {
      context.handle(
          _phraseOutputMeta,
          phraseOutput.isAcceptableOrUnknown(
              data['phrase_output']!, _phraseOutputMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InspectionV2Screen map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InspectionV2Screen(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      sectionKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_key'])!,
      screenId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}screen_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      groupKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}group_key']),
      nodeType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}node_type'])!,
      parentId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}parent_id']),
      displayOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}display_order'])!,
      isCompleted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_completed'])!,
      phraseOutput: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phrase_output']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $InspectionV2ScreensTable createAlias(String alias) {
    return $InspectionV2ScreensTable(attachedDatabase, alias);
  }
}

class InspectionV2Screen extends DataClass
    implements Insertable<InspectionV2Screen> {
  final String id;
  final String surveyId;
  final String sectionKey;
  final String screenId;
  final String title;
  final String? groupKey;
  final String nodeType;
  final String? parentId;
  final int displayOrder;
  final bool isCompleted;
  final String? phraseOutput;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const InspectionV2Screen(
      {required this.id,
      required this.surveyId,
      required this.sectionKey,
      required this.screenId,
      required this.title,
      this.groupKey,
      required this.nodeType,
      this.parentId,
      required this.displayOrder,
      required this.isCompleted,
      this.phraseOutput,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['section_key'] = Variable<String>(sectionKey);
    map['screen_id'] = Variable<String>(screenId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || groupKey != null) {
      map['group_key'] = Variable<String>(groupKey);
    }
    map['node_type'] = Variable<String>(nodeType);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['display_order'] = Variable<int>(displayOrder);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || phraseOutput != null) {
      map['phrase_output'] = Variable<String>(phraseOutput);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  InspectionV2ScreensCompanion toCompanion(bool nullToAbsent) {
    return InspectionV2ScreensCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      sectionKey: Value(sectionKey),
      screenId: Value(screenId),
      title: Value(title),
      groupKey: groupKey == null && nullToAbsent
          ? const Value.absent()
          : Value(groupKey),
      nodeType: Value(nodeType),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      displayOrder: Value(displayOrder),
      isCompleted: Value(isCompleted),
      phraseOutput: phraseOutput == null && nullToAbsent
          ? const Value.absent()
          : Value(phraseOutput),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory InspectionV2Screen.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InspectionV2Screen(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      sectionKey: serializer.fromJson<String>(json['sectionKey']),
      screenId: serializer.fromJson<String>(json['screenId']),
      title: serializer.fromJson<String>(json['title']),
      groupKey: serializer.fromJson<String?>(json['groupKey']),
      nodeType: serializer.fromJson<String>(json['nodeType']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      displayOrder: serializer.fromJson<int>(json['displayOrder']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      phraseOutput: serializer.fromJson<String?>(json['phraseOutput']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'sectionKey': serializer.toJson<String>(sectionKey),
      'screenId': serializer.toJson<String>(screenId),
      'title': serializer.toJson<String>(title),
      'groupKey': serializer.toJson<String?>(groupKey),
      'nodeType': serializer.toJson<String>(nodeType),
      'parentId': serializer.toJson<String?>(parentId),
      'displayOrder': serializer.toJson<int>(displayOrder),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'phraseOutput': serializer.toJson<String?>(phraseOutput),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  InspectionV2Screen copyWith(
          {String? id,
          String? surveyId,
          String? sectionKey,
          String? screenId,
          String? title,
          Value<String?> groupKey = const Value.absent(),
          String? nodeType,
          Value<String?> parentId = const Value.absent(),
          int? displayOrder,
          bool? isCompleted,
          Value<String?> phraseOutput = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      InspectionV2Screen(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        sectionKey: sectionKey ?? this.sectionKey,
        screenId: screenId ?? this.screenId,
        title: title ?? this.title,
        groupKey: groupKey.present ? groupKey.value : this.groupKey,
        nodeType: nodeType ?? this.nodeType,
        parentId: parentId.present ? parentId.value : this.parentId,
        displayOrder: displayOrder ?? this.displayOrder,
        isCompleted: isCompleted ?? this.isCompleted,
        phraseOutput:
            phraseOutput.present ? phraseOutput.value : this.phraseOutput,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  InspectionV2Screen copyWithCompanion(InspectionV2ScreensCompanion data) {
    return InspectionV2Screen(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      sectionKey:
          data.sectionKey.present ? data.sectionKey.value : this.sectionKey,
      screenId: data.screenId.present ? data.screenId.value : this.screenId,
      title: data.title.present ? data.title.value : this.title,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      nodeType: data.nodeType.present ? data.nodeType.value : this.nodeType,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
      isCompleted:
          data.isCompleted.present ? data.isCompleted.value : this.isCompleted,
      phraseOutput: data.phraseOutput.present
          ? data.phraseOutput.value
          : this.phraseOutput,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InspectionV2Screen(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionKey: $sectionKey, ')
          ..write('screenId: $screenId, ')
          ..write('title: $title, ')
          ..write('groupKey: $groupKey, ')
          ..write('nodeType: $nodeType, ')
          ..write('parentId: $parentId, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('phraseOutput: $phraseOutput, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      surveyId,
      sectionKey,
      screenId,
      title,
      groupKey,
      nodeType,
      parentId,
      displayOrder,
      isCompleted,
      phraseOutput,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InspectionV2Screen &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.sectionKey == this.sectionKey &&
          other.screenId == this.screenId &&
          other.title == this.title &&
          other.groupKey == this.groupKey &&
          other.nodeType == this.nodeType &&
          other.parentId == this.parentId &&
          other.displayOrder == this.displayOrder &&
          other.isCompleted == this.isCompleted &&
          other.phraseOutput == this.phraseOutput &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InspectionV2ScreensCompanion extends UpdateCompanion<InspectionV2Screen> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String> sectionKey;
  final Value<String> screenId;
  final Value<String> title;
  final Value<String?> groupKey;
  final Value<String> nodeType;
  final Value<String?> parentId;
  final Value<int> displayOrder;
  final Value<bool> isCompleted;
  final Value<String?> phraseOutput;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const InspectionV2ScreensCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.sectionKey = const Value.absent(),
    this.screenId = const Value.absent(),
    this.title = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.parentId = const Value.absent(),
    this.displayOrder = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.phraseOutput = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectionV2ScreensCompanion.insert({
    required String id,
    required String surveyId,
    required String sectionKey,
    required String screenId,
    required String title,
    this.groupKey = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.parentId = const Value.absent(),
    required int displayOrder,
    this.isCompleted = const Value.absent(),
    this.phraseOutput = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        sectionKey = Value(sectionKey),
        screenId = Value(screenId),
        title = Value(title),
        displayOrder = Value(displayOrder),
        createdAt = Value(createdAt);
  static Insertable<InspectionV2Screen> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? sectionKey,
    Expression<String>? screenId,
    Expression<String>? title,
    Expression<String>? groupKey,
    Expression<String>? nodeType,
    Expression<String>? parentId,
    Expression<int>? displayOrder,
    Expression<bool>? isCompleted,
    Expression<String>? phraseOutput,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (sectionKey != null) 'section_key': sectionKey,
      if (screenId != null) 'screen_id': screenId,
      if (title != null) 'title': title,
      if (groupKey != null) 'group_key': groupKey,
      if (nodeType != null) 'node_type': nodeType,
      if (parentId != null) 'parent_id': parentId,
      if (displayOrder != null) 'display_order': displayOrder,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (phraseOutput != null) 'phrase_output': phraseOutput,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectionV2ScreensCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String>? sectionKey,
      Value<String>? screenId,
      Value<String>? title,
      Value<String?>? groupKey,
      Value<String>? nodeType,
      Value<String?>? parentId,
      Value<int>? displayOrder,
      Value<bool>? isCompleted,
      Value<String?>? phraseOutput,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return InspectionV2ScreensCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionKey: sectionKey ?? this.sectionKey,
      screenId: screenId ?? this.screenId,
      title: title ?? this.title,
      groupKey: groupKey ?? this.groupKey,
      nodeType: nodeType ?? this.nodeType,
      parentId: parentId ?? this.parentId,
      displayOrder: displayOrder ?? this.displayOrder,
      isCompleted: isCompleted ?? this.isCompleted,
      phraseOutput: phraseOutput ?? this.phraseOutput,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (sectionKey.present) {
      map['section_key'] = Variable<String>(sectionKey.value);
    }
    if (screenId.present) {
      map['screen_id'] = Variable<String>(screenId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (nodeType.present) {
      map['node_type'] = Variable<String>(nodeType.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (phraseOutput.present) {
      map['phrase_output'] = Variable<String>(phraseOutput.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspectionV2ScreensCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionKey: $sectionKey, ')
          ..write('screenId: $screenId, ')
          ..write('title: $title, ')
          ..write('groupKey: $groupKey, ')
          ..write('nodeType: $nodeType, ')
          ..write('parentId: $parentId, ')
          ..write('displayOrder: $displayOrder, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('phraseOutput: $phraseOutput, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InspectionV2AnswersTable extends InspectionV2Answers
    with TableInfo<$InspectionV2AnswersTable, InspectionV2Answer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InspectionV2AnswersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _screenIdMeta =
      const VerificationMeta('screenId');
  @override
  late final GeneratedColumn<String> screenId = GeneratedColumn<String>(
      'screen_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldKeyMeta =
      const VerificationMeta('fieldKey');
  @override
  late final GeneratedColumn<String> fieldKey = GeneratedColumn<String>(
      'field_key', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
      'value', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, surveyId, screenId, fieldKey, value, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inspection_v2_answers';
  @override
  VerificationContext validateIntegrity(Insertable<InspectionV2Answer> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('screen_id')) {
      context.handle(_screenIdMeta,
          screenId.isAcceptableOrUnknown(data['screen_id']!, _screenIdMeta));
    } else if (isInserting) {
      context.missing(_screenIdMeta);
    }
    if (data.containsKey('field_key')) {
      context.handle(_fieldKeyMeta,
          fieldKey.isAcceptableOrUnknown(data['field_key']!, _fieldKeyMeta));
    } else if (isInserting) {
      context.missing(_fieldKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
          _valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InspectionV2Answer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InspectionV2Answer(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      screenId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}screen_id'])!,
      fieldKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_key'])!,
      value: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}value']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $InspectionV2AnswersTable createAlias(String alias) {
    return $InspectionV2AnswersTable(attachedDatabase, alias);
  }
}

class InspectionV2Answer extends DataClass
    implements Insertable<InspectionV2Answer> {
  final String id;
  final String surveyId;
  final String screenId;
  final String fieldKey;
  final String? value;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const InspectionV2Answer(
      {required this.id,
      required this.surveyId,
      required this.screenId,
      required this.fieldKey,
      this.value,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['screen_id'] = Variable<String>(screenId);
    map['field_key'] = Variable<String>(fieldKey);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  InspectionV2AnswersCompanion toCompanion(bool nullToAbsent) {
    return InspectionV2AnswersCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      screenId: Value(screenId),
      fieldKey: Value(fieldKey),
      value:
          value == null && nullToAbsent ? const Value.absent() : Value(value),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory InspectionV2Answer.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InspectionV2Answer(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      screenId: serializer.fromJson<String>(json['screenId']),
      fieldKey: serializer.fromJson<String>(json['fieldKey']),
      value: serializer.fromJson<String?>(json['value']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'screenId': serializer.toJson<String>(screenId),
      'fieldKey': serializer.toJson<String>(fieldKey),
      'value': serializer.toJson<String?>(value),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  InspectionV2Answer copyWith(
          {String? id,
          String? surveyId,
          String? screenId,
          String? fieldKey,
          Value<String?> value = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      InspectionV2Answer(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        screenId: screenId ?? this.screenId,
        fieldKey: fieldKey ?? this.fieldKey,
        value: value.present ? value.value : this.value,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  InspectionV2Answer copyWithCompanion(InspectionV2AnswersCompanion data) {
    return InspectionV2Answer(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      screenId: data.screenId.present ? data.screenId.value : this.screenId,
      fieldKey: data.fieldKey.present ? data.fieldKey.value : this.fieldKey,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InspectionV2Answer(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('screenId: $screenId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, surveyId, screenId, fieldKey, value, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InspectionV2Answer &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.screenId == this.screenId &&
          other.fieldKey == this.fieldKey &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InspectionV2AnswersCompanion extends UpdateCompanion<InspectionV2Answer> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String> screenId;
  final Value<String> fieldKey;
  final Value<String?> value;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const InspectionV2AnswersCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.screenId = const Value.absent(),
    this.fieldKey = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InspectionV2AnswersCompanion.insert({
    required String id,
    required String surveyId,
    required String screenId,
    required String fieldKey,
    this.value = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        screenId = Value(screenId),
        fieldKey = Value(fieldKey),
        createdAt = Value(createdAt);
  static Insertable<InspectionV2Answer> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? screenId,
    Expression<String>? fieldKey,
    Expression<String>? value,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (screenId != null) 'screen_id': screenId,
      if (fieldKey != null) 'field_key': fieldKey,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InspectionV2AnswersCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String>? screenId,
      Value<String>? fieldKey,
      Value<String?>? value,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return InspectionV2AnswersCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      screenId: screenId ?? this.screenId,
      fieldKey: fieldKey ?? this.fieldKey,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (screenId.present) {
      map['screen_id'] = Variable<String>(screenId.value);
    }
    if (fieldKey.present) {
      map['field_key'] = Variable<String>(fieldKey.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InspectionV2AnswersCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('screenId: $screenId, ')
          ..write('fieldKey: $fieldKey, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncQueueTable extends SyncQueue
    with TableInfo<$SyncQueueTable, SyncQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _entityTypeMeta =
      const VerificationMeta('entityType');
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
      'entity_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _entityIdMeta =
      const VerificationMeta('entityId');
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
      'entity_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
      'action', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadMeta =
      const VerificationMeta('payload');
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
      'payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _retryCountMeta =
      const VerificationMeta('retryCount');
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
      'retry_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pending'));
  static const VerificationMeta _errorMessageMeta =
      const VerificationMeta('errorMessage');
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
      'error_message', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _serverVersionMeta =
      const VerificationMeta('serverVersion');
  @override
  late final GeneratedColumn<int> serverVersion = GeneratedColumn<int>(
      'server_version', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _priorityMeta =
      const VerificationMeta('priority');
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
      'priority', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _processedAtMeta =
      const VerificationMeta('processedAt');
  @override
  late final GeneratedColumn<DateTime> processedAt = GeneratedColumn<DateTime>(
      'processed_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        entityType,
        entityId,
        action,
        payload,
        createdAt,
        retryCount,
        status,
        errorMessage,
        serverVersion,
        priority,
        processedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_queue';
  @override
  VerificationContext validateIntegrity(Insertable<SyncQueueData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('entity_type')) {
      context.handle(
          _entityTypeMeta,
          entityType.isAcceptableOrUnknown(
              data['entity_type']!, _entityTypeMeta));
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(_entityIdMeta,
          entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta));
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(_actionMeta,
          action.isAcceptableOrUnknown(data['action']!, _actionMeta));
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(_payloadMeta,
          payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta));
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
          _retryCountMeta,
          retryCount.isAcceptableOrUnknown(
              data['retry_count']!, _retryCountMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('error_message')) {
      context.handle(
          _errorMessageMeta,
          errorMessage.isAcceptableOrUnknown(
              data['error_message']!, _errorMessageMeta));
    }
    if (data.containsKey('server_version')) {
      context.handle(
          _serverVersionMeta,
          serverVersion.isAcceptableOrUnknown(
              data['server_version']!, _serverVersionMeta));
    }
    if (data.containsKey('priority')) {
      context.handle(_priorityMeta,
          priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta));
    }
    if (data.containsKey('processed_at')) {
      context.handle(
          _processedAtMeta,
          processedAt.isAcceptableOrUnknown(
              data['processed_at']!, _processedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncQueueData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      entityType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_type'])!,
      entityId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}entity_id'])!,
      action: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}action'])!,
      payload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      retryCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}retry_count'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      errorMessage: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}error_message']),
      serverVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}server_version']),
      priority: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}priority'])!,
      processedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}processed_at']),
    );
  }

  @override
  $SyncQueueTable createAlias(String alias) {
    return $SyncQueueTable(attachedDatabase, alias);
  }
}

class SyncQueueData extends DataClass implements Insertable<SyncQueueData> {
  /// Auto-incrementing primary key
  final int id;

  /// Type of entity being synced (survey, section, answer, photo)
  final String entityType;

  /// ID of the entity being synced
  final String entityId;

  /// Action to perform (create, update, delete)
  final String action;

  /// JSON payload containing the data to sync
  final String payload;

  /// When this item was added to the queue
  final DateTime createdAt;

  /// Number of retry attempts
  final int retryCount;

  /// Status of this queue item (pending, processing, completed, failed, conflict)
  final String status;

  /// Error message if sync failed
  final String? errorMessage;

  /// Server version for conflict detection
  final int? serverVersion;

  /// Priority for ordering (lower = higher priority)
  final int priority;

  /// Timestamp when item started processing (for crash recovery)
  /// If an item is in 'processing' status but processedAt is older than
  /// the stale threshold, it's considered stuck and will be reset.
  final DateTime? processedAt;
  const SyncQueueData(
      {required this.id,
      required this.entityType,
      required this.entityId,
      required this.action,
      required this.payload,
      required this.createdAt,
      required this.retryCount,
      required this.status,
      this.errorMessage,
      this.serverVersion,
      required this.priority,
      this.processedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    if (!nullToAbsent || serverVersion != null) {
      map['server_version'] = Variable<int>(serverVersion);
    }
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || processedAt != null) {
      map['processed_at'] = Variable<DateTime>(processedAt);
    }
    return map;
  }

  SyncQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncQueueCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payload: Value(payload),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      status: Value(status),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      serverVersion: serverVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(serverVersion),
      priority: Value(priority),
      processedAt: processedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(processedAt),
    );
  }

  factory SyncQueueData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncQueueData(
      id: serializer.fromJson<int>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      status: serializer.fromJson<String>(json['status']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      serverVersion: serializer.fromJson<int?>(json['serverVersion']),
      priority: serializer.fromJson<int>(json['priority']),
      processedAt: serializer.fromJson<DateTime?>(json['processedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'status': serializer.toJson<String>(status),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'serverVersion': serializer.toJson<int?>(serverVersion),
      'priority': serializer.toJson<int>(priority),
      'processedAt': serializer.toJson<DateTime?>(processedAt),
    };
  }

  SyncQueueData copyWith(
          {int? id,
          String? entityType,
          String? entityId,
          String? action,
          String? payload,
          DateTime? createdAt,
          int? retryCount,
          String? status,
          Value<String?> errorMessage = const Value.absent(),
          Value<int?> serverVersion = const Value.absent(),
          int? priority,
          Value<DateTime?> processedAt = const Value.absent()}) =>
      SyncQueueData(
        id: id ?? this.id,
        entityType: entityType ?? this.entityType,
        entityId: entityId ?? this.entityId,
        action: action ?? this.action,
        payload: payload ?? this.payload,
        createdAt: createdAt ?? this.createdAt,
        retryCount: retryCount ?? this.retryCount,
        status: status ?? this.status,
        errorMessage:
            errorMessage.present ? errorMessage.value : this.errorMessage,
        serverVersion:
            serverVersion.present ? serverVersion.value : this.serverVersion,
        priority: priority ?? this.priority,
        processedAt: processedAt.present ? processedAt.value : this.processedAt,
      );
  SyncQueueData copyWithCompanion(SyncQueueCompanion data) {
    return SyncQueueData(
      id: data.id.present ? data.id.value : this.id,
      entityType:
          data.entityType.present ? data.entityType.value : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount:
          data.retryCount.present ? data.retryCount.value : this.retryCount,
      status: data.status.present ? data.status.value : this.status,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      serverVersion: data.serverVersion.present
          ? data.serverVersion.value
          : this.serverVersion,
      priority: data.priority.present ? data.priority.value : this.priority,
      processedAt:
          data.processedAt.present ? data.processedAt.value : this.processedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('priority: $priority, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      entityType,
      entityId,
      action,
      payload,
      createdAt,
      retryCount,
      status,
      errorMessage,
      serverVersion,
      priority,
      processedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncQueueData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.status == this.status &&
          other.errorMessage == this.errorMessage &&
          other.serverVersion == this.serverVersion &&
          other.priority == this.priority &&
          other.processedAt == this.processedAt);
}

class SyncQueueCompanion extends UpdateCompanion<SyncQueueData> {
  final Value<int> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String> status;
  final Value<String?> errorMessage;
  final Value<int?> serverVersion;
  final Value<int> priority;
  final Value<DateTime?> processedAt;
  const SyncQueueCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.priority = const Value.absent(),
    this.processedAt = const Value.absent(),
  });
  SyncQueueCompanion.insert({
    this.id = const Value.absent(),
    required String entityType,
    required String entityId,
    required String action,
    required String payload,
    required DateTime createdAt,
    this.retryCount = const Value.absent(),
    this.status = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.serverVersion = const Value.absent(),
    this.priority = const Value.absent(),
    this.processedAt = const Value.absent(),
  })  : entityType = Value(entityType),
        entityId = Value(entityId),
        action = Value(action),
        payload = Value(payload),
        createdAt = Value(createdAt);
  static Insertable<SyncQueueData> custom({
    Expression<int>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? status,
    Expression<String>? errorMessage,
    Expression<int>? serverVersion,
    Expression<int>? priority,
    Expression<DateTime>? processedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (status != null) 'status': status,
      if (errorMessage != null) 'error_message': errorMessage,
      if (serverVersion != null) 'server_version': serverVersion,
      if (priority != null) 'priority': priority,
      if (processedAt != null) 'processed_at': processedAt,
    });
  }

  SyncQueueCompanion copyWith(
      {Value<int>? id,
      Value<String>? entityType,
      Value<String>? entityId,
      Value<String>? action,
      Value<String>? payload,
      Value<DateTime>? createdAt,
      Value<int>? retryCount,
      Value<String>? status,
      Value<String?>? errorMessage,
      Value<int?>? serverVersion,
      Value<int>? priority,
      Value<DateTime?>? processedAt}) {
    return SyncQueueCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      serverVersion: serverVersion ?? this.serverVersion,
      priority: priority ?? this.priority,
      processedAt: processedAt ?? this.processedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (serverVersion.present) {
      map['server_version'] = Variable<int>(serverVersion.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<DateTime>(processedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncQueueCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('status: $status, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('serverVersion: $serverVersion, ')
          ..write('priority: $priority, ')
          ..write('processedAt: $processedAt')
          ..write(')'))
        .toString();
  }
}

class $MediaItemsTable extends MediaItems
    with TableInfo<$MediaItemsTable, MediaItemsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MediaItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
      'section_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _mediaTypeMeta =
      const VerificationMeta('mediaType');
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
      'media_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _localPathMeta =
      const VerificationMeta('localPath');
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
      'local_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remotePathMeta =
      const VerificationMeta('remotePath');
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
      'remote_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _captionMeta =
      const VerificationMeta('caption');
  @override
  late final GeneratedColumn<String> caption = GeneratedColumn<String>(
      'caption', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _fileSizeMeta =
      const VerificationMeta('fileSize');
  @override
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
      'file_size', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationMeta =
      const VerificationMeta('duration');
  @override
  late final GeneratedColumn<int> duration = GeneratedColumn<int>(
      'duration', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _thumbnailPathMeta =
      const VerificationMeta('thumbnailPath');
  @override
  late final GeneratedColumn<String> thumbnailPath = GeneratedColumn<String>(
      'thumbnail_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _hasAnnotationsMeta =
      const VerificationMeta('hasAnnotations');
  @override
  late final GeneratedColumn<bool> hasAnnotations = GeneratedColumn<bool>(
      'has_annotations', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("has_annotations" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _waveformDataMeta =
      const VerificationMeta('waveformData');
  @override
  late final GeneratedColumn<String> waveformData = GeneratedColumn<String>(
      'waveform_data', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _transcriptionMeta =
      const VerificationMeta('transcription');
  @override
  late final GeneratedColumn<String> transcription = GeneratedColumn<String>(
      'transcription', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyId,
        sectionId,
        mediaType,
        localPath,
        remotePath,
        caption,
        status,
        fileSize,
        duration,
        width,
        height,
        thumbnailPath,
        hasAnnotations,
        sortOrder,
        waveformData,
        transcription,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'media_items';
  @override
  VerificationContext validateIntegrity(Insertable<MediaItemsData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    } else if (isInserting) {
      context.missing(_sectionIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(_mediaTypeMeta,
          mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta));
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(_localPathMeta,
          localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta));
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
          _remotePathMeta,
          remotePath.isAcceptableOrUnknown(
              data['remote_path']!, _remotePathMeta));
    }
    if (data.containsKey('caption')) {
      context.handle(_captionMeta,
          caption.isAcceptableOrUnknown(data['caption']!, _captionMeta));
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('file_size')) {
      context.handle(_fileSizeMeta,
          fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta));
    }
    if (data.containsKey('duration')) {
      context.handle(_durationMeta,
          duration.isAcceptableOrUnknown(data['duration']!, _durationMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('thumbnail_path')) {
      context.handle(
          _thumbnailPathMeta,
          thumbnailPath.isAcceptableOrUnknown(
              data['thumbnail_path']!, _thumbnailPathMeta));
    }
    if (data.containsKey('has_annotations')) {
      context.handle(
          _hasAnnotationsMeta,
          hasAnnotations.isAcceptableOrUnknown(
              data['has_annotations']!, _hasAnnotationsMeta));
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    if (data.containsKey('waveform_data')) {
      context.handle(
          _waveformDataMeta,
          waveformData.isAcceptableOrUnknown(
              data['waveform_data']!, _waveformDataMeta));
    }
    if (data.containsKey('transcription')) {
      context.handle(
          _transcriptionMeta,
          transcription.isAcceptableOrUnknown(
              data['transcription']!, _transcriptionMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MediaItemsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MediaItemsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_id'])!,
      mediaType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}media_type'])!,
      localPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}local_path'])!,
      remotePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_path']),
      caption: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}caption']),
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      fileSize: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}file_size']),
      duration: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration']),
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      thumbnailPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}thumbnail_path']),
      hasAnnotations: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}has_annotations'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
      waveformData: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}waveform_data']),
      transcription: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}transcription']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $MediaItemsTable createAlias(String alias) {
    return $MediaItemsTable(attachedDatabase, alias);
  }
}

class MediaItemsData extends DataClass implements Insertable<MediaItemsData> {
  /// Unique identifier
  final String id;

  /// Parent survey ID
  final String surveyId;

  /// Parent section ID
  final String sectionId;

  /// Type: photo, audio, video
  final String mediaType;

  /// Local file path on device
  final String localPath;

  /// Remote URL after sync (nullable)
  final String? remotePath;

  /// User-provided caption
  final String? caption;

  /// Sync status: local, uploading, synced, failed
  final String status;

  /// File size in bytes
  final int? fileSize;

  /// Duration in milliseconds (for audio/video)
  final int? duration;

  /// Width in pixels (for photo/video)
  final int? width;

  /// Height in pixels (for photo/video)
  final int? height;

  /// Thumbnail path (for photo/video)
  final String? thumbnailPath;

  /// Whether photo has annotations
  final bool hasAnnotations;

  /// Sort order within section
  final int sortOrder;

  /// Waveform data JSON (for audio)
  final String? waveformData;

  /// Speech-to-text transcription (for audio)
  final String? transcription;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;
  const MediaItemsData(
      {required this.id,
      required this.surveyId,
      required this.sectionId,
      required this.mediaType,
      required this.localPath,
      this.remotePath,
      this.caption,
      required this.status,
      this.fileSize,
      this.duration,
      this.width,
      this.height,
      this.thumbnailPath,
      required this.hasAnnotations,
      required this.sortOrder,
      this.waveformData,
      this.transcription,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['section_id'] = Variable<String>(sectionId);
    map['media_type'] = Variable<String>(mediaType);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || remotePath != null) {
      map['remote_path'] = Variable<String>(remotePath);
    }
    if (!nullToAbsent || caption != null) {
      map['caption'] = Variable<String>(caption);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || fileSize != null) {
      map['file_size'] = Variable<int>(fileSize);
    }
    if (!nullToAbsent || duration != null) {
      map['duration'] = Variable<int>(duration);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || thumbnailPath != null) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath);
    }
    map['has_annotations'] = Variable<bool>(hasAnnotations);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || waveformData != null) {
      map['waveform_data'] = Variable<String>(waveformData);
    }
    if (!nullToAbsent || transcription != null) {
      map['transcription'] = Variable<String>(transcription);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  MediaItemsCompanion toCompanion(bool nullToAbsent) {
    return MediaItemsCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      sectionId: Value(sectionId),
      mediaType: Value(mediaType),
      localPath: Value(localPath),
      remotePath: remotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(remotePath),
      caption: caption == null && nullToAbsent
          ? const Value.absent()
          : Value(caption),
      status: Value(status),
      fileSize: fileSize == null && nullToAbsent
          ? const Value.absent()
          : Value(fileSize),
      duration: duration == null && nullToAbsent
          ? const Value.absent()
          : Value(duration),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      thumbnailPath: thumbnailPath == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailPath),
      hasAnnotations: Value(hasAnnotations),
      sortOrder: Value(sortOrder),
      waveformData: waveformData == null && nullToAbsent
          ? const Value.absent()
          : Value(waveformData),
      transcription: transcription == null && nullToAbsent
          ? const Value.absent()
          : Value(transcription),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory MediaItemsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MediaItemsData(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      sectionId: serializer.fromJson<String>(json['sectionId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      localPath: serializer.fromJson<String>(json['localPath']),
      remotePath: serializer.fromJson<String?>(json['remotePath']),
      caption: serializer.fromJson<String?>(json['caption']),
      status: serializer.fromJson<String>(json['status']),
      fileSize: serializer.fromJson<int?>(json['fileSize']),
      duration: serializer.fromJson<int?>(json['duration']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      thumbnailPath: serializer.fromJson<String?>(json['thumbnailPath']),
      hasAnnotations: serializer.fromJson<bool>(json['hasAnnotations']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      waveformData: serializer.fromJson<String?>(json['waveformData']),
      transcription: serializer.fromJson<String?>(json['transcription']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'sectionId': serializer.toJson<String>(sectionId),
      'mediaType': serializer.toJson<String>(mediaType),
      'localPath': serializer.toJson<String>(localPath),
      'remotePath': serializer.toJson<String?>(remotePath),
      'caption': serializer.toJson<String?>(caption),
      'status': serializer.toJson<String>(status),
      'fileSize': serializer.toJson<int?>(fileSize),
      'duration': serializer.toJson<int?>(duration),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'thumbnailPath': serializer.toJson<String?>(thumbnailPath),
      'hasAnnotations': serializer.toJson<bool>(hasAnnotations),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'waveformData': serializer.toJson<String?>(waveformData),
      'transcription': serializer.toJson<String?>(transcription),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  MediaItemsData copyWith(
          {String? id,
          String? surveyId,
          String? sectionId,
          String? mediaType,
          String? localPath,
          Value<String?> remotePath = const Value.absent(),
          Value<String?> caption = const Value.absent(),
          String? status,
          Value<int?> fileSize = const Value.absent(),
          Value<int?> duration = const Value.absent(),
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          Value<String?> thumbnailPath = const Value.absent(),
          bool? hasAnnotations,
          int? sortOrder,
          Value<String?> waveformData = const Value.absent(),
          Value<String?> transcription = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      MediaItemsData(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        sectionId: sectionId ?? this.sectionId,
        mediaType: mediaType ?? this.mediaType,
        localPath: localPath ?? this.localPath,
        remotePath: remotePath.present ? remotePath.value : this.remotePath,
        caption: caption.present ? caption.value : this.caption,
        status: status ?? this.status,
        fileSize: fileSize.present ? fileSize.value : this.fileSize,
        duration: duration.present ? duration.value : this.duration,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        thumbnailPath:
            thumbnailPath.present ? thumbnailPath.value : this.thumbnailPath,
        hasAnnotations: hasAnnotations ?? this.hasAnnotations,
        sortOrder: sortOrder ?? this.sortOrder,
        waveformData:
            waveformData.present ? waveformData.value : this.waveformData,
        transcription:
            transcription.present ? transcription.value : this.transcription,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  MediaItemsData copyWithCompanion(MediaItemsCompanion data) {
    return MediaItemsData(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      remotePath:
          data.remotePath.present ? data.remotePath.value : this.remotePath,
      caption: data.caption.present ? data.caption.value : this.caption,
      status: data.status.present ? data.status.value : this.status,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      duration: data.duration.present ? data.duration.value : this.duration,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      thumbnailPath: data.thumbnailPath.present
          ? data.thumbnailPath.value
          : this.thumbnailPath,
      hasAnnotations: data.hasAnnotations.present
          ? data.hasAnnotations.value
          : this.hasAnnotations,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      waveformData: data.waveformData.present
          ? data.waveformData.value
          : this.waveformData,
      transcription: data.transcription.present
          ? data.transcription.value
          : this.transcription,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsData(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionId: $sectionId, ')
          ..write('mediaType: $mediaType, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('caption: $caption, ')
          ..write('status: $status, ')
          ..write('fileSize: $fileSize, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('hasAnnotations: $hasAnnotations, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('waveformData: $waveformData, ')
          ..write('transcription: $transcription, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      surveyId,
      sectionId,
      mediaType,
      localPath,
      remotePath,
      caption,
      status,
      fileSize,
      duration,
      width,
      height,
      thumbnailPath,
      hasAnnotations,
      sortOrder,
      waveformData,
      transcription,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItemsData &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.sectionId == this.sectionId &&
          other.mediaType == this.mediaType &&
          other.localPath == this.localPath &&
          other.remotePath == this.remotePath &&
          other.caption == this.caption &&
          other.status == this.status &&
          other.fileSize == this.fileSize &&
          other.duration == this.duration &&
          other.width == this.width &&
          other.height == this.height &&
          other.thumbnailPath == this.thumbnailPath &&
          other.hasAnnotations == this.hasAnnotations &&
          other.sortOrder == this.sortOrder &&
          other.waveformData == this.waveformData &&
          other.transcription == this.transcription &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class MediaItemsCompanion extends UpdateCompanion<MediaItemsData> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String> sectionId;
  final Value<String> mediaType;
  final Value<String> localPath;
  final Value<String?> remotePath;
  final Value<String?> caption;
  final Value<String> status;
  final Value<int?> fileSize;
  final Value<int?> duration;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> thumbnailPath;
  final Value<bool> hasAnnotations;
  final Value<int> sortOrder;
  final Value<String?> waveformData;
  final Value<String?> transcription;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const MediaItemsCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.caption = const Value.absent(),
    this.status = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.duration = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.hasAnnotations = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.waveformData = const Value.absent(),
    this.transcription = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MediaItemsCompanion.insert({
    required String id,
    required String surveyId,
    required String sectionId,
    required String mediaType,
    required String localPath,
    this.remotePath = const Value.absent(),
    this.caption = const Value.absent(),
    this.status = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.duration = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.thumbnailPath = const Value.absent(),
    this.hasAnnotations = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.waveformData = const Value.absent(),
    this.transcription = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        sectionId = Value(sectionId),
        mediaType = Value(mediaType),
        localPath = Value(localPath),
        createdAt = Value(createdAt);
  static Insertable<MediaItemsData> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? sectionId,
    Expression<String>? mediaType,
    Expression<String>? localPath,
    Expression<String>? remotePath,
    Expression<String>? caption,
    Expression<String>? status,
    Expression<int>? fileSize,
    Expression<int>? duration,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? thumbnailPath,
    Expression<bool>? hasAnnotations,
    Expression<int>? sortOrder,
    Expression<String>? waveformData,
    Expression<String>? transcription,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (sectionId != null) 'section_id': sectionId,
      if (mediaType != null) 'media_type': mediaType,
      if (localPath != null) 'local_path': localPath,
      if (remotePath != null) 'remote_path': remotePath,
      if (caption != null) 'caption': caption,
      if (status != null) 'status': status,
      if (fileSize != null) 'file_size': fileSize,
      if (duration != null) 'duration': duration,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (thumbnailPath != null) 'thumbnail_path': thumbnailPath,
      if (hasAnnotations != null) 'has_annotations': hasAnnotations,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (waveformData != null) 'waveform_data': waveformData,
      if (transcription != null) 'transcription': transcription,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MediaItemsCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String>? sectionId,
      Value<String>? mediaType,
      Value<String>? localPath,
      Value<String?>? remotePath,
      Value<String?>? caption,
      Value<String>? status,
      Value<int?>? fileSize,
      Value<int?>? duration,
      Value<int?>? width,
      Value<int?>? height,
      Value<String?>? thumbnailPath,
      Value<bool>? hasAnnotations,
      Value<int>? sortOrder,
      Value<String?>? waveformData,
      Value<String?>? transcription,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return MediaItemsCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionId: sectionId ?? this.sectionId,
      mediaType: mediaType ?? this.mediaType,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      caption: caption ?? this.caption,
      status: status ?? this.status,
      fileSize: fileSize ?? this.fileSize,
      duration: duration ?? this.duration,
      width: width ?? this.width,
      height: height ?? this.height,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      hasAnnotations: hasAnnotations ?? this.hasAnnotations,
      sortOrder: sortOrder ?? this.sortOrder,
      waveformData: waveformData ?? this.waveformData,
      transcription: transcription ?? this.transcription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (caption.present) {
      map['caption'] = Variable<String>(caption.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (duration.present) {
      map['duration'] = Variable<int>(duration.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (thumbnailPath.present) {
      map['thumbnail_path'] = Variable<String>(thumbnailPath.value);
    }
    if (hasAnnotations.present) {
      map['has_annotations'] = Variable<bool>(hasAnnotations.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (waveformData.present) {
      map['waveform_data'] = Variable<String>(waveformData.value);
    }
    if (transcription.present) {
      map['transcription'] = Variable<String>(transcription.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MediaItemsCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionId: $sectionId, ')
          ..write('mediaType: $mediaType, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('caption: $caption, ')
          ..write('status: $status, ')
          ..write('fileSize: $fileSize, ')
          ..write('duration: $duration, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('thumbnailPath: $thumbnailPath, ')
          ..write('hasAnnotations: $hasAnnotations, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('waveformData: $waveformData, ')
          ..write('transcription: $transcription, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PhotoAnnotationsTable extends PhotoAnnotations
    with TableInfo<$PhotoAnnotationsTable, PhotoAnnotationsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PhotoAnnotationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _photoIdMeta =
      const VerificationMeta('photoId');
  @override
  late final GeneratedColumn<String> photoId = GeneratedColumn<String>(
      'photo_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _elementsJsonMeta =
      const VerificationMeta('elementsJson');
  @override
  late final GeneratedColumn<String> elementsJson = GeneratedColumn<String>(
      'elements_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _annotatedImagePathMeta =
      const VerificationMeta('annotatedImagePath');
  @override
  late final GeneratedColumn<String> annotatedImagePath =
      GeneratedColumn<String>('annotated_image_path', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, photoId, elementsJson, annotatedImagePath, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'photo_annotations';
  @override
  VerificationContext validateIntegrity(
      Insertable<PhotoAnnotationsData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('photo_id')) {
      context.handle(_photoIdMeta,
          photoId.isAcceptableOrUnknown(data['photo_id']!, _photoIdMeta));
    } else if (isInserting) {
      context.missing(_photoIdMeta);
    }
    if (data.containsKey('elements_json')) {
      context.handle(
          _elementsJsonMeta,
          elementsJson.isAcceptableOrUnknown(
              data['elements_json']!, _elementsJsonMeta));
    } else if (isInserting) {
      context.missing(_elementsJsonMeta);
    }
    if (data.containsKey('annotated_image_path')) {
      context.handle(
          _annotatedImagePathMeta,
          annotatedImagePath.isAcceptableOrUnknown(
              data['annotated_image_path']!, _annotatedImagePathMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PhotoAnnotationsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PhotoAnnotationsData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      photoId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}photo_id'])!,
      elementsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}elements_json'])!,
      annotatedImagePath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}annotated_image_path']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $PhotoAnnotationsTable createAlias(String alias) {
    return $PhotoAnnotationsTable(attachedDatabase, alias);
  }
}

class PhotoAnnotationsData extends DataClass
    implements Insertable<PhotoAnnotationsData> {
  /// Unique identifier
  final String id;

  /// Parent photo media item ID
  final String photoId;

  /// JSON-encoded list of annotation elements
  final String elementsJson;

  /// Path to rendered annotated image
  final String? annotatedImagePath;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;
  const PhotoAnnotationsData(
      {required this.id,
      required this.photoId,
      required this.elementsJson,
      this.annotatedImagePath,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['photo_id'] = Variable<String>(photoId);
    map['elements_json'] = Variable<String>(elementsJson);
    if (!nullToAbsent || annotatedImagePath != null) {
      map['annotated_image_path'] = Variable<String>(annotatedImagePath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  PhotoAnnotationsCompanion toCompanion(bool nullToAbsent) {
    return PhotoAnnotationsCompanion(
      id: Value(id),
      photoId: Value(photoId),
      elementsJson: Value(elementsJson),
      annotatedImagePath: annotatedImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(annotatedImagePath),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory PhotoAnnotationsData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PhotoAnnotationsData(
      id: serializer.fromJson<String>(json['id']),
      photoId: serializer.fromJson<String>(json['photoId']),
      elementsJson: serializer.fromJson<String>(json['elementsJson']),
      annotatedImagePath:
          serializer.fromJson<String?>(json['annotatedImagePath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'photoId': serializer.toJson<String>(photoId),
      'elementsJson': serializer.toJson<String>(elementsJson),
      'annotatedImagePath': serializer.toJson<String?>(annotatedImagePath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  PhotoAnnotationsData copyWith(
          {String? id,
          String? photoId,
          String? elementsJson,
          Value<String?> annotatedImagePath = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      PhotoAnnotationsData(
        id: id ?? this.id,
        photoId: photoId ?? this.photoId,
        elementsJson: elementsJson ?? this.elementsJson,
        annotatedImagePath: annotatedImagePath.present
            ? annotatedImagePath.value
            : this.annotatedImagePath,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  PhotoAnnotationsData copyWithCompanion(PhotoAnnotationsCompanion data) {
    return PhotoAnnotationsData(
      id: data.id.present ? data.id.value : this.id,
      photoId: data.photoId.present ? data.photoId.value : this.photoId,
      elementsJson: data.elementsJson.present
          ? data.elementsJson.value
          : this.elementsJson,
      annotatedImagePath: data.annotatedImagePath.present
          ? data.annotatedImagePath.value
          : this.annotatedImagePath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PhotoAnnotationsData(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('elementsJson: $elementsJson, ')
          ..write('annotatedImagePath: $annotatedImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, photoId, elementsJson, annotatedImagePath, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PhotoAnnotationsData &&
          other.id == this.id &&
          other.photoId == this.photoId &&
          other.elementsJson == this.elementsJson &&
          other.annotatedImagePath == this.annotatedImagePath &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class PhotoAnnotationsCompanion extends UpdateCompanion<PhotoAnnotationsData> {
  final Value<String> id;
  final Value<String> photoId;
  final Value<String> elementsJson;
  final Value<String?> annotatedImagePath;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const PhotoAnnotationsCompanion({
    this.id = const Value.absent(),
    this.photoId = const Value.absent(),
    this.elementsJson = const Value.absent(),
    this.annotatedImagePath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PhotoAnnotationsCompanion.insert({
    required String id,
    required String photoId,
    required String elementsJson,
    this.annotatedImagePath = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        photoId = Value(photoId),
        elementsJson = Value(elementsJson),
        createdAt = Value(createdAt);
  static Insertable<PhotoAnnotationsData> custom({
    Expression<String>? id,
    Expression<String>? photoId,
    Expression<String>? elementsJson,
    Expression<String>? annotatedImagePath,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (photoId != null) 'photo_id': photoId,
      if (elementsJson != null) 'elements_json': elementsJson,
      if (annotatedImagePath != null)
        'annotated_image_path': annotatedImagePath,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PhotoAnnotationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? photoId,
      Value<String>? elementsJson,
      Value<String?>? annotatedImagePath,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return PhotoAnnotationsCompanion(
      id: id ?? this.id,
      photoId: photoId ?? this.photoId,
      elementsJson: elementsJson ?? this.elementsJson,
      annotatedImagePath: annotatedImagePath ?? this.annotatedImagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (photoId.present) {
      map['photo_id'] = Variable<String>(photoId.value);
    }
    if (elementsJson.present) {
      map['elements_json'] = Variable<String>(elementsJson.value);
    }
    if (annotatedImagePath.present) {
      map['annotated_image_path'] = Variable<String>(annotatedImagePath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PhotoAnnotationsCompanion(')
          ..write('id: $id, ')
          ..write('photoId: $photoId, ')
          ..write('elementsJson: $elementsJson, ')
          ..write('annotatedImagePath: $annotatedImagePath, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SignaturesTable extends Signatures
    with TableInfo<$SignaturesTable, SignatureData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SignaturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sectionIdMeta =
      const VerificationMeta('sectionId');
  @override
  late final GeneratedColumn<String> sectionId = GeneratedColumn<String>(
      'section_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _signerNameMeta =
      const VerificationMeta('signerName');
  @override
  late final GeneratedColumn<String> signerName = GeneratedColumn<String>(
      'signer_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _signerRoleMeta =
      const VerificationMeta('signerRole');
  @override
  late final GeneratedColumn<String> signerRole = GeneratedColumn<String>(
      'signer_role', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _strokesJsonMeta =
      const VerificationMeta('strokesJson');
  @override
  late final GeneratedColumn<String> strokesJson = GeneratedColumn<String>(
      'strokes_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('local'));
  static const VerificationMeta _previewPathMeta =
      const VerificationMeta('previewPath');
  @override
  late final GeneratedColumn<String> previewPath = GeneratedColumn<String>(
      'preview_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
      'width', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
      'height', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
      'updated_at', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyId,
        sectionId,
        signerName,
        signerRole,
        strokesJson,
        status,
        previewPath,
        width,
        height,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'signatures';
  @override
  VerificationContext validateIntegrity(Insertable<SignatureData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('section_id')) {
      context.handle(_sectionIdMeta,
          sectionId.isAcceptableOrUnknown(data['section_id']!, _sectionIdMeta));
    }
    if (data.containsKey('signer_name')) {
      context.handle(
          _signerNameMeta,
          signerName.isAcceptableOrUnknown(
              data['signer_name']!, _signerNameMeta));
    }
    if (data.containsKey('signer_role')) {
      context.handle(
          _signerRoleMeta,
          signerRole.isAcceptableOrUnknown(
              data['signer_role']!, _signerRoleMeta));
    }
    if (data.containsKey('strokes_json')) {
      context.handle(
          _strokesJsonMeta,
          strokesJson.isAcceptableOrUnknown(
              data['strokes_json']!, _strokesJsonMeta));
    } else if (isInserting) {
      context.missing(_strokesJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    }
    if (data.containsKey('preview_path')) {
      context.handle(
          _previewPathMeta,
          previewPath.isAcceptableOrUnknown(
              data['preview_path']!, _previewPathMeta));
    }
    if (data.containsKey('width')) {
      context.handle(
          _widthMeta, width.isAcceptableOrUnknown(data['width']!, _widthMeta));
    }
    if (data.containsKey('height')) {
      context.handle(_heightMeta,
          height.isAcceptableOrUnknown(data['height']!, _heightMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SignatureData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SignatureData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      sectionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}section_id']),
      signerName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signer_name']),
      signerRole: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}signer_role']),
      strokesJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}strokes_json'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      previewPath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}preview_path']),
      width: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}width']),
      height: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}height']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at']),
    );
  }

  @override
  $SignaturesTable createAlias(String alias) {
    return $SignaturesTable(attachedDatabase, alias);
  }
}

class SignatureData extends DataClass implements Insertable<SignatureData> {
  /// Unique identifier
  final String id;

  /// Parent survey ID
  final String surveyId;

  /// Parent section ID (optional - signatures can be survey-level)
  final String? sectionId;

  /// Name of the person signing
  final String? signerName;

  /// Role of the signer (e.g., Surveyor, Client, Witness)
  final String? signerRole;

  /// JSON-encoded list of strokes
  final String strokesJson;

  /// Sync status: local, uploading, synced, failed
  final String status;

  /// Path to PNG preview image
  final String? previewPath;

  /// Canvas width when signature was captured
  final int? width;

  /// Canvas height when signature was captured
  final int? height;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;
  const SignatureData(
      {required this.id,
      required this.surveyId,
      this.sectionId,
      this.signerName,
      this.signerRole,
      required this.strokesJson,
      required this.status,
      this.previewPath,
      this.width,
      this.height,
      required this.createdAt,
      this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    if (!nullToAbsent || sectionId != null) {
      map['section_id'] = Variable<String>(sectionId);
    }
    if (!nullToAbsent || signerName != null) {
      map['signer_name'] = Variable<String>(signerName);
    }
    if (!nullToAbsent || signerRole != null) {
      map['signer_role'] = Variable<String>(signerRole);
    }
    map['strokes_json'] = Variable<String>(strokesJson);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || previewPath != null) {
      map['preview_path'] = Variable<String>(previewPath);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    return map;
  }

  SignaturesCompanion toCompanion(bool nullToAbsent) {
    return SignaturesCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      sectionId: sectionId == null && nullToAbsent
          ? const Value.absent()
          : Value(sectionId),
      signerName: signerName == null && nullToAbsent
          ? const Value.absent()
          : Value(signerName),
      signerRole: signerRole == null && nullToAbsent
          ? const Value.absent()
          : Value(signerRole),
      strokesJson: Value(strokesJson),
      status: Value(status),
      previewPath: previewPath == null && nullToAbsent
          ? const Value.absent()
          : Value(previewPath),
      width:
          width == null && nullToAbsent ? const Value.absent() : Value(width),
      height:
          height == null && nullToAbsent ? const Value.absent() : Value(height),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory SignatureData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SignatureData(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      sectionId: serializer.fromJson<String?>(json['sectionId']),
      signerName: serializer.fromJson<String?>(json['signerName']),
      signerRole: serializer.fromJson<String?>(json['signerRole']),
      strokesJson: serializer.fromJson<String>(json['strokesJson']),
      status: serializer.fromJson<String>(json['status']),
      previewPath: serializer.fromJson<String?>(json['previewPath']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'sectionId': serializer.toJson<String?>(sectionId),
      'signerName': serializer.toJson<String?>(signerName),
      'signerRole': serializer.toJson<String?>(signerRole),
      'strokesJson': serializer.toJson<String>(strokesJson),
      'status': serializer.toJson<String>(status),
      'previewPath': serializer.toJson<String?>(previewPath),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
    };
  }

  SignatureData copyWith(
          {String? id,
          String? surveyId,
          Value<String?> sectionId = const Value.absent(),
          Value<String?> signerName = const Value.absent(),
          Value<String?> signerRole = const Value.absent(),
          String? strokesJson,
          String? status,
          Value<String?> previewPath = const Value.absent(),
          Value<int?> width = const Value.absent(),
          Value<int?> height = const Value.absent(),
          DateTime? createdAt,
          Value<DateTime?> updatedAt = const Value.absent()}) =>
      SignatureData(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        sectionId: sectionId.present ? sectionId.value : this.sectionId,
        signerName: signerName.present ? signerName.value : this.signerName,
        signerRole: signerRole.present ? signerRole.value : this.signerRole,
        strokesJson: strokesJson ?? this.strokesJson,
        status: status ?? this.status,
        previewPath: previewPath.present ? previewPath.value : this.previewPath,
        width: width.present ? width.value : this.width,
        height: height.present ? height.value : this.height,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
      );
  SignatureData copyWithCompanion(SignaturesCompanion data) {
    return SignatureData(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      sectionId: data.sectionId.present ? data.sectionId.value : this.sectionId,
      signerName:
          data.signerName.present ? data.signerName.value : this.signerName,
      signerRole:
          data.signerRole.present ? data.signerRole.value : this.signerRole,
      strokesJson:
          data.strokesJson.present ? data.strokesJson.value : this.strokesJson,
      status: data.status.present ? data.status.value : this.status,
      previewPath:
          data.previewPath.present ? data.previewPath.value : this.previewPath,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SignatureData(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionId: $sectionId, ')
          ..write('signerName: $signerName, ')
          ..write('signerRole: $signerRole, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('status: $status, ')
          ..write('previewPath: $previewPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      surveyId,
      sectionId,
      signerName,
      signerRole,
      strokesJson,
      status,
      previewPath,
      width,
      height,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SignatureData &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.sectionId == this.sectionId &&
          other.signerName == this.signerName &&
          other.signerRole == this.signerRole &&
          other.strokesJson == this.strokesJson &&
          other.status == this.status &&
          other.previewPath == this.previewPath &&
          other.width == this.width &&
          other.height == this.height &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SignaturesCompanion extends UpdateCompanion<SignatureData> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String?> sectionId;
  final Value<String?> signerName;
  final Value<String?> signerRole;
  final Value<String> strokesJson;
  final Value<String> status;
  final Value<String?> previewPath;
  final Value<int?> width;
  final Value<int?> height;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<int> rowid;
  const SignaturesCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.sectionId = const Value.absent(),
    this.signerName = const Value.absent(),
    this.signerRole = const Value.absent(),
    this.strokesJson = const Value.absent(),
    this.status = const Value.absent(),
    this.previewPath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SignaturesCompanion.insert({
    required String id,
    required String surveyId,
    this.sectionId = const Value.absent(),
    this.signerName = const Value.absent(),
    this.signerRole = const Value.absent(),
    required String strokesJson,
    this.status = const Value.absent(),
    this.previewPath = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        strokesJson = Value(strokesJson),
        createdAt = Value(createdAt);
  static Insertable<SignatureData> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? sectionId,
    Expression<String>? signerName,
    Expression<String>? signerRole,
    Expression<String>? strokesJson,
    Expression<String>? status,
    Expression<String>? previewPath,
    Expression<int>? width,
    Expression<int>? height,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (sectionId != null) 'section_id': sectionId,
      if (signerName != null) 'signer_name': signerName,
      if (signerRole != null) 'signer_role': signerRole,
      if (strokesJson != null) 'strokes_json': strokesJson,
      if (status != null) 'status': status,
      if (previewPath != null) 'preview_path': previewPath,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SignaturesCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String?>? sectionId,
      Value<String?>? signerName,
      Value<String?>? signerRole,
      Value<String>? strokesJson,
      Value<String>? status,
      Value<String?>? previewPath,
      Value<int?>? width,
      Value<int?>? height,
      Value<DateTime>? createdAt,
      Value<DateTime?>? updatedAt,
      Value<int>? rowid}) {
    return SignaturesCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      sectionId: sectionId ?? this.sectionId,
      signerName: signerName ?? this.signerName,
      signerRole: signerRole ?? this.signerRole,
      strokesJson: strokesJson ?? this.strokesJson,
      status: status ?? this.status,
      previewPath: previewPath ?? this.previewPath,
      width: width ?? this.width,
      height: height ?? this.height,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (sectionId.present) {
      map['section_id'] = Variable<String>(sectionId.value);
    }
    if (signerName.present) {
      map['signer_name'] = Variable<String>(signerName.value);
    }
    if (signerRole.present) {
      map['signer_role'] = Variable<String>(signerRole.value);
    }
    if (strokesJson.present) {
      map['strokes_json'] = Variable<String>(strokesJson.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (previewPath.present) {
      map['preview_path'] = Variable<String>(previewPath.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SignaturesCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('sectionId: $sectionId, ')
          ..write('signerName: $signerName, ')
          ..write('signerRole: $signerRole, ')
          ..write('strokesJson: $strokesJson, ')
          ..write('status: $status, ')
          ..write('previewPath: $previewPath, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GeneratedReportsTable extends GeneratedReports
    with TableInfo<$GeneratedReportsTable, GeneratedReportData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GeneratedReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyTitleMeta =
      const VerificationMeta('surveyTitle');
  @override
  late final GeneratedColumn<String> surveyTitle = GeneratedColumn<String>(
      'survey_title', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  static const VerificationMeta _filePathMeta =
      const VerificationMeta('filePath');
  @override
  late final GeneratedColumn<String> filePath = GeneratedColumn<String>(
      'file_path', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fileNameMeta =
      const VerificationMeta('fileName');
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
      'file_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sizeBytesMeta =
      const VerificationMeta('sizeBytes');
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
      'size_bytes', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _moduleTypeMeta =
      const VerificationMeta('moduleType');
  @override
  late final GeneratedColumn<String> moduleType = GeneratedColumn<String>(
      'module_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('inspection'));
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
      'format', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('pdf'));
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
      'style', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('legacy'));
  static const VerificationMeta _remoteUrlMeta =
      const VerificationMeta('remoteUrl');
  @override
  late final GeneratedColumn<String> remoteUrl = GeneratedColumn<String>(
      'remote_url', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _checksumMeta =
      const VerificationMeta('checksum');
  @override
  late final GeneratedColumn<String> checksum = GeneratedColumn<String>(
      'checksum', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant(''));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyId,
        surveyTitle,
        filePath,
        fileName,
        sizeBytes,
        generatedAt,
        moduleType,
        format,
        style,
        remoteUrl,
        checksum
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'generated_reports';
  @override
  VerificationContext validateIntegrity(
      Insertable<GeneratedReportData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('survey_title')) {
      context.handle(
          _surveyTitleMeta,
          surveyTitle.isAcceptableOrUnknown(
              data['survey_title']!, _surveyTitleMeta));
    }
    if (data.containsKey('file_path')) {
      context.handle(_filePathMeta,
          filePath.isAcceptableOrUnknown(data['file_path']!, _filePathMeta));
    } else if (isInserting) {
      context.missing(_filePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(_fileNameMeta,
          fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta));
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(_sizeBytesMeta,
          sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta));
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('module_type')) {
      context.handle(
          _moduleTypeMeta,
          moduleType.isAcceptableOrUnknown(
              data['module_type']!, _moduleTypeMeta));
    }
    if (data.containsKey('format')) {
      context.handle(_formatMeta,
          format.isAcceptableOrUnknown(data['format']!, _formatMeta));
    }
    if (data.containsKey('style')) {
      context.handle(
          _styleMeta, style.isAcceptableOrUnknown(data['style']!, _styleMeta));
    }
    if (data.containsKey('remote_url')) {
      context.handle(_remoteUrlMeta,
          remoteUrl.isAcceptableOrUnknown(data['remote_url']!, _remoteUrlMeta));
    }
    if (data.containsKey('checksum')) {
      context.handle(_checksumMeta,
          checksum.isAcceptableOrUnknown(data['checksum']!, _checksumMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GeneratedReportData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GeneratedReportData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      surveyTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_title'])!,
      filePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_path'])!,
      fileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}file_name'])!,
      sizeBytes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}size_bytes'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      moduleType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}module_type'])!,
      format: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}format'])!,
      style: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}style'])!,
      remoteUrl: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remote_url']),
      checksum: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}checksum'])!,
    );
  }

  @override
  $GeneratedReportsTable createAlias(String alias) {
    return $GeneratedReportsTable(attachedDatabase, alias);
  }
}

class GeneratedReportData extends DataClass
    implements Insertable<GeneratedReportData> {
  /// Unique identifier (UUID).
  final String id;

  /// Survey this report was generated for.
  final String surveyId;

  /// Human-readable survey title at time of generation.
  final String surveyTitle;

  /// Absolute file path on device.
  final String filePath;

  /// Display filename (e.g. "my_survey_1706000000.pdf").
  final String fileName;

  /// File size in bytes.
  final int sizeBytes;

  /// When the report was generated.
  final DateTime generatedAt;

  /// Module type: 'inspection' or 'valuation'.
  final String moduleType;

  /// Output format: 'pdf' or 'docx'.
  final String format;

  /// Export style: 'legacy' or 'premium'.
  final String style;

  /// Backend URL after upload (null if not uploaded).
  final String? remoteUrl;

  /// SHA-256 checksum of file bytes for integrity.
  final String checksum;
  const GeneratedReportData(
      {required this.id,
      required this.surveyId,
      required this.surveyTitle,
      required this.filePath,
      required this.fileName,
      required this.sizeBytes,
      required this.generatedAt,
      required this.moduleType,
      required this.format,
      required this.style,
      this.remoteUrl,
      required this.checksum});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['survey_title'] = Variable<String>(surveyTitle);
    map['file_path'] = Variable<String>(filePath);
    map['file_name'] = Variable<String>(fileName);
    map['size_bytes'] = Variable<int>(sizeBytes);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['module_type'] = Variable<String>(moduleType);
    map['format'] = Variable<String>(format);
    map['style'] = Variable<String>(style);
    if (!nullToAbsent || remoteUrl != null) {
      map['remote_url'] = Variable<String>(remoteUrl);
    }
    map['checksum'] = Variable<String>(checksum);
    return map;
  }

  GeneratedReportsCompanion toCompanion(bool nullToAbsent) {
    return GeneratedReportsCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      surveyTitle: Value(surveyTitle),
      filePath: Value(filePath),
      fileName: Value(fileName),
      sizeBytes: Value(sizeBytes),
      generatedAt: Value(generatedAt),
      moduleType: Value(moduleType),
      format: Value(format),
      style: Value(style),
      remoteUrl: remoteUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteUrl),
      checksum: Value(checksum),
    );
  }

  factory GeneratedReportData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GeneratedReportData(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      surveyTitle: serializer.fromJson<String>(json['surveyTitle']),
      filePath: serializer.fromJson<String>(json['filePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      sizeBytes: serializer.fromJson<int>(json['sizeBytes']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      moduleType: serializer.fromJson<String>(json['moduleType']),
      format: serializer.fromJson<String>(json['format']),
      style: serializer.fromJson<String>(json['style']),
      remoteUrl: serializer.fromJson<String?>(json['remoteUrl']),
      checksum: serializer.fromJson<String>(json['checksum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'surveyTitle': serializer.toJson<String>(surveyTitle),
      'filePath': serializer.toJson<String>(filePath),
      'fileName': serializer.toJson<String>(fileName),
      'sizeBytes': serializer.toJson<int>(sizeBytes),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'moduleType': serializer.toJson<String>(moduleType),
      'format': serializer.toJson<String>(format),
      'style': serializer.toJson<String>(style),
      'remoteUrl': serializer.toJson<String?>(remoteUrl),
      'checksum': serializer.toJson<String>(checksum),
    };
  }

  GeneratedReportData copyWith(
          {String? id,
          String? surveyId,
          String? surveyTitle,
          String? filePath,
          String? fileName,
          int? sizeBytes,
          DateTime? generatedAt,
          String? moduleType,
          String? format,
          String? style,
          Value<String?> remoteUrl = const Value.absent(),
          String? checksum}) =>
      GeneratedReportData(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        surveyTitle: surveyTitle ?? this.surveyTitle,
        filePath: filePath ?? this.filePath,
        fileName: fileName ?? this.fileName,
        sizeBytes: sizeBytes ?? this.sizeBytes,
        generatedAt: generatedAt ?? this.generatedAt,
        moduleType: moduleType ?? this.moduleType,
        format: format ?? this.format,
        style: style ?? this.style,
        remoteUrl: remoteUrl.present ? remoteUrl.value : this.remoteUrl,
        checksum: checksum ?? this.checksum,
      );
  GeneratedReportData copyWithCompanion(GeneratedReportsCompanion data) {
    return GeneratedReportData(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      surveyTitle:
          data.surveyTitle.present ? data.surveyTitle.value : this.surveyTitle,
      filePath: data.filePath.present ? data.filePath.value : this.filePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      moduleType:
          data.moduleType.present ? data.moduleType.value : this.moduleType,
      format: data.format.present ? data.format.value : this.format,
      style: data.style.present ? data.style.value : this.style,
      remoteUrl: data.remoteUrl.present ? data.remoteUrl.value : this.remoteUrl,
      checksum: data.checksum.present ? data.checksum.value : this.checksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedReportData(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('surveyTitle: $surveyTitle, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('moduleType: $moduleType, ')
          ..write('format: $format, ')
          ..write('style: $style, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('checksum: $checksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surveyId, surveyTitle, filePath, fileName,
      sizeBytes, generatedAt, moduleType, format, style, remoteUrl, checksum);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GeneratedReportData &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.surveyTitle == this.surveyTitle &&
          other.filePath == this.filePath &&
          other.fileName == this.fileName &&
          other.sizeBytes == this.sizeBytes &&
          other.generatedAt == this.generatedAt &&
          other.moduleType == this.moduleType &&
          other.format == this.format &&
          other.style == this.style &&
          other.remoteUrl == this.remoteUrl &&
          other.checksum == this.checksum);
}

class GeneratedReportsCompanion extends UpdateCompanion<GeneratedReportData> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String> surveyTitle;
  final Value<String> filePath;
  final Value<String> fileName;
  final Value<int> sizeBytes;
  final Value<DateTime> generatedAt;
  final Value<String> moduleType;
  final Value<String> format;
  final Value<String> style;
  final Value<String?> remoteUrl;
  final Value<String> checksum;
  final Value<int> rowid;
  const GeneratedReportsCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.surveyTitle = const Value.absent(),
    this.filePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.moduleType = const Value.absent(),
    this.format = const Value.absent(),
    this.style = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GeneratedReportsCompanion.insert({
    required String id,
    required String surveyId,
    this.surveyTitle = const Value.absent(),
    required String filePath,
    required String fileName,
    this.sizeBytes = const Value.absent(),
    required DateTime generatedAt,
    this.moduleType = const Value.absent(),
    this.format = const Value.absent(),
    this.style = const Value.absent(),
    this.remoteUrl = const Value.absent(),
    this.checksum = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        filePath = Value(filePath),
        fileName = Value(fileName),
        generatedAt = Value(generatedAt);
  static Insertable<GeneratedReportData> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? surveyTitle,
    Expression<String>? filePath,
    Expression<String>? fileName,
    Expression<int>? sizeBytes,
    Expression<DateTime>? generatedAt,
    Expression<String>? moduleType,
    Expression<String>? format,
    Expression<String>? style,
    Expression<String>? remoteUrl,
    Expression<String>? checksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (surveyTitle != null) 'survey_title': surveyTitle,
      if (filePath != null) 'file_path': filePath,
      if (fileName != null) 'file_name': fileName,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (moduleType != null) 'module_type': moduleType,
      if (format != null) 'format': format,
      if (style != null) 'style': style,
      if (remoteUrl != null) 'remote_url': remoteUrl,
      if (checksum != null) 'checksum': checksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GeneratedReportsCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String>? surveyTitle,
      Value<String>? filePath,
      Value<String>? fileName,
      Value<int>? sizeBytes,
      Value<DateTime>? generatedAt,
      Value<String>? moduleType,
      Value<String>? format,
      Value<String>? style,
      Value<String?>? remoteUrl,
      Value<String>? checksum,
      Value<int>? rowid}) {
    return GeneratedReportsCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      surveyTitle: surveyTitle ?? this.surveyTitle,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      generatedAt: generatedAt ?? this.generatedAt,
      moduleType: moduleType ?? this.moduleType,
      format: format ?? this.format,
      style: style ?? this.style,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      checksum: checksum ?? this.checksum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (surveyTitle.present) {
      map['survey_title'] = Variable<String>(surveyTitle.value);
    }
    if (filePath.present) {
      map['file_path'] = Variable<String>(filePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (moduleType.present) {
      map['module_type'] = Variable<String>(moduleType.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (remoteUrl.present) {
      map['remote_url'] = Variable<String>(remoteUrl.value);
    }
    if (checksum.present) {
      map['checksum'] = Variable<String>(checksum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GeneratedReportsCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('surveyTitle: $surveyTitle, ')
          ..write('filePath: $filePath, ')
          ..write('fileName: $fileName, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('moduleType: $moduleType, ')
          ..write('format: $format, ')
          ..write('style: $style, ')
          ..write('remoteUrl: $remoteUrl, ')
          ..write('checksum: $checksum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveyRecommendationsTable extends SurveyRecommendations
    with TableInfo<$SurveyRecommendationsTable, SurveyRecommendation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyRecommendationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _categoryMeta =
      const VerificationMeta('category');
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
      'category', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _severityMeta =
      const VerificationMeta('severity');
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
      'severity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _screenIdMeta =
      const VerificationMeta('screenId');
  @override
  late final GeneratedColumn<String> screenId = GeneratedColumn<String>(
      'screen_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fieldIdMeta =
      const VerificationMeta('fieldId');
  @override
  late final GeneratedColumn<String> fieldId = GeneratedColumn<String>(
      'field_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
      'reason', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _suggestedTextMeta =
      const VerificationMeta('suggestedText');
  @override
  late final GeneratedColumn<String> suggestedText = GeneratedColumn<String>(
      'suggested_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _acceptedMeta =
      const VerificationMeta('accepted');
  @override
  late final GeneratedColumn<bool> accepted = GeneratedColumn<bool>(
      'accepted', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("accepted" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _sourceTypeMeta =
      const VerificationMeta('sourceType');
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
      'source_type', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('rule'));
  static const VerificationMeta _ruleVersionMeta =
      const VerificationMeta('ruleVersion');
  @override
  late final GeneratedColumn<String> ruleVersion = GeneratedColumn<String>(
      'rule_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _aiModelVersionMeta =
      const VerificationMeta('aiModelVersion');
  @override
  late final GeneratedColumn<String> aiModelVersion = GeneratedColumn<String>(
      'ai_model_version', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _confidenceScoreMeta =
      const VerificationMeta('confidenceScore');
  @override
  late final GeneratedColumn<double> confidenceScore = GeneratedColumn<double>(
      'confidence_score', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _generationTimestampMeta =
      const VerificationMeta('generationTimestamp');
  @override
  late final GeneratedColumn<int> generationTimestamp = GeneratedColumn<int>(
      'generation_timestamp', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _internalReasoningMeta =
      const VerificationMeta('internalReasoning');
  @override
  late final GeneratedColumn<String> internalReasoning =
      GeneratedColumn<String>('internal_reasoning', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _auditHashMeta =
      const VerificationMeta('auditHash');
  @override
  late final GeneratedColumn<String> auditHash = GeneratedColumn<String>(
      'audit_hash', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyId,
        category,
        severity,
        screenId,
        fieldId,
        reason,
        suggestedText,
        accepted,
        createdAt,
        sourceType,
        ruleVersion,
        aiModelVersion,
        confidenceScore,
        generationTimestamp,
        internalReasoning,
        auditHash
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_recommendations';
  @override
  VerificationContext validateIntegrity(
      Insertable<SurveyRecommendation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('category')) {
      context.handle(_categoryMeta,
          category.isAcceptableOrUnknown(data['category']!, _categoryMeta));
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(_severityMeta,
          severity.isAcceptableOrUnknown(data['severity']!, _severityMeta));
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('screen_id')) {
      context.handle(_screenIdMeta,
          screenId.isAcceptableOrUnknown(data['screen_id']!, _screenIdMeta));
    } else if (isInserting) {
      context.missing(_screenIdMeta);
    }
    if (data.containsKey('field_id')) {
      context.handle(_fieldIdMeta,
          fieldId.isAcceptableOrUnknown(data['field_id']!, _fieldIdMeta));
    }
    if (data.containsKey('reason')) {
      context.handle(_reasonMeta,
          reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta));
    } else if (isInserting) {
      context.missing(_reasonMeta);
    }
    if (data.containsKey('suggested_text')) {
      context.handle(
          _suggestedTextMeta,
          suggestedText.isAcceptableOrUnknown(
              data['suggested_text']!, _suggestedTextMeta));
    } else if (isInserting) {
      context.missing(_suggestedTextMeta);
    }
    if (data.containsKey('accepted')) {
      context.handle(_acceptedMeta,
          accepted.isAcceptableOrUnknown(data['accepted']!, _acceptedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('source_type')) {
      context.handle(
          _sourceTypeMeta,
          sourceType.isAcceptableOrUnknown(
              data['source_type']!, _sourceTypeMeta));
    }
    if (data.containsKey('rule_version')) {
      context.handle(
          _ruleVersionMeta,
          ruleVersion.isAcceptableOrUnknown(
              data['rule_version']!, _ruleVersionMeta));
    }
    if (data.containsKey('ai_model_version')) {
      context.handle(
          _aiModelVersionMeta,
          aiModelVersion.isAcceptableOrUnknown(
              data['ai_model_version']!, _aiModelVersionMeta));
    }
    if (data.containsKey('confidence_score')) {
      context.handle(
          _confidenceScoreMeta,
          confidenceScore.isAcceptableOrUnknown(
              data['confidence_score']!, _confidenceScoreMeta));
    }
    if (data.containsKey('generation_timestamp')) {
      context.handle(
          _generationTimestampMeta,
          generationTimestamp.isAcceptableOrUnknown(
              data['generation_timestamp']!, _generationTimestampMeta));
    }
    if (data.containsKey('internal_reasoning')) {
      context.handle(
          _internalReasoningMeta,
          internalReasoning.isAcceptableOrUnknown(
              data['internal_reasoning']!, _internalReasoningMeta));
    }
    if (data.containsKey('audit_hash')) {
      context.handle(_auditHashMeta,
          auditHash.isAcceptableOrUnknown(data['audit_hash']!, _auditHashMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyRecommendation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyRecommendation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      category: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}category'])!,
      severity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}severity'])!,
      screenId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}screen_id'])!,
      fieldId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}field_id']),
      reason: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}reason'])!,
      suggestedText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}suggested_text'])!,
      accepted: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}accepted'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      sourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}source_type'])!,
      ruleVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rule_version']),
      aiModelVersion: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}ai_model_version']),
      confidenceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}confidence_score']),
      generationTimestamp: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}generation_timestamp']),
      internalReasoning: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}internal_reasoning']),
      auditHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}audit_hash']),
    );
  }

  @override
  $SurveyRecommendationsTable createAlias(String alias) {
    return $SurveyRecommendationsTable(attachedDatabase, alias);
  }
}

class SurveyRecommendation extends DataClass
    implements Insertable<SurveyRecommendation> {
  final String id;
  final String surveyId;
  final String category;
  final String severity;
  final String screenId;
  final String? fieldId;
  final String reason;
  final String suggestedText;
  final bool accepted;
  final DateTime createdAt;
  final String sourceType;
  final String? ruleVersion;
  final String? aiModelVersion;
  final double? confidenceScore;
  final int? generationTimestamp;
  final String? internalReasoning;
  final String? auditHash;
  const SurveyRecommendation(
      {required this.id,
      required this.surveyId,
      required this.category,
      required this.severity,
      required this.screenId,
      this.fieldId,
      required this.reason,
      required this.suggestedText,
      required this.accepted,
      required this.createdAt,
      required this.sourceType,
      this.ruleVersion,
      this.aiModelVersion,
      this.confidenceScore,
      this.generationTimestamp,
      this.internalReasoning,
      this.auditHash});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['category'] = Variable<String>(category);
    map['severity'] = Variable<String>(severity);
    map['screen_id'] = Variable<String>(screenId);
    if (!nullToAbsent || fieldId != null) {
      map['field_id'] = Variable<String>(fieldId);
    }
    map['reason'] = Variable<String>(reason);
    map['suggested_text'] = Variable<String>(suggestedText);
    map['accepted'] = Variable<bool>(accepted);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || ruleVersion != null) {
      map['rule_version'] = Variable<String>(ruleVersion);
    }
    if (!nullToAbsent || aiModelVersion != null) {
      map['ai_model_version'] = Variable<String>(aiModelVersion);
    }
    if (!nullToAbsent || confidenceScore != null) {
      map['confidence_score'] = Variable<double>(confidenceScore);
    }
    if (!nullToAbsent || generationTimestamp != null) {
      map['generation_timestamp'] = Variable<int>(generationTimestamp);
    }
    if (!nullToAbsent || internalReasoning != null) {
      map['internal_reasoning'] = Variable<String>(internalReasoning);
    }
    if (!nullToAbsent || auditHash != null) {
      map['audit_hash'] = Variable<String>(auditHash);
    }
    return map;
  }

  SurveyRecommendationsCompanion toCompanion(bool nullToAbsent) {
    return SurveyRecommendationsCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      category: Value(category),
      severity: Value(severity),
      screenId: Value(screenId),
      fieldId: fieldId == null && nullToAbsent
          ? const Value.absent()
          : Value(fieldId),
      reason: Value(reason),
      suggestedText: Value(suggestedText),
      accepted: Value(accepted),
      createdAt: Value(createdAt),
      sourceType: Value(sourceType),
      ruleVersion: ruleVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(ruleVersion),
      aiModelVersion: aiModelVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(aiModelVersion),
      confidenceScore: confidenceScore == null && nullToAbsent
          ? const Value.absent()
          : Value(confidenceScore),
      generationTimestamp: generationTimestamp == null && nullToAbsent
          ? const Value.absent()
          : Value(generationTimestamp),
      internalReasoning: internalReasoning == null && nullToAbsent
          ? const Value.absent()
          : Value(internalReasoning),
      auditHash: auditHash == null && nullToAbsent
          ? const Value.absent()
          : Value(auditHash),
    );
  }

  factory SurveyRecommendation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyRecommendation(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      category: serializer.fromJson<String>(json['category']),
      severity: serializer.fromJson<String>(json['severity']),
      screenId: serializer.fromJson<String>(json['screenId']),
      fieldId: serializer.fromJson<String?>(json['fieldId']),
      reason: serializer.fromJson<String>(json['reason']),
      suggestedText: serializer.fromJson<String>(json['suggestedText']),
      accepted: serializer.fromJson<bool>(json['accepted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      ruleVersion: serializer.fromJson<String?>(json['ruleVersion']),
      aiModelVersion: serializer.fromJson<String?>(json['aiModelVersion']),
      confidenceScore: serializer.fromJson<double?>(json['confidenceScore']),
      generationTimestamp:
          serializer.fromJson<int?>(json['generationTimestamp']),
      internalReasoning:
          serializer.fromJson<String?>(json['internalReasoning']),
      auditHash: serializer.fromJson<String?>(json['auditHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'category': serializer.toJson<String>(category),
      'severity': serializer.toJson<String>(severity),
      'screenId': serializer.toJson<String>(screenId),
      'fieldId': serializer.toJson<String?>(fieldId),
      'reason': serializer.toJson<String>(reason),
      'suggestedText': serializer.toJson<String>(suggestedText),
      'accepted': serializer.toJson<bool>(accepted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sourceType': serializer.toJson<String>(sourceType),
      'ruleVersion': serializer.toJson<String?>(ruleVersion),
      'aiModelVersion': serializer.toJson<String?>(aiModelVersion),
      'confidenceScore': serializer.toJson<double?>(confidenceScore),
      'generationTimestamp': serializer.toJson<int?>(generationTimestamp),
      'internalReasoning': serializer.toJson<String?>(internalReasoning),
      'auditHash': serializer.toJson<String?>(auditHash),
    };
  }

  SurveyRecommendation copyWith(
          {String? id,
          String? surveyId,
          String? category,
          String? severity,
          String? screenId,
          Value<String?> fieldId = const Value.absent(),
          String? reason,
          String? suggestedText,
          bool? accepted,
          DateTime? createdAt,
          String? sourceType,
          Value<String?> ruleVersion = const Value.absent(),
          Value<String?> aiModelVersion = const Value.absent(),
          Value<double?> confidenceScore = const Value.absent(),
          Value<int?> generationTimestamp = const Value.absent(),
          Value<String?> internalReasoning = const Value.absent(),
          Value<String?> auditHash = const Value.absent()}) =>
      SurveyRecommendation(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        category: category ?? this.category,
        severity: severity ?? this.severity,
        screenId: screenId ?? this.screenId,
        fieldId: fieldId.present ? fieldId.value : this.fieldId,
        reason: reason ?? this.reason,
        suggestedText: suggestedText ?? this.suggestedText,
        accepted: accepted ?? this.accepted,
        createdAt: createdAt ?? this.createdAt,
        sourceType: sourceType ?? this.sourceType,
        ruleVersion: ruleVersion.present ? ruleVersion.value : this.ruleVersion,
        aiModelVersion:
            aiModelVersion.present ? aiModelVersion.value : this.aiModelVersion,
        confidenceScore: confidenceScore.present
            ? confidenceScore.value
            : this.confidenceScore,
        generationTimestamp: generationTimestamp.present
            ? generationTimestamp.value
            : this.generationTimestamp,
        internalReasoning: internalReasoning.present
            ? internalReasoning.value
            : this.internalReasoning,
        auditHash: auditHash.present ? auditHash.value : this.auditHash,
      );
  SurveyRecommendation copyWithCompanion(SurveyRecommendationsCompanion data) {
    return SurveyRecommendation(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      category: data.category.present ? data.category.value : this.category,
      severity: data.severity.present ? data.severity.value : this.severity,
      screenId: data.screenId.present ? data.screenId.value : this.screenId,
      fieldId: data.fieldId.present ? data.fieldId.value : this.fieldId,
      reason: data.reason.present ? data.reason.value : this.reason,
      suggestedText: data.suggestedText.present
          ? data.suggestedText.value
          : this.suggestedText,
      accepted: data.accepted.present ? data.accepted.value : this.accepted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sourceType:
          data.sourceType.present ? data.sourceType.value : this.sourceType,
      ruleVersion:
          data.ruleVersion.present ? data.ruleVersion.value : this.ruleVersion,
      aiModelVersion: data.aiModelVersion.present
          ? data.aiModelVersion.value
          : this.aiModelVersion,
      confidenceScore: data.confidenceScore.present
          ? data.confidenceScore.value
          : this.confidenceScore,
      generationTimestamp: data.generationTimestamp.present
          ? data.generationTimestamp.value
          : this.generationTimestamp,
      internalReasoning: data.internalReasoning.present
          ? data.internalReasoning.value
          : this.internalReasoning,
      auditHash: data.auditHash.present ? data.auditHash.value : this.auditHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyRecommendation(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('category: $category, ')
          ..write('severity: $severity, ')
          ..write('screenId: $screenId, ')
          ..write('fieldId: $fieldId, ')
          ..write('reason: $reason, ')
          ..write('suggestedText: $suggestedText, ')
          ..write('accepted: $accepted, ')
          ..write('createdAt: $createdAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('aiModelVersion: $aiModelVersion, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('generationTimestamp: $generationTimestamp, ')
          ..write('internalReasoning: $internalReasoning, ')
          ..write('auditHash: $auditHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      surveyId,
      category,
      severity,
      screenId,
      fieldId,
      reason,
      suggestedText,
      accepted,
      createdAt,
      sourceType,
      ruleVersion,
      aiModelVersion,
      confidenceScore,
      generationTimestamp,
      internalReasoning,
      auditHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyRecommendation &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.category == this.category &&
          other.severity == this.severity &&
          other.screenId == this.screenId &&
          other.fieldId == this.fieldId &&
          other.reason == this.reason &&
          other.suggestedText == this.suggestedText &&
          other.accepted == this.accepted &&
          other.createdAt == this.createdAt &&
          other.sourceType == this.sourceType &&
          other.ruleVersion == this.ruleVersion &&
          other.aiModelVersion == this.aiModelVersion &&
          other.confidenceScore == this.confidenceScore &&
          other.generationTimestamp == this.generationTimestamp &&
          other.internalReasoning == this.internalReasoning &&
          other.auditHash == this.auditHash);
}

class SurveyRecommendationsCompanion
    extends UpdateCompanion<SurveyRecommendation> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<String> category;
  final Value<String> severity;
  final Value<String> screenId;
  final Value<String?> fieldId;
  final Value<String> reason;
  final Value<String> suggestedText;
  final Value<bool> accepted;
  final Value<DateTime> createdAt;
  final Value<String> sourceType;
  final Value<String?> ruleVersion;
  final Value<String?> aiModelVersion;
  final Value<double?> confidenceScore;
  final Value<int?> generationTimestamp;
  final Value<String?> internalReasoning;
  final Value<String?> auditHash;
  final Value<int> rowid;
  const SurveyRecommendationsCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.category = const Value.absent(),
    this.severity = const Value.absent(),
    this.screenId = const Value.absent(),
    this.fieldId = const Value.absent(),
    this.reason = const Value.absent(),
    this.suggestedText = const Value.absent(),
    this.accepted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.aiModelVersion = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.generationTimestamp = const Value.absent(),
    this.internalReasoning = const Value.absent(),
    this.auditHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveyRecommendationsCompanion.insert({
    required String id,
    required String surveyId,
    required String category,
    required String severity,
    required String screenId,
    this.fieldId = const Value.absent(),
    required String reason,
    required String suggestedText,
    this.accepted = const Value.absent(),
    required DateTime createdAt,
    this.sourceType = const Value.absent(),
    this.ruleVersion = const Value.absent(),
    this.aiModelVersion = const Value.absent(),
    this.confidenceScore = const Value.absent(),
    this.generationTimestamp = const Value.absent(),
    this.internalReasoning = const Value.absent(),
    this.auditHash = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        category = Value(category),
        severity = Value(severity),
        screenId = Value(screenId),
        reason = Value(reason),
        suggestedText = Value(suggestedText),
        createdAt = Value(createdAt);
  static Insertable<SurveyRecommendation> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<String>? category,
    Expression<String>? severity,
    Expression<String>? screenId,
    Expression<String>? fieldId,
    Expression<String>? reason,
    Expression<String>? suggestedText,
    Expression<bool>? accepted,
    Expression<DateTime>? createdAt,
    Expression<String>? sourceType,
    Expression<String>? ruleVersion,
    Expression<String>? aiModelVersion,
    Expression<double>? confidenceScore,
    Expression<int>? generationTimestamp,
    Expression<String>? internalReasoning,
    Expression<String>? auditHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (category != null) 'category': category,
      if (severity != null) 'severity': severity,
      if (screenId != null) 'screen_id': screenId,
      if (fieldId != null) 'field_id': fieldId,
      if (reason != null) 'reason': reason,
      if (suggestedText != null) 'suggested_text': suggestedText,
      if (accepted != null) 'accepted': accepted,
      if (createdAt != null) 'created_at': createdAt,
      if (sourceType != null) 'source_type': sourceType,
      if (ruleVersion != null) 'rule_version': ruleVersion,
      if (aiModelVersion != null) 'ai_model_version': aiModelVersion,
      if (confidenceScore != null) 'confidence_score': confidenceScore,
      if (generationTimestamp != null)
        'generation_timestamp': generationTimestamp,
      if (internalReasoning != null) 'internal_reasoning': internalReasoning,
      if (auditHash != null) 'audit_hash': auditHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveyRecommendationsCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<String>? category,
      Value<String>? severity,
      Value<String>? screenId,
      Value<String?>? fieldId,
      Value<String>? reason,
      Value<String>? suggestedText,
      Value<bool>? accepted,
      Value<DateTime>? createdAt,
      Value<String>? sourceType,
      Value<String?>? ruleVersion,
      Value<String?>? aiModelVersion,
      Value<double?>? confidenceScore,
      Value<int?>? generationTimestamp,
      Value<String?>? internalReasoning,
      Value<String?>? auditHash,
      Value<int>? rowid}) {
    return SurveyRecommendationsCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      screenId: screenId ?? this.screenId,
      fieldId: fieldId ?? this.fieldId,
      reason: reason ?? this.reason,
      suggestedText: suggestedText ?? this.suggestedText,
      accepted: accepted ?? this.accepted,
      createdAt: createdAt ?? this.createdAt,
      sourceType: sourceType ?? this.sourceType,
      ruleVersion: ruleVersion ?? this.ruleVersion,
      aiModelVersion: aiModelVersion ?? this.aiModelVersion,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      generationTimestamp: generationTimestamp ?? this.generationTimestamp,
      internalReasoning: internalReasoning ?? this.internalReasoning,
      auditHash: auditHash ?? this.auditHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (screenId.present) {
      map['screen_id'] = Variable<String>(screenId.value);
    }
    if (fieldId.present) {
      map['field_id'] = Variable<String>(fieldId.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (suggestedText.present) {
      map['suggested_text'] = Variable<String>(suggestedText.value);
    }
    if (accepted.present) {
      map['accepted'] = Variable<bool>(accepted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (ruleVersion.present) {
      map['rule_version'] = Variable<String>(ruleVersion.value);
    }
    if (aiModelVersion.present) {
      map['ai_model_version'] = Variable<String>(aiModelVersion.value);
    }
    if (confidenceScore.present) {
      map['confidence_score'] = Variable<double>(confidenceScore.value);
    }
    if (generationTimestamp.present) {
      map['generation_timestamp'] = Variable<int>(generationTimestamp.value);
    }
    if (internalReasoning.present) {
      map['internal_reasoning'] = Variable<String>(internalReasoning.value);
    }
    if (auditHash.present) {
      map['audit_hash'] = Variable<String>(auditHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyRecommendationsCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('category: $category, ')
          ..write('severity: $severity, ')
          ..write('screenId: $screenId, ')
          ..write('fieldId: $fieldId, ')
          ..write('reason: $reason, ')
          ..write('suggestedText: $suggestedText, ')
          ..write('accepted: $accepted, ')
          ..write('createdAt: $createdAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('ruleVersion: $ruleVersion, ')
          ..write('aiModelVersion: $aiModelVersion, ')
          ..write('confidenceScore: $confidenceScore, ')
          ..write('generationTimestamp: $generationTimestamp, ')
          ..write('internalReasoning: $internalReasoning, ')
          ..write('auditHash: $auditHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SurveyQualityScoresTable extends SurveyQualityScores
    with TableInfo<$SurveyQualityScoresTable, SurveyQualityScore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SurveyQualityScoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _surveyIdMeta =
      const VerificationMeta('surveyId');
  @override
  late final GeneratedColumn<String> surveyId = GeneratedColumn<String>(
      'survey_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _complianceScoreMeta =
      const VerificationMeta('complianceScore');
  @override
  late final GeneratedColumn<double> complianceScore = GeneratedColumn<double>(
      'compliance_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _narrativeScoreMeta =
      const VerificationMeta('narrativeScore');
  @override
  late final GeneratedColumn<double> narrativeScore = GeneratedColumn<double>(
      'narrative_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _riskScoreMeta =
      const VerificationMeta('riskScore');
  @override
  late final GeneratedColumn<double> riskScore = GeneratedColumn<double>(
      'risk_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _overallScoreMeta =
      const VerificationMeta('overallScore');
  @override
  late final GeneratedColumn<double> overallScore = GeneratedColumn<double>(
      'overall_score', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _generatedAtMeta =
      const VerificationMeta('generatedAt');
  @override
  late final GeneratedColumn<DateTime> generatedAt = GeneratedColumn<DateTime>(
      'generated_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _engineVersionMeta =
      const VerificationMeta('engineVersion');
  @override
  late final GeneratedColumn<String> engineVersion = GeneratedColumn<String>(
      'engine_version', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        surveyId,
        complianceScore,
        narrativeScore,
        riskScore,
        overallScore,
        generatedAt,
        engineVersion
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'survey_quality_scores';
  @override
  VerificationContext validateIntegrity(Insertable<SurveyQualityScore> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('survey_id')) {
      context.handle(_surveyIdMeta,
          surveyId.isAcceptableOrUnknown(data['survey_id']!, _surveyIdMeta));
    } else if (isInserting) {
      context.missing(_surveyIdMeta);
    }
    if (data.containsKey('compliance_score')) {
      context.handle(
          _complianceScoreMeta,
          complianceScore.isAcceptableOrUnknown(
              data['compliance_score']!, _complianceScoreMeta));
    } else if (isInserting) {
      context.missing(_complianceScoreMeta);
    }
    if (data.containsKey('narrative_score')) {
      context.handle(
          _narrativeScoreMeta,
          narrativeScore.isAcceptableOrUnknown(
              data['narrative_score']!, _narrativeScoreMeta));
    } else if (isInserting) {
      context.missing(_narrativeScoreMeta);
    }
    if (data.containsKey('risk_score')) {
      context.handle(_riskScoreMeta,
          riskScore.isAcceptableOrUnknown(data['risk_score']!, _riskScoreMeta));
    } else if (isInserting) {
      context.missing(_riskScoreMeta);
    }
    if (data.containsKey('overall_score')) {
      context.handle(
          _overallScoreMeta,
          overallScore.isAcceptableOrUnknown(
              data['overall_score']!, _overallScoreMeta));
    } else if (isInserting) {
      context.missing(_overallScoreMeta);
    }
    if (data.containsKey('generated_at')) {
      context.handle(
          _generatedAtMeta,
          generatedAt.isAcceptableOrUnknown(
              data['generated_at']!, _generatedAtMeta));
    } else if (isInserting) {
      context.missing(_generatedAtMeta);
    }
    if (data.containsKey('engine_version')) {
      context.handle(
          _engineVersionMeta,
          engineVersion.isAcceptableOrUnknown(
              data['engine_version']!, _engineVersionMeta));
    } else if (isInserting) {
      context.missing(_engineVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurveyQualityScore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurveyQualityScore(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      surveyId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}survey_id'])!,
      complianceScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}compliance_score'])!,
      narrativeScore: attachedDatabase.typeMapping.read(
          DriftSqlType.double, data['${effectivePrefix}narrative_score'])!,
      riskScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}risk_score'])!,
      overallScore: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}overall_score'])!,
      generatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}generated_at'])!,
      engineVersion: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}engine_version'])!,
    );
  }

  @override
  $SurveyQualityScoresTable createAlias(String alias) {
    return $SurveyQualityScoresTable(attachedDatabase, alias);
  }
}

class SurveyQualityScore extends DataClass
    implements Insertable<SurveyQualityScore> {
  final String id;
  final String surveyId;
  final double complianceScore;
  final double narrativeScore;
  final double riskScore;
  final double overallScore;
  final DateTime generatedAt;
  final String engineVersion;
  const SurveyQualityScore(
      {required this.id,
      required this.surveyId,
      required this.complianceScore,
      required this.narrativeScore,
      required this.riskScore,
      required this.overallScore,
      required this.generatedAt,
      required this.engineVersion});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['survey_id'] = Variable<String>(surveyId);
    map['compliance_score'] = Variable<double>(complianceScore);
    map['narrative_score'] = Variable<double>(narrativeScore);
    map['risk_score'] = Variable<double>(riskScore);
    map['overall_score'] = Variable<double>(overallScore);
    map['generated_at'] = Variable<DateTime>(generatedAt);
    map['engine_version'] = Variable<String>(engineVersion);
    return map;
  }

  SurveyQualityScoresCompanion toCompanion(bool nullToAbsent) {
    return SurveyQualityScoresCompanion(
      id: Value(id),
      surveyId: Value(surveyId),
      complianceScore: Value(complianceScore),
      narrativeScore: Value(narrativeScore),
      riskScore: Value(riskScore),
      overallScore: Value(overallScore),
      generatedAt: Value(generatedAt),
      engineVersion: Value(engineVersion),
    );
  }

  factory SurveyQualityScore.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurveyQualityScore(
      id: serializer.fromJson<String>(json['id']),
      surveyId: serializer.fromJson<String>(json['surveyId']),
      complianceScore: serializer.fromJson<double>(json['complianceScore']),
      narrativeScore: serializer.fromJson<double>(json['narrativeScore']),
      riskScore: serializer.fromJson<double>(json['riskScore']),
      overallScore: serializer.fromJson<double>(json['overallScore']),
      generatedAt: serializer.fromJson<DateTime>(json['generatedAt']),
      engineVersion: serializer.fromJson<String>(json['engineVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'surveyId': serializer.toJson<String>(surveyId),
      'complianceScore': serializer.toJson<double>(complianceScore),
      'narrativeScore': serializer.toJson<double>(narrativeScore),
      'riskScore': serializer.toJson<double>(riskScore),
      'overallScore': serializer.toJson<double>(overallScore),
      'generatedAt': serializer.toJson<DateTime>(generatedAt),
      'engineVersion': serializer.toJson<String>(engineVersion),
    };
  }

  SurveyQualityScore copyWith(
          {String? id,
          String? surveyId,
          double? complianceScore,
          double? narrativeScore,
          double? riskScore,
          double? overallScore,
          DateTime? generatedAt,
          String? engineVersion}) =>
      SurveyQualityScore(
        id: id ?? this.id,
        surveyId: surveyId ?? this.surveyId,
        complianceScore: complianceScore ?? this.complianceScore,
        narrativeScore: narrativeScore ?? this.narrativeScore,
        riskScore: riskScore ?? this.riskScore,
        overallScore: overallScore ?? this.overallScore,
        generatedAt: generatedAt ?? this.generatedAt,
        engineVersion: engineVersion ?? this.engineVersion,
      );
  SurveyQualityScore copyWithCompanion(SurveyQualityScoresCompanion data) {
    return SurveyQualityScore(
      id: data.id.present ? data.id.value : this.id,
      surveyId: data.surveyId.present ? data.surveyId.value : this.surveyId,
      complianceScore: data.complianceScore.present
          ? data.complianceScore.value
          : this.complianceScore,
      narrativeScore: data.narrativeScore.present
          ? data.narrativeScore.value
          : this.narrativeScore,
      riskScore: data.riskScore.present ? data.riskScore.value : this.riskScore,
      overallScore: data.overallScore.present
          ? data.overallScore.value
          : this.overallScore,
      generatedAt:
          data.generatedAt.present ? data.generatedAt.value : this.generatedAt,
      engineVersion: data.engineVersion.present
          ? data.engineVersion.value
          : this.engineVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurveyQualityScore(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('complianceScore: $complianceScore, ')
          ..write('narrativeScore: $narrativeScore, ')
          ..write('riskScore: $riskScore, ')
          ..write('overallScore: $overallScore, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('engineVersion: $engineVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, surveyId, complianceScore, narrativeScore,
      riskScore, overallScore, generatedAt, engineVersion);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurveyQualityScore &&
          other.id == this.id &&
          other.surveyId == this.surveyId &&
          other.complianceScore == this.complianceScore &&
          other.narrativeScore == this.narrativeScore &&
          other.riskScore == this.riskScore &&
          other.overallScore == this.overallScore &&
          other.generatedAt == this.generatedAt &&
          other.engineVersion == this.engineVersion);
}

class SurveyQualityScoresCompanion extends UpdateCompanion<SurveyQualityScore> {
  final Value<String> id;
  final Value<String> surveyId;
  final Value<double> complianceScore;
  final Value<double> narrativeScore;
  final Value<double> riskScore;
  final Value<double> overallScore;
  final Value<DateTime> generatedAt;
  final Value<String> engineVersion;
  final Value<int> rowid;
  const SurveyQualityScoresCompanion({
    this.id = const Value.absent(),
    this.surveyId = const Value.absent(),
    this.complianceScore = const Value.absent(),
    this.narrativeScore = const Value.absent(),
    this.riskScore = const Value.absent(),
    this.overallScore = const Value.absent(),
    this.generatedAt = const Value.absent(),
    this.engineVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurveyQualityScoresCompanion.insert({
    required String id,
    required String surveyId,
    required double complianceScore,
    required double narrativeScore,
    required double riskScore,
    required double overallScore,
    required DateTime generatedAt,
    required String engineVersion,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        surveyId = Value(surveyId),
        complianceScore = Value(complianceScore),
        narrativeScore = Value(narrativeScore),
        riskScore = Value(riskScore),
        overallScore = Value(overallScore),
        generatedAt = Value(generatedAt),
        engineVersion = Value(engineVersion);
  static Insertable<SurveyQualityScore> custom({
    Expression<String>? id,
    Expression<String>? surveyId,
    Expression<double>? complianceScore,
    Expression<double>? narrativeScore,
    Expression<double>? riskScore,
    Expression<double>? overallScore,
    Expression<DateTime>? generatedAt,
    Expression<String>? engineVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (surveyId != null) 'survey_id': surveyId,
      if (complianceScore != null) 'compliance_score': complianceScore,
      if (narrativeScore != null) 'narrative_score': narrativeScore,
      if (riskScore != null) 'risk_score': riskScore,
      if (overallScore != null) 'overall_score': overallScore,
      if (generatedAt != null) 'generated_at': generatedAt,
      if (engineVersion != null) 'engine_version': engineVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurveyQualityScoresCompanion copyWith(
      {Value<String>? id,
      Value<String>? surveyId,
      Value<double>? complianceScore,
      Value<double>? narrativeScore,
      Value<double>? riskScore,
      Value<double>? overallScore,
      Value<DateTime>? generatedAt,
      Value<String>? engineVersion,
      Value<int>? rowid}) {
    return SurveyQualityScoresCompanion(
      id: id ?? this.id,
      surveyId: surveyId ?? this.surveyId,
      complianceScore: complianceScore ?? this.complianceScore,
      narrativeScore: narrativeScore ?? this.narrativeScore,
      riskScore: riskScore ?? this.riskScore,
      overallScore: overallScore ?? this.overallScore,
      generatedAt: generatedAt ?? this.generatedAt,
      engineVersion: engineVersion ?? this.engineVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (surveyId.present) {
      map['survey_id'] = Variable<String>(surveyId.value);
    }
    if (complianceScore.present) {
      map['compliance_score'] = Variable<double>(complianceScore.value);
    }
    if (narrativeScore.present) {
      map['narrative_score'] = Variable<double>(narrativeScore.value);
    }
    if (riskScore.present) {
      map['risk_score'] = Variable<double>(riskScore.value);
    }
    if (overallScore.present) {
      map['overall_score'] = Variable<double>(overallScore.value);
    }
    if (generatedAt.present) {
      map['generated_at'] = Variable<DateTime>(generatedAt.value);
    }
    if (engineVersion.present) {
      map['engine_version'] = Variable<String>(engineVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurveyQualityScoresCompanion(')
          ..write('id: $id, ')
          ..write('surveyId: $surveyId, ')
          ..write('complianceScore: $complianceScore, ')
          ..write('narrativeScore: $narrativeScore, ')
          ..write('riskScore: $riskScore, ')
          ..write('overallScore: $overallScore, ')
          ..write('generatedAt: $generatedAt, ')
          ..write('engineVersion: $engineVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SurveysTable surveys = $SurveysTable(this);
  late final $SurveySectionsTable surveySections = $SurveySectionsTable(this);
  late final $SurveyAnswersTable surveyAnswers = $SurveyAnswersTable(this);
  late final $InspectionV2ScreensTable inspectionV2Screens =
      $InspectionV2ScreensTable(this);
  late final $InspectionV2AnswersTable inspectionV2Answers =
      $InspectionV2AnswersTable(this);
  late final $SyncQueueTable syncQueue = $SyncQueueTable(this);
  late final $MediaItemsTable mediaItems = $MediaItemsTable(this);
  late final $PhotoAnnotationsTable photoAnnotations =
      $PhotoAnnotationsTable(this);
  late final $SignaturesTable signatures = $SignaturesTable(this);
  late final $GeneratedReportsTable generatedReports =
      $GeneratedReportsTable(this);
  late final $SurveyRecommendationsTable surveyRecommendations =
      $SurveyRecommendationsTable(this);
  late final $SurveyQualityScoresTable surveyQualityScores =
      $SurveyQualityScoresTable(this);
  late final SyncQueueDao syncQueueDao = SyncQueueDao(this as AppDatabase);
  late final MediaDao mediaDao = MediaDao(this as AppDatabase);
  late final SignatureDao signatureDao = SignatureDao(this as AppDatabase);
  late final GeneratedReportsDao generatedReportsDao =
      GeneratedReportsDao(this as AppDatabase);
  late final SurveyRecommendationsDao surveyRecommendationsDao =
      SurveyRecommendationsDao(this as AppDatabase);
  late final SurveyQualityScoresDao surveyQualityScoresDao =
      SurveyQualityScoresDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        surveys,
        surveySections,
        surveyAnswers,
        inspectionV2Screens,
        inspectionV2Answers,
        syncQueue,
        mediaItems,
        photoAnnotations,
        signatures,
        generatedReports,
        surveyRecommendations,
        surveyQualityScores
      ];
}

typedef $$SurveysTableCreateCompanionBuilder = SurveysCompanion Function({
  required String id,
  required String title,
  required String type,
  required String status,
  Value<String?> jobRef,
  Value<String?> address,
  Value<String?> clientName,
  Value<double> progress,
  Value<int> photoCount,
  Value<int> noteCount,
  Value<int> totalSections,
  Value<int> completedSections,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<String?> parentSurveyId,
  Value<int> reinspectionNumber,
  Value<String?> aiSummary,
  Value<String?> riskSummary,
  Value<String?> repairRecommendations,
  Value<int> rowid,
});
typedef $$SurveysTableUpdateCompanionBuilder = SurveysCompanion Function({
  Value<String> id,
  Value<String> title,
  Value<String> type,
  Value<String> status,
  Value<String?> jobRef,
  Value<String?> address,
  Value<String?> clientName,
  Value<double> progress,
  Value<int> photoCount,
  Value<int> noteCount,
  Value<int> totalSections,
  Value<int> completedSections,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<DateTime?> startedAt,
  Value<DateTime?> completedAt,
  Value<String?> parentSurveyId,
  Value<int> reinspectionNumber,
  Value<String?> aiSummary,
  Value<String?> riskSummary,
  Value<String?> repairRecommendations,
  Value<int> rowid,
});

class $$SurveysTableFilterComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jobRef => $composableBuilder(
      column: $table.jobRef, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get photoCount => $composableBuilder(
      column: $table.photoCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get noteCount => $composableBuilder(
      column: $table.noteCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalSections => $composableBuilder(
      column: $table.totalSections, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedSections => $composableBuilder(
      column: $table.completedSections,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentSurveyId => $composableBuilder(
      column: $table.parentSurveyId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get reinspectionNumber => $composableBuilder(
      column: $table.reinspectionNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiSummary => $composableBuilder(
      column: $table.aiSummary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get riskSummary => $composableBuilder(
      column: $table.riskSummary, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get repairRecommendations => $composableBuilder(
      column: $table.repairRecommendations,
      builder: (column) => ColumnFilters(column));
}

class $$SurveysTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get type => $composableBuilder(
      column: $table.type, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jobRef => $composableBuilder(
      column: $table.jobRef, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get address => $composableBuilder(
      column: $table.address, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get progress => $composableBuilder(
      column: $table.progress, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get photoCount => $composableBuilder(
      column: $table.photoCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get noteCount => $composableBuilder(
      column: $table.noteCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalSections => $composableBuilder(
      column: $table.totalSections,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedSections => $composableBuilder(
      column: $table.completedSections,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentSurveyId => $composableBuilder(
      column: $table.parentSurveyId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get reinspectionNumber => $composableBuilder(
      column: $table.reinspectionNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiSummary => $composableBuilder(
      column: $table.aiSummary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get riskSummary => $composableBuilder(
      column: $table.riskSummary, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repairRecommendations => $composableBuilder(
      column: $table.repairRecommendations,
      builder: (column) => ColumnOrderings(column));
}

class $$SurveysTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveysTable> {
  $$SurveysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get jobRef =>
      $composableBuilder(column: $table.jobRef, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get clientName => $composableBuilder(
      column: $table.clientName, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get photoCount => $composableBuilder(
      column: $table.photoCount, builder: (column) => column);

  GeneratedColumn<int> get noteCount =>
      $composableBuilder(column: $table.noteCount, builder: (column) => column);

  GeneratedColumn<int> get totalSections => $composableBuilder(
      column: $table.totalSections, builder: (column) => column);

  GeneratedColumn<int> get completedSections => $composableBuilder(
      column: $table.completedSections, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<String> get parentSurveyId => $composableBuilder(
      column: $table.parentSurveyId, builder: (column) => column);

  GeneratedColumn<int> get reinspectionNumber => $composableBuilder(
      column: $table.reinspectionNumber, builder: (column) => column);

  GeneratedColumn<String> get aiSummary =>
      $composableBuilder(column: $table.aiSummary, builder: (column) => column);

  GeneratedColumn<String> get riskSummary => $composableBuilder(
      column: $table.riskSummary, builder: (column) => column);

  GeneratedColumn<String> get repairRecommendations => $composableBuilder(
      column: $table.repairRecommendations, builder: (column) => column);
}

class $$SurveysTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveysTable,
    Survey,
    $$SurveysTableFilterComposer,
    $$SurveysTableOrderingComposer,
    $$SurveysTableAnnotationComposer,
    $$SurveysTableCreateCompanionBuilder,
    $$SurveysTableUpdateCompanionBuilder,
    (Survey, BaseReferences<_$AppDatabase, $SurveysTable, Survey>),
    Survey,
    PrefetchHooks Function()> {
  $$SurveysTableTableManager(_$AppDatabase db, $SurveysTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String> type = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> jobRef = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> clientName = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int> photoCount = const Value.absent(),
            Value<int> noteCount = const Value.absent(),
            Value<int> totalSections = const Value.absent(),
            Value<int> completedSections = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> parentSurveyId = const Value.absent(),
            Value<int> reinspectionNumber = const Value.absent(),
            Value<String?> aiSummary = const Value.absent(),
            Value<String?> riskSummary = const Value.absent(),
            Value<String?> repairRecommendations = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveysCompanion(
            id: id,
            title: title,
            type: type,
            status: status,
            jobRef: jobRef,
            address: address,
            clientName: clientName,
            progress: progress,
            photoCount: photoCount,
            noteCount: noteCount,
            totalSections: totalSections,
            completedSections: completedSections,
            createdAt: createdAt,
            updatedAt: updatedAt,
            startedAt: startedAt,
            completedAt: completedAt,
            parentSurveyId: parentSurveyId,
            reinspectionNumber: reinspectionNumber,
            aiSummary: aiSummary,
            riskSummary: riskSummary,
            repairRecommendations: repairRecommendations,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String title,
            required String type,
            required String status,
            Value<String?> jobRef = const Value.absent(),
            Value<String?> address = const Value.absent(),
            Value<String?> clientName = const Value.absent(),
            Value<double> progress = const Value.absent(),
            Value<int> photoCount = const Value.absent(),
            Value<int> noteCount = const Value.absent(),
            Value<int> totalSections = const Value.absent(),
            Value<int> completedSections = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<DateTime?> startedAt = const Value.absent(),
            Value<DateTime?> completedAt = const Value.absent(),
            Value<String?> parentSurveyId = const Value.absent(),
            Value<int> reinspectionNumber = const Value.absent(),
            Value<String?> aiSummary = const Value.absent(),
            Value<String?> riskSummary = const Value.absent(),
            Value<String?> repairRecommendations = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveysCompanion.insert(
            id: id,
            title: title,
            type: type,
            status: status,
            jobRef: jobRef,
            address: address,
            clientName: clientName,
            progress: progress,
            photoCount: photoCount,
            noteCount: noteCount,
            totalSections: totalSections,
            completedSections: completedSections,
            createdAt: createdAt,
            updatedAt: updatedAt,
            startedAt: startedAt,
            completedAt: completedAt,
            parentSurveyId: parentSurveyId,
            reinspectionNumber: reinspectionNumber,
            aiSummary: aiSummary,
            riskSummary: riskSummary,
            repairRecommendations: repairRecommendations,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurveysTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurveysTable,
    Survey,
    $$SurveysTableFilterComposer,
    $$SurveysTableOrderingComposer,
    $$SurveysTableAnnotationComposer,
    $$SurveysTableCreateCompanionBuilder,
    $$SurveysTableUpdateCompanionBuilder,
    (Survey, BaseReferences<_$AppDatabase, $SurveysTable, Survey>),
    Survey,
    PrefetchHooks Function()>;
typedef $$SurveySectionsTableCreateCompanionBuilder = SurveySectionsCompanion
    Function({
  required String id,
  required String surveyId,
  required String sectionType,
  required String title,
  required int sectionOrder,
  Value<bool> isCompleted,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$SurveySectionsTableUpdateCompanionBuilder = SurveySectionsCompanion
    Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String> sectionType,
  Value<String> title,
  Value<int> sectionOrder,
  Value<bool> isCompleted,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$SurveySectionsTableFilterComposer
    extends Composer<_$AppDatabase, $SurveySectionsTable> {
  $$SurveySectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionType => $composableBuilder(
      column: $table.sectionType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sectionOrder => $composableBuilder(
      column: $table.sectionOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SurveySectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveySectionsTable> {
  $$SurveySectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionType => $composableBuilder(
      column: $table.sectionType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sectionOrder => $composableBuilder(
      column: $table.sectionOrder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SurveySectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveySectionsTable> {
  $$SurveySectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get sectionType => $composableBuilder(
      column: $table.sectionType, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get sectionOrder => $composableBuilder(
      column: $table.sectionOrder, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SurveySectionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveySectionsTable,
    SurveySection,
    $$SurveySectionsTableFilterComposer,
    $$SurveySectionsTableOrderingComposer,
    $$SurveySectionsTableAnnotationComposer,
    $$SurveySectionsTableCreateCompanionBuilder,
    $$SurveySectionsTableUpdateCompanionBuilder,
    (
      SurveySection,
      BaseReferences<_$AppDatabase, $SurveySectionsTable, SurveySection>
    ),
    SurveySection,
    PrefetchHooks Function()> {
  $$SurveySectionsTableTableManager(
      _$AppDatabase db, $SurveySectionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveySectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveySectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveySectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String> sectionType = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<int> sectionOrder = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveySectionsCompanion(
            id: id,
            surveyId: surveyId,
            sectionType: sectionType,
            title: title,
            sectionOrder: sectionOrder,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            required String sectionType,
            required String title,
            required int sectionOrder,
            Value<bool> isCompleted = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveySectionsCompanion.insert(
            id: id,
            surveyId: surveyId,
            sectionType: sectionType,
            title: title,
            sectionOrder: sectionOrder,
            isCompleted: isCompleted,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurveySectionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurveySectionsTable,
    SurveySection,
    $$SurveySectionsTableFilterComposer,
    $$SurveySectionsTableOrderingComposer,
    $$SurveySectionsTableAnnotationComposer,
    $$SurveySectionsTableCreateCompanionBuilder,
    $$SurveySectionsTableUpdateCompanionBuilder,
    (
      SurveySection,
      BaseReferences<_$AppDatabase, $SurveySectionsTable, SurveySection>
    ),
    SurveySection,
    PrefetchHooks Function()>;
typedef $$SurveyAnswersTableCreateCompanionBuilder = SurveyAnswersCompanion
    Function({
  required String id,
  required String surveyId,
  required String sectionId,
  required String fieldKey,
  Value<String?> value,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$SurveyAnswersTableUpdateCompanionBuilder = SurveyAnswersCompanion
    Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String> sectionId,
  Value<String> fieldKey,
  Value<String?> value,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$SurveyAnswersTableFilterComposer
    extends Composer<_$AppDatabase, $SurveyAnswersTable> {
  $$SurveyAnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldKey => $composableBuilder(
      column: $table.fieldKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SurveyAnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveyAnswersTable> {
  $$SurveyAnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldKey => $composableBuilder(
      column: $table.fieldKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SurveyAnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveyAnswersTable> {
  $$SurveyAnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SurveyAnswersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveyAnswersTable,
    SurveyAnswer,
    $$SurveyAnswersTableFilterComposer,
    $$SurveyAnswersTableOrderingComposer,
    $$SurveyAnswersTableAnnotationComposer,
    $$SurveyAnswersTableCreateCompanionBuilder,
    $$SurveyAnswersTableUpdateCompanionBuilder,
    (
      SurveyAnswer,
      BaseReferences<_$AppDatabase, $SurveyAnswersTable, SurveyAnswer>
    ),
    SurveyAnswer,
    PrefetchHooks Function()> {
  $$SurveyAnswersTableTableManager(_$AppDatabase db, $SurveyAnswersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyAnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyAnswersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyAnswersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String> sectionId = const Value.absent(),
            Value<String> fieldKey = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyAnswersCompanion(
            id: id,
            surveyId: surveyId,
            sectionId: sectionId,
            fieldKey: fieldKey,
            value: value,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            required String sectionId,
            required String fieldKey,
            Value<String?> value = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyAnswersCompanion.insert(
            id: id,
            surveyId: surveyId,
            sectionId: sectionId,
            fieldKey: fieldKey,
            value: value,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurveyAnswersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurveyAnswersTable,
    SurveyAnswer,
    $$SurveyAnswersTableFilterComposer,
    $$SurveyAnswersTableOrderingComposer,
    $$SurveyAnswersTableAnnotationComposer,
    $$SurveyAnswersTableCreateCompanionBuilder,
    $$SurveyAnswersTableUpdateCompanionBuilder,
    (
      SurveyAnswer,
      BaseReferences<_$AppDatabase, $SurveyAnswersTable, SurveyAnswer>
    ),
    SurveyAnswer,
    PrefetchHooks Function()>;
typedef $$InspectionV2ScreensTableCreateCompanionBuilder
    = InspectionV2ScreensCompanion Function({
  required String id,
  required String surveyId,
  required String sectionKey,
  required String screenId,
  required String title,
  Value<String?> groupKey,
  Value<String> nodeType,
  Value<String?> parentId,
  required int displayOrder,
  Value<bool> isCompleted,
  Value<String?> phraseOutput,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$InspectionV2ScreensTableUpdateCompanionBuilder
    = InspectionV2ScreensCompanion Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String> sectionKey,
  Value<String> screenId,
  Value<String> title,
  Value<String?> groupKey,
  Value<String> nodeType,
  Value<String?> parentId,
  Value<int> displayOrder,
  Value<bool> isCompleted,
  Value<String?> phraseOutput,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$InspectionV2ScreensTableFilterComposer
    extends Composer<_$AppDatabase, $InspectionV2ScreensTable> {
  $$InspectionV2ScreensTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionKey => $composableBuilder(
      column: $table.sectionKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get screenId => $composableBuilder(
      column: $table.screenId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get groupKey => $composableBuilder(
      column: $table.groupKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nodeType => $composableBuilder(
      column: $table.nodeType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get phraseOutput => $composableBuilder(
      column: $table.phraseOutput, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$InspectionV2ScreensTableOrderingComposer
    extends Composer<_$AppDatabase, $InspectionV2ScreensTable> {
  $$InspectionV2ScreensTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionKey => $composableBuilder(
      column: $table.sectionKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get screenId => $composableBuilder(
      column: $table.screenId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get groupKey => $composableBuilder(
      column: $table.groupKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nodeType => $composableBuilder(
      column: $table.nodeType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get parentId => $composableBuilder(
      column: $table.parentId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phraseOutput => $composableBuilder(
      column: $table.phraseOutput,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$InspectionV2ScreensTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspectionV2ScreensTable> {
  $$InspectionV2ScreensTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get sectionKey => $composableBuilder(
      column: $table.sectionKey, builder: (column) => column);

  GeneratedColumn<String> get screenId =>
      $composableBuilder(column: $table.screenId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<String> get nodeType =>
      $composableBuilder(column: $table.nodeType, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<int> get displayOrder => $composableBuilder(
      column: $table.displayOrder, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
      column: $table.isCompleted, builder: (column) => column);

  GeneratedColumn<String> get phraseOutput => $composableBuilder(
      column: $table.phraseOutput, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InspectionV2ScreensTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InspectionV2ScreensTable,
    InspectionV2Screen,
    $$InspectionV2ScreensTableFilterComposer,
    $$InspectionV2ScreensTableOrderingComposer,
    $$InspectionV2ScreensTableAnnotationComposer,
    $$InspectionV2ScreensTableCreateCompanionBuilder,
    $$InspectionV2ScreensTableUpdateCompanionBuilder,
    (
      InspectionV2Screen,
      BaseReferences<_$AppDatabase, $InspectionV2ScreensTable,
          InspectionV2Screen>
    ),
    InspectionV2Screen,
    PrefetchHooks Function()> {
  $$InspectionV2ScreensTableTableManager(
      _$AppDatabase db, $InspectionV2ScreensTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspectionV2ScreensTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InspectionV2ScreensTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InspectionV2ScreensTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String> sectionKey = const Value.absent(),
            Value<String> screenId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> groupKey = const Value.absent(),
            Value<String> nodeType = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            Value<int> displayOrder = const Value.absent(),
            Value<bool> isCompleted = const Value.absent(),
            Value<String?> phraseOutput = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InspectionV2ScreensCompanion(
            id: id,
            surveyId: surveyId,
            sectionKey: sectionKey,
            screenId: screenId,
            title: title,
            groupKey: groupKey,
            nodeType: nodeType,
            parentId: parentId,
            displayOrder: displayOrder,
            isCompleted: isCompleted,
            phraseOutput: phraseOutput,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            required String sectionKey,
            required String screenId,
            required String title,
            Value<String?> groupKey = const Value.absent(),
            Value<String> nodeType = const Value.absent(),
            Value<String?> parentId = const Value.absent(),
            required int displayOrder,
            Value<bool> isCompleted = const Value.absent(),
            Value<String?> phraseOutput = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InspectionV2ScreensCompanion.insert(
            id: id,
            surveyId: surveyId,
            sectionKey: sectionKey,
            screenId: screenId,
            title: title,
            groupKey: groupKey,
            nodeType: nodeType,
            parentId: parentId,
            displayOrder: displayOrder,
            isCompleted: isCompleted,
            phraseOutput: phraseOutput,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InspectionV2ScreensTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InspectionV2ScreensTable,
    InspectionV2Screen,
    $$InspectionV2ScreensTableFilterComposer,
    $$InspectionV2ScreensTableOrderingComposer,
    $$InspectionV2ScreensTableAnnotationComposer,
    $$InspectionV2ScreensTableCreateCompanionBuilder,
    $$InspectionV2ScreensTableUpdateCompanionBuilder,
    (
      InspectionV2Screen,
      BaseReferences<_$AppDatabase, $InspectionV2ScreensTable,
          InspectionV2Screen>
    ),
    InspectionV2Screen,
    PrefetchHooks Function()>;
typedef $$InspectionV2AnswersTableCreateCompanionBuilder
    = InspectionV2AnswersCompanion Function({
  required String id,
  required String surveyId,
  required String screenId,
  required String fieldKey,
  Value<String?> value,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$InspectionV2AnswersTableUpdateCompanionBuilder
    = InspectionV2AnswersCompanion Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String> screenId,
  Value<String> fieldKey,
  Value<String?> value,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$InspectionV2AnswersTableFilterComposer
    extends Composer<_$AppDatabase, $InspectionV2AnswersTable> {
  $$InspectionV2AnswersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get screenId => $composableBuilder(
      column: $table.screenId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldKey => $composableBuilder(
      column: $table.fieldKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$InspectionV2AnswersTableOrderingComposer
    extends Composer<_$AppDatabase, $InspectionV2AnswersTable> {
  $$InspectionV2AnswersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get screenId => $composableBuilder(
      column: $table.screenId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldKey => $composableBuilder(
      column: $table.fieldKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value => $composableBuilder(
      column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$InspectionV2AnswersTableAnnotationComposer
    extends Composer<_$AppDatabase, $InspectionV2AnswersTable> {
  $$InspectionV2AnswersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get screenId =>
      $composableBuilder(column: $table.screenId, builder: (column) => column);

  GeneratedColumn<String> get fieldKey =>
      $composableBuilder(column: $table.fieldKey, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$InspectionV2AnswersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $InspectionV2AnswersTable,
    InspectionV2Answer,
    $$InspectionV2AnswersTableFilterComposer,
    $$InspectionV2AnswersTableOrderingComposer,
    $$InspectionV2AnswersTableAnnotationComposer,
    $$InspectionV2AnswersTableCreateCompanionBuilder,
    $$InspectionV2AnswersTableUpdateCompanionBuilder,
    (
      InspectionV2Answer,
      BaseReferences<_$AppDatabase, $InspectionV2AnswersTable,
          InspectionV2Answer>
    ),
    InspectionV2Answer,
    PrefetchHooks Function()> {
  $$InspectionV2AnswersTableTableManager(
      _$AppDatabase db, $InspectionV2AnswersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InspectionV2AnswersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InspectionV2AnswersTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InspectionV2AnswersTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String> screenId = const Value.absent(),
            Value<String> fieldKey = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InspectionV2AnswersCompanion(
            id: id,
            surveyId: surveyId,
            screenId: screenId,
            fieldKey: fieldKey,
            value: value,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            required String screenId,
            required String fieldKey,
            Value<String?> value = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              InspectionV2AnswersCompanion.insert(
            id: id,
            surveyId: surveyId,
            screenId: screenId,
            fieldKey: fieldKey,
            value: value,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$InspectionV2AnswersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $InspectionV2AnswersTable,
    InspectionV2Answer,
    $$InspectionV2AnswersTableFilterComposer,
    $$InspectionV2AnswersTableOrderingComposer,
    $$InspectionV2AnswersTableAnnotationComposer,
    $$InspectionV2AnswersTableCreateCompanionBuilder,
    $$InspectionV2AnswersTableUpdateCompanionBuilder,
    (
      InspectionV2Answer,
      BaseReferences<_$AppDatabase, $InspectionV2AnswersTable,
          InspectionV2Answer>
    ),
    InspectionV2Answer,
    PrefetchHooks Function()>;
typedef $$SyncQueueTableCreateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  required String entityType,
  required String entityId,
  required String action,
  required String payload,
  required DateTime createdAt,
  Value<int> retryCount,
  Value<String> status,
  Value<String?> errorMessage,
  Value<int?> serverVersion,
  Value<int> priority,
  Value<DateTime?> processedAt,
});
typedef $$SyncQueueTableUpdateCompanionBuilder = SyncQueueCompanion Function({
  Value<int> id,
  Value<String> entityType,
  Value<String> entityId,
  Value<String> action,
  Value<String> payload,
  Value<DateTime> createdAt,
  Value<int> retryCount,
  Value<String> status,
  Value<String?> errorMessage,
  Value<int?> serverVersion,
  Value<int> priority,
  Value<DateTime?> processedAt,
});

class $$SyncQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => ColumnFilters(column));
}

class $$SyncQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get entityId => $composableBuilder(
      column: $table.entityId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get action => $composableBuilder(
      column: $table.action, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payload => $composableBuilder(
      column: $table.payload, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priority => $composableBuilder(
      column: $table.priority, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => ColumnOrderings(column));
}

class $$SyncQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncQueueTable> {
  $$SyncQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
      column: $table.entityType, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
      column: $table.retryCount, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get errorMessage => $composableBuilder(
      column: $table.errorMessage, builder: (column) => column);

  GeneratedColumn<int> get serverVersion => $composableBuilder(
      column: $table.serverVersion, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get processedAt => $composableBuilder(
      column: $table.processedAt, builder: (column) => column);
}

class $$SyncQueueTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()> {
  $$SyncQueueTableTableManager(_$AppDatabase db, $SyncQueueTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> entityType = const Value.absent(),
            Value<String> entityId = const Value.absent(),
            Value<String> action = const Value.absent(),
            Value<String> payload = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> serverVersion = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<DateTime?> processedAt = const Value.absent(),
          }) =>
              SyncQueueCompanion(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            status: status,
            errorMessage: errorMessage,
            serverVersion: serverVersion,
            priority: priority,
            processedAt: processedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String entityType,
            required String entityId,
            required String action,
            required String payload,
            required DateTime createdAt,
            Value<int> retryCount = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> errorMessage = const Value.absent(),
            Value<int?> serverVersion = const Value.absent(),
            Value<int> priority = const Value.absent(),
            Value<DateTime?> processedAt = const Value.absent(),
          }) =>
              SyncQueueCompanion.insert(
            id: id,
            entityType: entityType,
            entityId: entityId,
            action: action,
            payload: payload,
            createdAt: createdAt,
            retryCount: retryCount,
            status: status,
            errorMessage: errorMessage,
            serverVersion: serverVersion,
            priority: priority,
            processedAt: processedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SyncQueueTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SyncQueueTable,
    SyncQueueData,
    $$SyncQueueTableFilterComposer,
    $$SyncQueueTableOrderingComposer,
    $$SyncQueueTableAnnotationComposer,
    $$SyncQueueTableCreateCompanionBuilder,
    $$SyncQueueTableUpdateCompanionBuilder,
    (
      SyncQueueData,
      BaseReferences<_$AppDatabase, $SyncQueueTable, SyncQueueData>
    ),
    SyncQueueData,
    PrefetchHooks Function()>;
typedef $$MediaItemsTableCreateCompanionBuilder = MediaItemsCompanion Function({
  required String id,
  required String surveyId,
  required String sectionId,
  required String mediaType,
  required String localPath,
  Value<String?> remotePath,
  Value<String?> caption,
  Value<String> status,
  Value<int?> fileSize,
  Value<int?> duration,
  Value<int?> width,
  Value<int?> height,
  Value<String?> thumbnailPath,
  Value<bool> hasAnnotations,
  Value<int> sortOrder,
  Value<String?> waveformData,
  Value<String?> transcription,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$MediaItemsTableUpdateCompanionBuilder = MediaItemsCompanion Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String> sectionId,
  Value<String> mediaType,
  Value<String> localPath,
  Value<String?> remotePath,
  Value<String?> caption,
  Value<String> status,
  Value<int?> fileSize,
  Value<int?> duration,
  Value<int?> width,
  Value<int?> height,
  Value<String?> thumbnailPath,
  Value<bool> hasAnnotations,
  Value<int> sortOrder,
  Value<String?> waveformData,
  Value<String?> transcription,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$MediaItemsTableFilterComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remotePath => $composableBuilder(
      column: $table.remotePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get hasAnnotations => $composableBuilder(
      column: $table.hasAnnotations,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get waveformData => $composableBuilder(
      column: $table.waveformData, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$MediaItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get mediaType => $composableBuilder(
      column: $table.mediaType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get localPath => $composableBuilder(
      column: $table.localPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remotePath => $composableBuilder(
      column: $table.remotePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caption => $composableBuilder(
      column: $table.caption, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get fileSize => $composableBuilder(
      column: $table.fileSize, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get duration => $composableBuilder(
      column: $table.duration, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get hasAnnotations => $composableBuilder(
      column: $table.hasAnnotations,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get waveformData => $composableBuilder(
      column: $table.waveformData,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get transcription => $composableBuilder(
      column: $table.transcription,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$MediaItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MediaItemsTable> {
  $$MediaItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
      column: $table.remotePath, builder: (column) => column);

  GeneratedColumn<String> get caption =>
      $composableBuilder(column: $table.caption, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<int> get duration =>
      $composableBuilder(column: $table.duration, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get thumbnailPath => $composableBuilder(
      column: $table.thumbnailPath, builder: (column) => column);

  GeneratedColumn<bool> get hasAnnotations => $composableBuilder(
      column: $table.hasAnnotations, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get waveformData => $composableBuilder(
      column: $table.waveformData, builder: (column) => column);

  GeneratedColumn<String> get transcription => $composableBuilder(
      column: $table.transcription, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$MediaItemsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MediaItemsTable,
    MediaItemsData,
    $$MediaItemsTableFilterComposer,
    $$MediaItemsTableOrderingComposer,
    $$MediaItemsTableAnnotationComposer,
    $$MediaItemsTableCreateCompanionBuilder,
    $$MediaItemsTableUpdateCompanionBuilder,
    (
      MediaItemsData,
      BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItemsData>
    ),
    MediaItemsData,
    PrefetchHooks Function()> {
  $$MediaItemsTableTableManager(_$AppDatabase db, $MediaItemsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MediaItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MediaItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MediaItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String> sectionId = const Value.absent(),
            Value<String> mediaType = const Value.absent(),
            Value<String> localPath = const Value.absent(),
            Value<String?> remotePath = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> fileSize = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<bool> hasAnnotations = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> waveformData = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemsCompanion(
            id: id,
            surveyId: surveyId,
            sectionId: sectionId,
            mediaType: mediaType,
            localPath: localPath,
            remotePath: remotePath,
            caption: caption,
            status: status,
            fileSize: fileSize,
            duration: duration,
            width: width,
            height: height,
            thumbnailPath: thumbnailPath,
            hasAnnotations: hasAnnotations,
            sortOrder: sortOrder,
            waveformData: waveformData,
            transcription: transcription,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            required String sectionId,
            required String mediaType,
            required String localPath,
            Value<String?> remotePath = const Value.absent(),
            Value<String?> caption = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int?> fileSize = const Value.absent(),
            Value<int?> duration = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<String?> thumbnailPath = const Value.absent(),
            Value<bool> hasAnnotations = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<String?> waveformData = const Value.absent(),
            Value<String?> transcription = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              MediaItemsCompanion.insert(
            id: id,
            surveyId: surveyId,
            sectionId: sectionId,
            mediaType: mediaType,
            localPath: localPath,
            remotePath: remotePath,
            caption: caption,
            status: status,
            fileSize: fileSize,
            duration: duration,
            width: width,
            height: height,
            thumbnailPath: thumbnailPath,
            hasAnnotations: hasAnnotations,
            sortOrder: sortOrder,
            waveformData: waveformData,
            transcription: transcription,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MediaItemsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MediaItemsTable,
    MediaItemsData,
    $$MediaItemsTableFilterComposer,
    $$MediaItemsTableOrderingComposer,
    $$MediaItemsTableAnnotationComposer,
    $$MediaItemsTableCreateCompanionBuilder,
    $$MediaItemsTableUpdateCompanionBuilder,
    (
      MediaItemsData,
      BaseReferences<_$AppDatabase, $MediaItemsTable, MediaItemsData>
    ),
    MediaItemsData,
    PrefetchHooks Function()>;
typedef $$PhotoAnnotationsTableCreateCompanionBuilder
    = PhotoAnnotationsCompanion Function({
  required String id,
  required String photoId,
  required String elementsJson,
  Value<String?> annotatedImagePath,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$PhotoAnnotationsTableUpdateCompanionBuilder
    = PhotoAnnotationsCompanion Function({
  Value<String> id,
  Value<String> photoId,
  Value<String> elementsJson,
  Value<String?> annotatedImagePath,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$PhotoAnnotationsTableFilterComposer
    extends Composer<_$AppDatabase, $PhotoAnnotationsTable> {
  $$PhotoAnnotationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get photoId => $composableBuilder(
      column: $table.photoId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get elementsJson => $composableBuilder(
      column: $table.elementsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get annotatedImagePath => $composableBuilder(
      column: $table.annotatedImagePath,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PhotoAnnotationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PhotoAnnotationsTable> {
  $$PhotoAnnotationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get photoId => $composableBuilder(
      column: $table.photoId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get elementsJson => $composableBuilder(
      column: $table.elementsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get annotatedImagePath => $composableBuilder(
      column: $table.annotatedImagePath,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PhotoAnnotationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PhotoAnnotationsTable> {
  $$PhotoAnnotationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get photoId =>
      $composableBuilder(column: $table.photoId, builder: (column) => column);

  GeneratedColumn<String> get elementsJson => $composableBuilder(
      column: $table.elementsJson, builder: (column) => column);

  GeneratedColumn<String> get annotatedImagePath => $composableBuilder(
      column: $table.annotatedImagePath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PhotoAnnotationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PhotoAnnotationsTable,
    PhotoAnnotationsData,
    $$PhotoAnnotationsTableFilterComposer,
    $$PhotoAnnotationsTableOrderingComposer,
    $$PhotoAnnotationsTableAnnotationComposer,
    $$PhotoAnnotationsTableCreateCompanionBuilder,
    $$PhotoAnnotationsTableUpdateCompanionBuilder,
    (
      PhotoAnnotationsData,
      BaseReferences<_$AppDatabase, $PhotoAnnotationsTable,
          PhotoAnnotationsData>
    ),
    PhotoAnnotationsData,
    PrefetchHooks Function()> {
  $$PhotoAnnotationsTableTableManager(
      _$AppDatabase db, $PhotoAnnotationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PhotoAnnotationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PhotoAnnotationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PhotoAnnotationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> photoId = const Value.absent(),
            Value<String> elementsJson = const Value.absent(),
            Value<String?> annotatedImagePath = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotoAnnotationsCompanion(
            id: id,
            photoId: photoId,
            elementsJson: elementsJson,
            annotatedImagePath: annotatedImagePath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String photoId,
            required String elementsJson,
            Value<String?> annotatedImagePath = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              PhotoAnnotationsCompanion.insert(
            id: id,
            photoId: photoId,
            elementsJson: elementsJson,
            annotatedImagePath: annotatedImagePath,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PhotoAnnotationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PhotoAnnotationsTable,
    PhotoAnnotationsData,
    $$PhotoAnnotationsTableFilterComposer,
    $$PhotoAnnotationsTableOrderingComposer,
    $$PhotoAnnotationsTableAnnotationComposer,
    $$PhotoAnnotationsTableCreateCompanionBuilder,
    $$PhotoAnnotationsTableUpdateCompanionBuilder,
    (
      PhotoAnnotationsData,
      BaseReferences<_$AppDatabase, $PhotoAnnotationsTable,
          PhotoAnnotationsData>
    ),
    PhotoAnnotationsData,
    PrefetchHooks Function()>;
typedef $$SignaturesTableCreateCompanionBuilder = SignaturesCompanion Function({
  required String id,
  required String surveyId,
  Value<String?> sectionId,
  Value<String?> signerName,
  Value<String?> signerRole,
  required String strokesJson,
  Value<String> status,
  Value<String?> previewPath,
  Value<int?> width,
  Value<int?> height,
  required DateTime createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});
typedef $$SignaturesTableUpdateCompanionBuilder = SignaturesCompanion Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String?> sectionId,
  Value<String?> signerName,
  Value<String?> signerRole,
  Value<String> strokesJson,
  Value<String> status,
  Value<String?> previewPath,
  Value<int?> width,
  Value<int?> height,
  Value<DateTime> createdAt,
  Value<DateTime?> updatedAt,
  Value<int> rowid,
});

class $$SignaturesTableFilterComposer
    extends Composer<_$AppDatabase, $SignaturesTable> {
  $$SignaturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signerName => $composableBuilder(
      column: $table.signerName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get signerRole => $composableBuilder(
      column: $table.signerRole, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get strokesJson => $composableBuilder(
      column: $table.strokesJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get previewPath => $composableBuilder(
      column: $table.previewPath, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$SignaturesTableOrderingComposer
    extends Composer<_$AppDatabase, $SignaturesTable> {
  $$SignaturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sectionId => $composableBuilder(
      column: $table.sectionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signerName => $composableBuilder(
      column: $table.signerName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get signerRole => $composableBuilder(
      column: $table.signerRole, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get strokesJson => $composableBuilder(
      column: $table.strokesJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get previewPath => $composableBuilder(
      column: $table.previewPath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get width => $composableBuilder(
      column: $table.width, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get height => $composableBuilder(
      column: $table.height, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$SignaturesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SignaturesTable> {
  $$SignaturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get sectionId =>
      $composableBuilder(column: $table.sectionId, builder: (column) => column);

  GeneratedColumn<String> get signerName => $composableBuilder(
      column: $table.signerName, builder: (column) => column);

  GeneratedColumn<String> get signerRole => $composableBuilder(
      column: $table.signerRole, builder: (column) => column);

  GeneratedColumn<String> get strokesJson => $composableBuilder(
      column: $table.strokesJson, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get previewPath => $composableBuilder(
      column: $table.previewPath, builder: (column) => column);

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SignaturesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SignaturesTable,
    SignatureData,
    $$SignaturesTableFilterComposer,
    $$SignaturesTableOrderingComposer,
    $$SignaturesTableAnnotationComposer,
    $$SignaturesTableCreateCompanionBuilder,
    $$SignaturesTableUpdateCompanionBuilder,
    (
      SignatureData,
      BaseReferences<_$AppDatabase, $SignaturesTable, SignatureData>
    ),
    SignatureData,
    PrefetchHooks Function()> {
  $$SignaturesTableTableManager(_$AppDatabase db, $SignaturesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SignaturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SignaturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SignaturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String?> sectionId = const Value.absent(),
            Value<String?> signerName = const Value.absent(),
            Value<String?> signerRole = const Value.absent(),
            Value<String> strokesJson = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<String?> previewPath = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignaturesCompanion(
            id: id,
            surveyId: surveyId,
            sectionId: sectionId,
            signerName: signerName,
            signerRole: signerRole,
            strokesJson: strokesJson,
            status: status,
            previewPath: previewPath,
            width: width,
            height: height,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            Value<String?> sectionId = const Value.absent(),
            Value<String?> signerName = const Value.absent(),
            Value<String?> signerRole = const Value.absent(),
            required String strokesJson,
            Value<String> status = const Value.absent(),
            Value<String?> previewPath = const Value.absent(),
            Value<int?> width = const Value.absent(),
            Value<int?> height = const Value.absent(),
            required DateTime createdAt,
            Value<DateTime?> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SignaturesCompanion.insert(
            id: id,
            surveyId: surveyId,
            sectionId: sectionId,
            signerName: signerName,
            signerRole: signerRole,
            strokesJson: strokesJson,
            status: status,
            previewPath: previewPath,
            width: width,
            height: height,
            createdAt: createdAt,
            updatedAt: updatedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SignaturesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SignaturesTable,
    SignatureData,
    $$SignaturesTableFilterComposer,
    $$SignaturesTableOrderingComposer,
    $$SignaturesTableAnnotationComposer,
    $$SignaturesTableCreateCompanionBuilder,
    $$SignaturesTableUpdateCompanionBuilder,
    (
      SignatureData,
      BaseReferences<_$AppDatabase, $SignaturesTable, SignatureData>
    ),
    SignatureData,
    PrefetchHooks Function()>;
typedef $$GeneratedReportsTableCreateCompanionBuilder
    = GeneratedReportsCompanion Function({
  required String id,
  required String surveyId,
  Value<String> surveyTitle,
  required String filePath,
  required String fileName,
  Value<int> sizeBytes,
  required DateTime generatedAt,
  Value<String> moduleType,
  Value<String> format,
  Value<String> style,
  Value<String?> remoteUrl,
  Value<String> checksum,
  Value<int> rowid,
});
typedef $$GeneratedReportsTableUpdateCompanionBuilder
    = GeneratedReportsCompanion Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String> surveyTitle,
  Value<String> filePath,
  Value<String> fileName,
  Value<int> sizeBytes,
  Value<DateTime> generatedAt,
  Value<String> moduleType,
  Value<String> format,
  Value<String> style,
  Value<String?> remoteUrl,
  Value<String> checksum,
  Value<int> rowid,
});

class $$GeneratedReportsTableFilterComposer
    extends Composer<_$AppDatabase, $GeneratedReportsTable> {
  $$GeneratedReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyTitle => $composableBuilder(
      column: $table.surveyTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moduleType => $composableBuilder(
      column: $table.moduleType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remoteUrl => $composableBuilder(
      column: $table.remoteUrl, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnFilters(column));
}

class $$GeneratedReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $GeneratedReportsTable> {
  $$GeneratedReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyTitle => $composableBuilder(
      column: $table.surveyTitle, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get filePath => $composableBuilder(
      column: $table.filePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fileName => $composableBuilder(
      column: $table.fileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
      column: $table.sizeBytes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moduleType => $composableBuilder(
      column: $table.moduleType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get format => $composableBuilder(
      column: $table.format, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get style => $composableBuilder(
      column: $table.style, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remoteUrl => $composableBuilder(
      column: $table.remoteUrl, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get checksum => $composableBuilder(
      column: $table.checksum, builder: (column) => ColumnOrderings(column));
}

class $$GeneratedReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GeneratedReportsTable> {
  $$GeneratedReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get surveyTitle => $composableBuilder(
      column: $table.surveyTitle, builder: (column) => column);

  GeneratedColumn<String> get filePath =>
      $composableBuilder(column: $table.filePath, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get moduleType => $composableBuilder(
      column: $table.moduleType, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<String> get remoteUrl =>
      $composableBuilder(column: $table.remoteUrl, builder: (column) => column);

  GeneratedColumn<String> get checksum =>
      $composableBuilder(column: $table.checksum, builder: (column) => column);
}

class $$GeneratedReportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $GeneratedReportsTable,
    GeneratedReportData,
    $$GeneratedReportsTableFilterComposer,
    $$GeneratedReportsTableOrderingComposer,
    $$GeneratedReportsTableAnnotationComposer,
    $$GeneratedReportsTableCreateCompanionBuilder,
    $$GeneratedReportsTableUpdateCompanionBuilder,
    (
      GeneratedReportData,
      BaseReferences<_$AppDatabase, $GeneratedReportsTable, GeneratedReportData>
    ),
    GeneratedReportData,
    PrefetchHooks Function()> {
  $$GeneratedReportsTableTableManager(
      _$AppDatabase db, $GeneratedReportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GeneratedReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GeneratedReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GeneratedReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String> surveyTitle = const Value.absent(),
            Value<String> filePath = const Value.absent(),
            Value<String> fileName = const Value.absent(),
            Value<int> sizeBytes = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<String> moduleType = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<String> style = const Value.absent(),
            Value<String?> remoteUrl = const Value.absent(),
            Value<String> checksum = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedReportsCompanion(
            id: id,
            surveyId: surveyId,
            surveyTitle: surveyTitle,
            filePath: filePath,
            fileName: fileName,
            sizeBytes: sizeBytes,
            generatedAt: generatedAt,
            moduleType: moduleType,
            format: format,
            style: style,
            remoteUrl: remoteUrl,
            checksum: checksum,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            Value<String> surveyTitle = const Value.absent(),
            required String filePath,
            required String fileName,
            Value<int> sizeBytes = const Value.absent(),
            required DateTime generatedAt,
            Value<String> moduleType = const Value.absent(),
            Value<String> format = const Value.absent(),
            Value<String> style = const Value.absent(),
            Value<String?> remoteUrl = const Value.absent(),
            Value<String> checksum = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              GeneratedReportsCompanion.insert(
            id: id,
            surveyId: surveyId,
            surveyTitle: surveyTitle,
            filePath: filePath,
            fileName: fileName,
            sizeBytes: sizeBytes,
            generatedAt: generatedAt,
            moduleType: moduleType,
            format: format,
            style: style,
            remoteUrl: remoteUrl,
            checksum: checksum,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$GeneratedReportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $GeneratedReportsTable,
    GeneratedReportData,
    $$GeneratedReportsTableFilterComposer,
    $$GeneratedReportsTableOrderingComposer,
    $$GeneratedReportsTableAnnotationComposer,
    $$GeneratedReportsTableCreateCompanionBuilder,
    $$GeneratedReportsTableUpdateCompanionBuilder,
    (
      GeneratedReportData,
      BaseReferences<_$AppDatabase, $GeneratedReportsTable, GeneratedReportData>
    ),
    GeneratedReportData,
    PrefetchHooks Function()>;
typedef $$SurveyRecommendationsTableCreateCompanionBuilder
    = SurveyRecommendationsCompanion Function({
  required String id,
  required String surveyId,
  required String category,
  required String severity,
  required String screenId,
  Value<String?> fieldId,
  required String reason,
  required String suggestedText,
  Value<bool> accepted,
  required DateTime createdAt,
  Value<String> sourceType,
  Value<String?> ruleVersion,
  Value<String?> aiModelVersion,
  Value<double?> confidenceScore,
  Value<int?> generationTimestamp,
  Value<String?> internalReasoning,
  Value<String?> auditHash,
  Value<int> rowid,
});
typedef $$SurveyRecommendationsTableUpdateCompanionBuilder
    = SurveyRecommendationsCompanion Function({
  Value<String> id,
  Value<String> surveyId,
  Value<String> category,
  Value<String> severity,
  Value<String> screenId,
  Value<String?> fieldId,
  Value<String> reason,
  Value<String> suggestedText,
  Value<bool> accepted,
  Value<DateTime> createdAt,
  Value<String> sourceType,
  Value<String?> ruleVersion,
  Value<String?> aiModelVersion,
  Value<double?> confidenceScore,
  Value<int?> generationTimestamp,
  Value<String?> internalReasoning,
  Value<String?> auditHash,
  Value<int> rowid,
});

class $$SurveyRecommendationsTableFilterComposer
    extends Composer<_$AppDatabase, $SurveyRecommendationsTable> {
  $$SurveyRecommendationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get screenId => $composableBuilder(
      column: $table.screenId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get fieldId => $composableBuilder(
      column: $table.fieldId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get suggestedText => $composableBuilder(
      column: $table.suggestedText, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ruleVersion => $composableBuilder(
      column: $table.ruleVersion, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get aiModelVersion => $composableBuilder(
      column: $table.aiModelVersion,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get generationTimestamp => $composableBuilder(
      column: $table.generationTimestamp,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get internalReasoning => $composableBuilder(
      column: $table.internalReasoning,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get auditHash => $composableBuilder(
      column: $table.auditHash, builder: (column) => ColumnFilters(column));
}

class $$SurveyRecommendationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveyRecommendationsTable> {
  $$SurveyRecommendationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get category => $composableBuilder(
      column: $table.category, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get severity => $composableBuilder(
      column: $table.severity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get screenId => $composableBuilder(
      column: $table.screenId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get fieldId => $composableBuilder(
      column: $table.fieldId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get reason => $composableBuilder(
      column: $table.reason, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get suggestedText => $composableBuilder(
      column: $table.suggestedText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get accepted => $composableBuilder(
      column: $table.accepted, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ruleVersion => $composableBuilder(
      column: $table.ruleVersion, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get aiModelVersion => $composableBuilder(
      column: $table.aiModelVersion,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get generationTimestamp => $composableBuilder(
      column: $table.generationTimestamp,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get internalReasoning => $composableBuilder(
      column: $table.internalReasoning,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get auditHash => $composableBuilder(
      column: $table.auditHash, builder: (column) => ColumnOrderings(column));
}

class $$SurveyRecommendationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveyRecommendationsTable> {
  $$SurveyRecommendationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get screenId =>
      $composableBuilder(column: $table.screenId, builder: (column) => column);

  GeneratedColumn<String> get fieldId =>
      $composableBuilder(column: $table.fieldId, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get suggestedText => $composableBuilder(
      column: $table.suggestedText, builder: (column) => column);

  GeneratedColumn<bool> get accepted =>
      $composableBuilder(column: $table.accepted, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
      column: $table.sourceType, builder: (column) => column);

  GeneratedColumn<String> get ruleVersion => $composableBuilder(
      column: $table.ruleVersion, builder: (column) => column);

  GeneratedColumn<String> get aiModelVersion => $composableBuilder(
      column: $table.aiModelVersion, builder: (column) => column);

  GeneratedColumn<double> get confidenceScore => $composableBuilder(
      column: $table.confidenceScore, builder: (column) => column);

  GeneratedColumn<int> get generationTimestamp => $composableBuilder(
      column: $table.generationTimestamp, builder: (column) => column);

  GeneratedColumn<String> get internalReasoning => $composableBuilder(
      column: $table.internalReasoning, builder: (column) => column);

  GeneratedColumn<String> get auditHash =>
      $composableBuilder(column: $table.auditHash, builder: (column) => column);
}

class $$SurveyRecommendationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveyRecommendationsTable,
    SurveyRecommendation,
    $$SurveyRecommendationsTableFilterComposer,
    $$SurveyRecommendationsTableOrderingComposer,
    $$SurveyRecommendationsTableAnnotationComposer,
    $$SurveyRecommendationsTableCreateCompanionBuilder,
    $$SurveyRecommendationsTableUpdateCompanionBuilder,
    (
      SurveyRecommendation,
      BaseReferences<_$AppDatabase, $SurveyRecommendationsTable,
          SurveyRecommendation>
    ),
    SurveyRecommendation,
    PrefetchHooks Function()> {
  $$SurveyRecommendationsTableTableManager(
      _$AppDatabase db, $SurveyRecommendationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyRecommendationsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyRecommendationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyRecommendationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<String> category = const Value.absent(),
            Value<String> severity = const Value.absent(),
            Value<String> screenId = const Value.absent(),
            Value<String?> fieldId = const Value.absent(),
            Value<String> reason = const Value.absent(),
            Value<String> suggestedText = const Value.absent(),
            Value<bool> accepted = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<String> sourceType = const Value.absent(),
            Value<String?> ruleVersion = const Value.absent(),
            Value<String?> aiModelVersion = const Value.absent(),
            Value<double?> confidenceScore = const Value.absent(),
            Value<int?> generationTimestamp = const Value.absent(),
            Value<String?> internalReasoning = const Value.absent(),
            Value<String?> auditHash = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyRecommendationsCompanion(
            id: id,
            surveyId: surveyId,
            category: category,
            severity: severity,
            screenId: screenId,
            fieldId: fieldId,
            reason: reason,
            suggestedText: suggestedText,
            accepted: accepted,
            createdAt: createdAt,
            sourceType: sourceType,
            ruleVersion: ruleVersion,
            aiModelVersion: aiModelVersion,
            confidenceScore: confidenceScore,
            generationTimestamp: generationTimestamp,
            internalReasoning: internalReasoning,
            auditHash: auditHash,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            required String category,
            required String severity,
            required String screenId,
            Value<String?> fieldId = const Value.absent(),
            required String reason,
            required String suggestedText,
            Value<bool> accepted = const Value.absent(),
            required DateTime createdAt,
            Value<String> sourceType = const Value.absent(),
            Value<String?> ruleVersion = const Value.absent(),
            Value<String?> aiModelVersion = const Value.absent(),
            Value<double?> confidenceScore = const Value.absent(),
            Value<int?> generationTimestamp = const Value.absent(),
            Value<String?> internalReasoning = const Value.absent(),
            Value<String?> auditHash = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyRecommendationsCompanion.insert(
            id: id,
            surveyId: surveyId,
            category: category,
            severity: severity,
            screenId: screenId,
            fieldId: fieldId,
            reason: reason,
            suggestedText: suggestedText,
            accepted: accepted,
            createdAt: createdAt,
            sourceType: sourceType,
            ruleVersion: ruleVersion,
            aiModelVersion: aiModelVersion,
            confidenceScore: confidenceScore,
            generationTimestamp: generationTimestamp,
            internalReasoning: internalReasoning,
            auditHash: auditHash,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurveyRecommendationsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $SurveyRecommendationsTable,
        SurveyRecommendation,
        $$SurveyRecommendationsTableFilterComposer,
        $$SurveyRecommendationsTableOrderingComposer,
        $$SurveyRecommendationsTableAnnotationComposer,
        $$SurveyRecommendationsTableCreateCompanionBuilder,
        $$SurveyRecommendationsTableUpdateCompanionBuilder,
        (
          SurveyRecommendation,
          BaseReferences<_$AppDatabase, $SurveyRecommendationsTable,
              SurveyRecommendation>
        ),
        SurveyRecommendation,
        PrefetchHooks Function()>;
typedef $$SurveyQualityScoresTableCreateCompanionBuilder
    = SurveyQualityScoresCompanion Function({
  required String id,
  required String surveyId,
  required double complianceScore,
  required double narrativeScore,
  required double riskScore,
  required double overallScore,
  required DateTime generatedAt,
  required String engineVersion,
  Value<int> rowid,
});
typedef $$SurveyQualityScoresTableUpdateCompanionBuilder
    = SurveyQualityScoresCompanion Function({
  Value<String> id,
  Value<String> surveyId,
  Value<double> complianceScore,
  Value<double> narrativeScore,
  Value<double> riskScore,
  Value<double> overallScore,
  Value<DateTime> generatedAt,
  Value<String> engineVersion,
  Value<int> rowid,
});

class $$SurveyQualityScoresTableFilterComposer
    extends Composer<_$AppDatabase, $SurveyQualityScoresTable> {
  $$SurveyQualityScoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get complianceScore => $composableBuilder(
      column: $table.complianceScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get narrativeScore => $composableBuilder(
      column: $table.narrativeScore,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get riskScore => $composableBuilder(
      column: $table.riskScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get overallScore => $composableBuilder(
      column: $table.overallScore, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get engineVersion => $composableBuilder(
      column: $table.engineVersion, builder: (column) => ColumnFilters(column));
}

class $$SurveyQualityScoresTableOrderingComposer
    extends Composer<_$AppDatabase, $SurveyQualityScoresTable> {
  $$SurveyQualityScoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get surveyId => $composableBuilder(
      column: $table.surveyId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get complianceScore => $composableBuilder(
      column: $table.complianceScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get narrativeScore => $composableBuilder(
      column: $table.narrativeScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get riskScore => $composableBuilder(
      column: $table.riskScore, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get overallScore => $composableBuilder(
      column: $table.overallScore,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get engineVersion => $composableBuilder(
      column: $table.engineVersion,
      builder: (column) => ColumnOrderings(column));
}

class $$SurveyQualityScoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $SurveyQualityScoresTable> {
  $$SurveyQualityScoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get surveyId =>
      $composableBuilder(column: $table.surveyId, builder: (column) => column);

  GeneratedColumn<double> get complianceScore => $composableBuilder(
      column: $table.complianceScore, builder: (column) => column);

  GeneratedColumn<double> get narrativeScore => $composableBuilder(
      column: $table.narrativeScore, builder: (column) => column);

  GeneratedColumn<double> get riskScore =>
      $composableBuilder(column: $table.riskScore, builder: (column) => column);

  GeneratedColumn<double> get overallScore => $composableBuilder(
      column: $table.overallScore, builder: (column) => column);

  GeneratedColumn<DateTime> get generatedAt => $composableBuilder(
      column: $table.generatedAt, builder: (column) => column);

  GeneratedColumn<String> get engineVersion => $composableBuilder(
      column: $table.engineVersion, builder: (column) => column);
}

class $$SurveyQualityScoresTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SurveyQualityScoresTable,
    SurveyQualityScore,
    $$SurveyQualityScoresTableFilterComposer,
    $$SurveyQualityScoresTableOrderingComposer,
    $$SurveyQualityScoresTableAnnotationComposer,
    $$SurveyQualityScoresTableCreateCompanionBuilder,
    $$SurveyQualityScoresTableUpdateCompanionBuilder,
    (
      SurveyQualityScore,
      BaseReferences<_$AppDatabase, $SurveyQualityScoresTable,
          SurveyQualityScore>
    ),
    SurveyQualityScore,
    PrefetchHooks Function()> {
  $$SurveyQualityScoresTableTableManager(
      _$AppDatabase db, $SurveyQualityScoresTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SurveyQualityScoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SurveyQualityScoresTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SurveyQualityScoresTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> surveyId = const Value.absent(),
            Value<double> complianceScore = const Value.absent(),
            Value<double> narrativeScore = const Value.absent(),
            Value<double> riskScore = const Value.absent(),
            Value<double> overallScore = const Value.absent(),
            Value<DateTime> generatedAt = const Value.absent(),
            Value<String> engineVersion = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyQualityScoresCompanion(
            id: id,
            surveyId: surveyId,
            complianceScore: complianceScore,
            narrativeScore: narrativeScore,
            riskScore: riskScore,
            overallScore: overallScore,
            generatedAt: generatedAt,
            engineVersion: engineVersion,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String surveyId,
            required double complianceScore,
            required double narrativeScore,
            required double riskScore,
            required double overallScore,
            required DateTime generatedAt,
            required String engineVersion,
            Value<int> rowid = const Value.absent(),
          }) =>
              SurveyQualityScoresCompanion.insert(
            id: id,
            surveyId: surveyId,
            complianceScore: complianceScore,
            narrativeScore: narrativeScore,
            riskScore: riskScore,
            overallScore: overallScore,
            generatedAt: generatedAt,
            engineVersion: engineVersion,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SurveyQualityScoresTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SurveyQualityScoresTable,
    SurveyQualityScore,
    $$SurveyQualityScoresTableFilterComposer,
    $$SurveyQualityScoresTableOrderingComposer,
    $$SurveyQualityScoresTableAnnotationComposer,
    $$SurveyQualityScoresTableCreateCompanionBuilder,
    $$SurveyQualityScoresTableUpdateCompanionBuilder,
    (
      SurveyQualityScore,
      BaseReferences<_$AppDatabase, $SurveyQualityScoresTable,
          SurveyQualityScore>
    ),
    SurveyQualityScore,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SurveysTableTableManager get surveys =>
      $$SurveysTableTableManager(_db, _db.surveys);
  $$SurveySectionsTableTableManager get surveySections =>
      $$SurveySectionsTableTableManager(_db, _db.surveySections);
  $$SurveyAnswersTableTableManager get surveyAnswers =>
      $$SurveyAnswersTableTableManager(_db, _db.surveyAnswers);
  $$InspectionV2ScreensTableTableManager get inspectionV2Screens =>
      $$InspectionV2ScreensTableTableManager(_db, _db.inspectionV2Screens);
  $$InspectionV2AnswersTableTableManager get inspectionV2Answers =>
      $$InspectionV2AnswersTableTableManager(_db, _db.inspectionV2Answers);
  $$SyncQueueTableTableManager get syncQueue =>
      $$SyncQueueTableTableManager(_db, _db.syncQueue);
  $$MediaItemsTableTableManager get mediaItems =>
      $$MediaItemsTableTableManager(_db, _db.mediaItems);
  $$PhotoAnnotationsTableTableManager get photoAnnotations =>
      $$PhotoAnnotationsTableTableManager(_db, _db.photoAnnotations);
  $$SignaturesTableTableManager get signatures =>
      $$SignaturesTableTableManager(_db, _db.signatures);
  $$GeneratedReportsTableTableManager get generatedReports =>
      $$GeneratedReportsTableTableManager(_db, _db.generatedReports);
  $$SurveyRecommendationsTableTableManager get surveyRecommendations =>
      $$SurveyRecommendationsTableTableManager(_db, _db.surveyRecommendations);
  $$SurveyQualityScoresTableTableManager get surveyQualityScores =>
      $$SurveyQualityScoresTableTableManager(_db, _db.surveyQualityScores);
}
