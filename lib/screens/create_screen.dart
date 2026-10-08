import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../core/motion.dart';
import '../data/departments.dart';
import '../data/recall_store.dart';
import '../db/app_database.dart';
import '../models/institute.dart';
import '../models/topsheet_data.dart';
import '../pdf/topsheet_pdf.dart';
import '../services/remote_data_service.dart';
import '../widgets/pressable.dart';
import '../widgets/recall_text_field.dart';
import '../widgets/searchable_picker.dart';

/* Hallmark · genre: modern-minimal · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

/// Animation length that respects the OS reduce-motion flag and the app's
/// own jank-based downgrade.
Duration _motion(BuildContext context, Duration full) {
  if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
    return Duration.zero;
  }
  return motionTierOf(context) == MotionTier.reduced ? Motion.fast : full;
}

enum _GenState { idle, generating, done }

class CreateScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const CreateScreen({super.key, this.initialData});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen>
    with WidgetsBindingObserver {
  static const _requiredCount = 14;

  /// Error ids, in the order the fields appear on screen.
  static const _fieldOrder = [
    'department',
    'semester',
    'subject',
    'exptNo',
    'exptName',
    'dateOfExpt',
    'submissionDate',
    'studentName',
    'studentIndex',
    'boardRoll',
    'batch',
    'teacherName',
    'teacherRole',
    'teacherDepartment',
  ];

  final _data = TopsheetData();
  final _df = DateFormat('dd MMM yyyy');

  final _exptNoCtrl = TextEditingController();
  final _exptNameCtrl = TextEditingController();
  final _studentNameCtrl = TextEditingController();
  final _studentIndexCtrl = TextEditingController();
  final _boardRollCtrl = TextEditingController();
  final _batchCtrl = TextEditingController();
  final _teacherNameCtrl = TextEditingController();
  final _teacherRoleCtrl = TextEditingController();
  final _teacherDeptCtrl = TextEditingController();

  late final Map<String, TextEditingController> _textFields = {
    'exptNo': _exptNoCtrl,
    'exptName': _exptNameCtrl,
    'studentName': _studentNameCtrl,
    'studentIndex': _studentIndexCtrl,
    'boardRoll': _boardRollCtrl,
    'batch': _batchCtrl,
    'teacherName': _teacherNameCtrl,
    'teacherRole': _teacherRoleCtrl,
    'teacherDepartment': _teacherDeptCtrl,
  };

  final _scrollController = ScrollController();
  final Map<String, GlobalKey> _fieldKeys = {
    for (final id in _fieldOrder) id: GlobalKey(),
  };

  _GenState _genState = _GenState.idle;
  int _shakeSignal = 0;
  bool _showHint = false;
  bool _loadingSubjects = false;
  String? _subjectNote;
  bool _subjectNoteRetry = false;
  bool _bulkUpdate = false;
  final Map<String, String?> _errors = {};
  String? _lastSavedDraft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    for (final c in _textFields.values) {
      c.addListener(_onFieldChanged);
    }
    if (widget.initialData != null) {
      // Older saved topsheets have no institute; fill it from the profile.
      _restoreFrom(widget.initialData!).whenComplete(_applyProfileDefaults);
    } else {
      _restoreLastPicks().whenComplete(() {
        _restoreDraft().whenComplete(_applyProfileDefaults);
      });
    }
    RecallStore.instance.hintSeen().then((seen) {
      if (mounted && !seen) setState(() => _showHint = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save the in-progress form whenever the app leaves the foreground, so
    // an interrupted fill-out survives being backgrounded or killed.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  /// Rebuilds the progress counters while typing and clears an error as
  /// soon as its field has a value.
  void _onFieldChanged() {
    if (!mounted || _bulkUpdate) return;
    setState(() {
      for (final e in _textFields.entries) {
        if (_errors.containsKey(e.key) && e.value.text.trim().isNotEmpty) {
          _errors.remove(e.key);
        }
      }
    });
  }

  Map<String, dynamic> _draftJson() => {
    'deptCode': _data.department?.code,
    'instituteName': _data.instituteName,
    'instituteCode': _data.instituteCode,
    'instituteAddress': _data.instituteAddress,
    'instituteWebsite': _data.instituteWebsite,
    'subjectCode': _data.subject?.code,
    'semester': _data.semester,
    'exptNo': _exptNoCtrl.text,
    'exptName': _exptNameCtrl.text,
    'dateOfExpt': _data.dateOfExpt?.toIso8601String(),
    'submissionDate': _data.submissionDate?.toIso8601String(),
    'studentName': _studentNameCtrl.text,
    'studentIndex': _studentIndexCtrl.text,
    'boardRoll': _boardRollCtrl.text,
    'batch': _batchCtrl.text,
    'teacherName': _teacherNameCtrl.text,
    'teacherRole': _teacherRoleCtrl.text,
    'teacherDepartment': _teacherDeptCtrl.text,
  };

  Future<void> _saveDraft() async {
    final json = _draftJson();
    // Lifecycle transitions fire inactive then paused back-to-back; skip the
    // duplicate write when nothing changed since the last save.
    final encoded = jsonEncode(json);
    if (encoded == _lastSavedDraft) return;
    _lastSavedDraft = encoded;
    await RecallStore.instance.saveDraft(json);
  }

  Future<void> _restoreDraft() async {
    final draft = await RecallStore.instance.loadDraft();
    if (draft == null) return;
    await _restoreFrom(draft);
  }

  /// Populates the form from a saved draft OR a recent topsheet's stored
  /// formData (edit flow) — same shape, same restore logic either way.
  /// The subject is looked up in the background so the form never waits
  /// for the network.
  Future<void> _restoreFrom(Map<String, dynamic> draft) async {
    final deptCode = draft['deptCode'] as int?;
    final dept = deptCode == null ? null : departmentByCode(deptCode);
    if (!mounted) return;
    _bulkUpdate = true;
    setState(() {
      if (dept != null) _data.department = dept;
      _data.semester = draft['semester'] as String? ?? _data.semester;
      _data.instituteName =
          draft['instituteName'] as String? ?? _data.instituteName;
      _data.instituteCode =
          draft['instituteCode'] as String? ?? _data.instituteCode;
      _data.instituteAddress =
          draft['instituteAddress'] as String? ?? _data.instituteAddress;
      _data.instituteWebsite =
          draft['instituteWebsite'] as String? ?? _data.instituteWebsite;
      _exptNoCtrl.text = draft['exptNo'] as String? ?? '';
      _exptNameCtrl.text = draft['exptName'] as String? ?? '';
      _studentNameCtrl.text = draft['studentName'] as String? ?? '';
      _studentIndexCtrl.text = draft['studentIndex'] as String? ?? '';
      _boardRollCtrl.text = draft['boardRoll'] as String? ?? '';
      _batchCtrl.text = draft['batch'] as String? ?? '';
      _teacherNameCtrl.text = draft['teacherName'] as String? ?? '';
      _teacherRoleCtrl.text = draft['teacherRole'] as String? ?? '';
      _teacherDeptCtrl.text = draft['teacherDepartment'] as String? ?? '';
      final dateOfExpt = draft['dateOfExpt'] as String?;
      if (dateOfExpt != null) _data.dateOfExpt = DateTime.tryParse(dateOfExpt);
      final submissionDate = draft['submissionDate'] as String?;
      if (submissionDate != null) {
        _data.submissionDate = DateTime.tryParse(submissionDate);
      }
    });
    _bulkUpdate = false;
    final subjectCode = draft['subjectCode'] as int?;
    if (dept != null && subjectCode != null) {
      unawaited(_restoreSubject(dept.code, subjectCode, force: true));
    }
  }

  /// Looks the subject up without blocking the form. A draft may replace a
  /// subject restored from the last picks ([force]); the last picks never
  /// overwrite one that is already set.
  Future<void> _restoreSubject(
    int deptCode,
    int subjectCode, {
    bool force = false,
  }) async {
    final subjects = await AppDatabase.instance.subjectsForDeptAndSemester(
      deptCode,
    );
    if (!mounted || _data.department?.code != deptCode) return;
    if (!force && _data.subject != null) return;
    for (final s in subjects) {
      if (s.code == subjectCode) {
        setState(() => _data.subject = s);
        return;
      }
    }
  }

  Future<void> _restoreLastPicks() async {
    final last = await RecallStore.instance.lastPicks();
    if (last == null) return;
    final (deptCode, subjectCode, semester) = last;
    final dept = departmentByCode(deptCode);
    if (dept == null || !mounted) return;
    setState(() {
      _data.department = dept;
      _data.semester = semester;
    });
    unawaited(_restoreSubject(dept.code, subjectCode));
  }

  /// Fills in the user's onboarding profile (name, index, semester,
  /// department) as a fallback — but only for fields still empty after
  /// last-picks/draft restore, so recent usage history always wins over
  /// the onboarding-time default.
  Future<void> _applyProfileDefaults() async {
    final profile = await RecallStore.instance.loadProfile();
    if (profile == null || !mounted) return;
    _bulkUpdate = true;
    setState(() {
      // Draft/edit data wins; profile only fills an empty institute.
      if (_data.instituteName.isEmpty) {
        _data.instituteName = profile['instituteName'] as String? ?? '';
        _data.instituteCode = profile['instituteCode'] as String? ?? '';
        _data.instituteAddress = profile['instituteAddress'] as String? ?? '';
        _data.instituteWebsite = profile['instituteWebsite'] as String? ?? '';
      }
      if (_studentNameCtrl.text.trim().isEmpty) {
        _studentNameCtrl.text = profile['name'] as String? ?? '';
      }
      if (_studentIndexCtrl.text.trim().isEmpty) {
        _studentIndexCtrl.text = profile['studentIndex'] as String? ?? '';
      }
      if (_data.semester.isEmpty) {
        final semester = profile['semester'] as String?;
        if (semester != null && semester.isNotEmpty) _data.semester = semester;
      }
      if (_data.department == null) {
        final deptCode = profile['deptCode'] as int?;
        if (deptCode != null) {
          final dept = departmentByCode(deptCode);
          if (dept != null) _data.department = dept;
        }
      }
    });
    _bulkUpdate = false;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _pickInstitute() async {
    final raw = await RemoteDataService.instance.fetchInstitutes();
    if (!mounted) return;
    if (raw == null || raw.isEmpty) {
      _toast("Couldn't load institutes. Check your connection and try again.");
      return;
    }
    final result = await showSearchablePicker<Institute>(
      context: context,
      title: 'Select Institute',
      items: raw.map(Institute.fromJson).toList(),
      labelOf: (i) => i.name,
      subtitleOf: (i) => i.code == null ? '' : 'Code ${i.code}',
    );
    if (result == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _data.instituteName = result.name;
      _data.instituteCode = result.code ?? '';
      _data.instituteAddress = result.address ?? '';
      _data.instituteWebsite = result.website ?? '';
    });
  }

  Future<void> _pickDepartment() async {
    if (btebDepartments.isEmpty) {
      await RemoteDataService.instance.ensureDepartments();
      if (!mounted) return;
      if (btebDepartments.isEmpty) {
        _toast("Couldn't load departments. Check your connection and try again.");
        return;
      }
    }
    final result = await showSearchablePicker<Department>(
      context: context,
      title: 'Select Department',
      items: btebDepartments,
      labelOf: (d) => '${d.longName} (${d.shortName})',
      subtitleOf: (d) => 'Code ${d.code}',
    );
    if (result == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (_data.department?.code != result.code) _data.subject = null;
      _data.department = result;
      _subjectNote = null;
      _errors.remove('department');
    });
  }

  Future<void> _pickSemester() async {
    final result = await showSearchablePicker<String>(
      context: context,
      title: 'Select Semester',
      items: semesters,
      labelOf: (s) => s,
    );
    if (result == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      // A subject from another semester no longer applies.
      if (_data.semester != result) _data.subject = null;
      _data.semester = result;
      _subjectNote = null;
      _errors.remove('semester');
    });
  }

  int? _semesterNumber() {
    if (_data.semester.isEmpty) return null;
    final idx = semesters.indexOf(_data.semester);
    return idx == -1 ? null : idx + 1;
  }

  /// Opens the subject list. While subjects are being fetched the field
  /// shows a spinner; if there are none, the reason is shown under the
  /// field (with Retry when the cause may be the connection).
  Future<void> _pickSubject({bool forceDownload = false}) async {
    final dept = _data.department;
    final semNumber = _semesterNumber();
    if (dept == null || semNumber == null || _loadingSubjects) return;

    setState(() {
      _loadingSubjects = true;
      _subjectNote = null;
    });

    var subjects = <Subject>[];
    try {
      subjects = await AppDatabase.instance.subjectsForDeptAndSemester(
        dept.code,
        semNumber,
      );
      if (subjects.isEmpty && forceDownload) {
        // The user asked explicitly, so skip the short back-off.
        final ok = await AppDatabase.instance.syncSubjects(
          dept.code,
          force: true,
        );
        if (ok) {
          subjects = await AppDatabase.instance.subjectsForDeptAndSemester(
            dept.code,
            semNumber,
          );
        }
      }
    } catch (_) {
      subjects = <Subject>[];
    }
    if (!mounted) return;

    if (subjects.isEmpty) {
      // Does this department have subjects for any semester?
      var hasAny = false;
      try {
        final all = await AppDatabase.instance.subjectsForDeptAndSemester(
          dept.code,
        );
        hasAny = all.isNotEmpty;
      } catch (_) {
        hasAny = false;
      }
      if (!mounted) return;
      setState(() {
        _loadingSubjects = false;
        _subjectNoteRetry = !hasAny;
        _subjectNote = hasAny
            ? 'No subjects are listed for ${dept.shortName} \u00b7 ${_data.semester} yet.'
            : "Couldn't load subjects for ${dept.shortName}. Connect to the "
                  'internet and try again. They are saved on your phone after '
                  'the first download.';
      });
      return;
    }

    setState(() => _loadingSubjects = false);
    final result = await showSearchablePicker<Subject>(
      context: context,
      title: 'Select Subject',
      items: subjects,
      labelOf: (s) => s.name,
      subtitleOf: (s) => 'Code ${s.code}',
    );
    if (result == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() {
      _data.subject = result;
      _errors.remove('subject');
    });
  }

  Future<void> _pickDate({required bool isSubmission}) async {
    final current = isSubmission ? _data.submissionDate : _data.dateOfExpt;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isSubmission) {
        _data.submissionDate = picked;
        _errors.remove('submissionDate');
      } else {
        _data.dateOfExpt = picked;
        _errors.remove('dateOfExpt');
      }
    });
  }

  void _syncTextFields() {
    _data.exptNo = int.tryParse(_exptNoCtrl.text.trim());
    _data.exptName = _exptNameCtrl.text;
    _data.studentName = _studentNameCtrl.text;
    _data.studentIndex = _studentIndexCtrl.text;
    _data.boardRoll = int.tryParse(_boardRollCtrl.text.trim());
    _data.batch = _batchCtrl.text;
    _data.teacherName = _teacherNameCtrl.text;
    _data.teacherRole = _teacherRoleCtrl.text;
    _data.teacherDepartment = _teacherDeptCtrl.text;
  }

  bool _validate() {
    _errors.clear();
    String? numberError(TextEditingController c) {
      final t = c.text.trim();
      if (t.isEmpty) return 'Required';
      if (int.tryParse(t) == null) return 'Numbers only';
      return null;
    }

    if (_data.department == null) _errors['department'] = 'Required';
    if (_data.semester.isEmpty) _errors['semester'] = 'Required';
    if (_data.subject == null) _errors['subject'] = 'Required';

    final exptNoError = numberError(_exptNoCtrl);
    if (exptNoError != null) _errors['exptNo'] = exptNoError;
    if (_exptNameCtrl.text.trim().isEmpty) _errors['exptName'] = 'Required';
    if (_data.dateOfExpt == null) _errors['dateOfExpt'] = 'Required';
    if (_data.submissionDate == null) _errors['submissionDate'] = 'Required';

    if (_studentNameCtrl.text.trim().isEmpty) {
      _errors['studentName'] = 'Required';
    }
    if (_studentIndexCtrl.text.trim().isEmpty) {
      _errors['studentIndex'] = 'Required';
    }
    final boardRollError = numberError(_boardRollCtrl);
    if (boardRollError != null) _errors['boardRoll'] = boardRollError;
    if (_batchCtrl.text.trim().isEmpty) _errors['batch'] = 'Required';

    if (_teacherNameCtrl.text.trim().isEmpty) {
      _errors['teacherName'] = 'Required';
    }
    if (_teacherRoleCtrl.text.trim().isEmpty) {
      _errors['teacherRole'] = 'Required';
    }
    if (_teacherDeptCtrl.text.trim().isEmpty) {
      _errors['teacherDepartment'] = 'Required';
    }
    return _errors.isEmpty;
  }

  void _scrollToFirstError() {
    for (final id in _fieldOrder) {
      if (!_errors.containsKey(id)) continue;
      final ctx = _fieldKeys[id]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.2,
          duration: _motion(context, Motion.slow),
          curve: Motion.standardCurve,
        );
      }
      return;
    }
  }

  Future<void> _generatePdf() async {
    if (_genState != _GenState.idle) return;
    FocusManager.instance.primaryFocus?.unfocus();
    _syncTextFields();
    if (!_validate()) {
      setState(() => _shakeSignal++);
      HapticFeedback.heavyImpact();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _scrollToFirstError(),
      );
      _toast('Fill in the highlighted fields');
      return;
    }
    setState(() => _genState = _GenState.generating);
    try {
      final bytes = await generateTopsheetPdf(_data);

      // Remember repeat-prone fields so the next topsheet (same batch/teacher,
      // different experiment) doesn't need retyping.
      await RecallStore.instance.rememberAll({
        'studentName': _data.studentName,
        'studentIndex': _data.studentIndex,
        'batch': _data.batch,
        'teacherName': _data.teacherName,
        'teacherRole': _data.teacherRole,
        'teacherDepartment': _data.teacherDepartment,
        'exptName': _data.exptName,
      });
      await RecallStore.instance.saveStudentProfile(_data.studentName, {
        'studentIndex': _data.studentIndex,
        'boardRoll': _boardRollCtrl.text,
        'batch': _data.batch,
      });
      await RecallStore.instance.rememberLastPicks(
        deptCode: _data.department!.code,
        subjectCode: _data.subject!.code,
        semester: _data.semester,
      );

      final displayName = _data.exptName.isEmpty
          ? (_data.subject?.name ?? 'Topsheet')
          : '${_data.exptName} \u2014 ${_data.subject?.name ?? ''}';
      await _saveToRecents(bytes, displayName.trim(), _draftJson());
      await RecallStore.instance.clearDraft();
      if (!mounted) return;

      // Clear per-experiment fields only — teacher/student/dept/batch carry
      // over to the next topsheet.
      _exptNoCtrl.clear();
      _exptNameCtrl.clear();
      setState(() {
        _data.exptNo = null;
        _data.exptName = '';
        _data.dateOfExpt = null;
        _data.submissionDate = null;
      });

      HapticFeedback.mediumImpact();
      setState(() => _genState = _GenState.done);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _genState = _GenState.idle);
      if (mounted) await _showPdfSheet(bytes, displayName.trim());
    } catch (_) {
      if (mounted) _toast("Couldn't create the PDF. Please try again.");
    } finally {
      if (mounted && _genState == _GenState.generating) {
        setState(() => _genState = _GenState.idle);
      }
    }
  }

  Future<void> _saveToRecents(
    Uint8List bytes,
    String name,
    Map<String, dynamic> formData,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final topsheetsDir = Directory(p.join(dir.path, 'topsheets'));
    if (!await topsheetsDir.exists()) {
      await topsheetsDir.create(recursive: true);
    }
    final file = File(
      p.join(
        topsheetsDir.path,
        'topsheet_${DateTime.now().millisecondsSinceEpoch}.pdf',
      ),
    );
    await file.writeAsBytes(bytes);
    final dropped = await RecallStore.instance.addRecentPdf(
      path: file.path,
      name: name,
      formData: formData,
    );
    for (final path in dropped) {
      final f = File(path);
      if (await f.exists()) await f.delete();
    }
  }

  String _pdfFileNameFor(String name) {
    final raw = (name.isEmpty ? 'topsheet' : name).toLowerCase();
    final sanitized = raw
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return '${sanitized.isEmpty ? 'topsheet' : sanitized}.pdf';
  }

  Future<void> _sharePdf(Uint8List bytes, String name) async {
    await Printing.sharePdf(bytes: bytes, filename: _pdfFileNameFor(name));
  }

  Future<void> _savePdf(Uint8List bytes, String name) async {
    final ok = await Printing.layoutPdf(
      onLayout: (_) async => bytes,
      name: _pdfFileNameFor(name),
      dynamicLayout: false,
    );
    if (!mounted) return;
    _toast(ok ? 'Save dialog completed' : 'Save dialog canceled');
  }

  Future<void> _showPdfSheet(Uint8List bytes, String name) {
    final title = name.isEmpty ? 'Topsheet' : name;
    return Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: _motion(context, Motion.slow),
        pageBuilder: (ctx, anim, secAnim) => FadeTransition(
          opacity: anim,
          child: _PdfResultPage(
            bytes: bytes,
            title: title,
            fileName: _pdfFileNameFor(title),
            onShare: () => _sharePdf(bytes, title),
            onSave: () => _savePdf(bytes, title),
          ),
        ),
      ),
    );
  }

  Future<void> _fillStudentProfile(String name) async {
    final profile = await RecallStore.instance.studentProfile(name);
    if (profile == null || !mounted) return;
    _bulkUpdate = true;
    setState(() {
      _studentIndexCtrl.text =
          profile['studentIndex'] ?? _studentIndexCtrl.text;
      _boardRollCtrl.text = profile['boardRoll'] ?? _boardRollCtrl.text;
      _batchCtrl.text = profile['batch'] ?? _batchCtrl.text;
      _errors.remove('studentIndex');
      _errors.remove('boardRoll');
      _errors.remove('batch');
    });
    _bulkUpdate = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _exptNoCtrl.dispose();
    _exptNameCtrl.dispose();
    _studentNameCtrl.dispose();
    _studentIndexCtrl.dispose();
    _boardRollCtrl.dispose();
    _batchCtrl.dispose();
    _teacherNameCtrl.dispose();
    _teacherRoleCtrl.dispose();
    _teacherDeptCtrl.dispose();
    super.dispose();
  }

  Widget _buildBottomBar(ColorScheme scheme) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return AnimatedSize(
      duration: _motion(context, Motion.standard),
      curve: Motion.standardCurve,
      alignment: Alignment.bottomCenter,
      child: keyboardOpen
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                12 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: _GenerateButton(
                state: _genState,
                onPressed: _generatePdf,
                shakeSignal: _shakeSignal,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final subjectReady = _data.department != null && _data.semester.isNotEmpty;

    int count(List<bool> flags) => flags.where((f) => f).length;
    final courseDone = count([
      _data.department != null,
      _data.semester.isNotEmpty,
      _data.subject != null,
    ]);
    final experimentDone = count([
      _exptNoCtrl.text.trim().isNotEmpty,
      _exptNameCtrl.text.trim().isNotEmpty,
      _data.dateOfExpt != null,
      _data.submissionDate != null,
    ]);
    final studentDone = count([
      _studentNameCtrl.text.trim().isNotEmpty,
      _studentIndexCtrl.text.trim().isNotEmpty,
      _boardRollCtrl.text.trim().isNotEmpty,
      _batchCtrl.text.trim().isNotEmpty,
    ]);
    final teacherDone = count([
      _teacherNameCtrl.text.trim().isNotEmpty,
      _teacherRoleCtrl.text.trim().isNotEmpty,
      _teacherDeptCtrl.text.trim().isNotEmpty,
    ]);
    final filled = courseDone + experimentDone + studentDone + teacherDone;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveDraft();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Create topsheet')),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProgressCard(
                      subject: _data.subject?.name,
                      filled: filled,
                      total: _requiredCount,
                    ),
                    AnimatedSize(
                      duration: _motion(context, Motion.standard),
                      curve: Motion.standardCurve,
                      alignment: Alignment.topCenter,
                      child: _showHint
                          ? Padding(
                              padding: const EdgeInsets.only(top: 14),
                              child: _HintBanner(
                                onDismiss: () {
                                  RecallStore.instance.markHintSeen();
                                  setState(() => _showHint = false);
                                },
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 20),
                    _Section(
                      title: 'Course',
                      icon: Icons.menu_book_rounded,
                      done: courseDone,
                      total: 3,
                      children: [
                        _Field(
                          label: 'Institute',
                          child: _PickerTile(
                            value: _data.instituteName.isEmpty
                                ? null
                                : _data.instituteName,
                            placeholder: 'Select institute',
                            onTap: _pickInstitute,
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['department'],
                          child: _Field(
                            label: 'Department',
                            child: _PickerTile(
                              value: _data.department == null
                                  ? null
                                  : '${_data.department!.longName} (${_data.department!.shortName})',
                              placeholder: 'Select department',
                              onTap: _pickDepartment,
                              errorText: _errors['department'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['semester'],
                          child: _Field(
                            label: 'Semester',
                            child: _PickerTile(
                              value: _data.semester.isEmpty
                                  ? null
                                  : _data.semester,
                              placeholder: 'Select semester',
                              onTap: _pickSemester,
                              errorText: _errors['semester'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['subject'],
                          child: _Field(
                            label: 'Subject',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _PickerTile(
                                  value: _data.subject?.name,
                                  placeholder: subjectReady
                                      ? 'Select subject'
                                      : 'Choose department and semester first',
                                  onTap: subjectReady && !_loadingSubjects
                                      ? _pickSubject
                                      : null,
                                  loading: _loadingSubjects,
                                  errorText: _errors['subject'],
                                ),
                                if (_subjectNote != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: _SubjectNote(
                                      message: _subjectNote!,
                                      onRetry: _subjectNoteRetry
                                          ? () =>
                                                _pickSubject(forceDownload: true)
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      title: 'Experiment',
                      icon: Icons.science_rounded,
                      done: experimentDone,
                      total: 4,
                      children: [
                        KeyedSubtree(
                          key: _fieldKeys['exptNo'],
                          child: _Field(
                            label: 'Experiment no.',
                            child: _TextInput(
                              controller: _exptNoCtrl,
                              hint: 'e.g. 3',
                              keyboardType: TextInputType.number,
                              errorText: _errors['exptNo'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['exptName'],
                          child: _Field(
                            label: 'Experiment name',
                            child: RecallTextField(
                              field: 'exptName',
                              label: 'Name of the experiment',
                              controller: _exptNameCtrl,
                              errorText: _errors['exptName'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['dateOfExpt'],
                          child: _Field(
                            label: 'Date of experiment',
                            child: _PickerTile(
                              value: _data.dateOfExpt == null
                                  ? null
                                  : _df.format(_data.dateOfExpt!),
                              placeholder: 'Select date',
                              trailing: Icons.calendar_today_rounded,
                              onTap: () => _pickDate(isSubmission: false),
                              errorText: _errors['dateOfExpt'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['submissionDate'],
                          child: _Field(
                            label: 'Submission date',
                            child: _PickerTile(
                              value: _data.submissionDate == null
                                  ? null
                                  : _df.format(_data.submissionDate!),
                              placeholder: 'Select date',
                              trailing: Icons.calendar_today_rounded,
                              onTap: () => _pickDate(isSubmission: true),
                              errorText: _errors['submissionDate'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      title: 'Student',
                      icon: Icons.school_rounded,
                      done: studentDone,
                      total: 4,
                      children: [
                        KeyedSubtree(
                          key: _fieldKeys['studentName'],
                          child: _Field(
                            label: 'Student name',
                            child: RecallTextField(
                              field: 'studentName',
                              label: 'Full name',
                              controller: _studentNameCtrl,
                              errorText: _errors['studentName'],
                              onSelected: _fillStudentProfile,
                            ),
                          ),
                        ),
                  KeyedSubtree(
                          key: _fieldKeys['studentIndex'],
                          child: _Field(
                            label: 'Student index',
                            child: RecallTextField(
                              field: 'studentIndex',
                              label: 'Roll or index',
                              controller: _studentIndexCtrl,
                              errorText: _errors['studentIndex'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['boardRoll'],
                          child: _Field(
                            label: 'Board roll',
                            child: _TextInput(
                              controller: _boardRollCtrl,
                              hint: 'Board roll number',
                              keyboardType: TextInputType.number,
                              errorText: _errors['boardRoll'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['batch'],
                          child: _Field(
                            label: 'Batch',
                            child: RecallTextField(
                              field: 'batch',
                              label: 'Batch or session',
                              controller: _batchCtrl,
                              errorText: _errors['batch'],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      title: 'Teacher',
                      icon: Icons.badge_rounded,
                      done: teacherDone,
                      total: 3,
                      children: [
                        KeyedSubtree(
                          key: _fieldKeys['teacherName'],
                          child: _Field(
                            label: 'Teacher name',
                            child: RecallTextField(
                              field: 'teacherName',
                              label: 'Full name',
                              controller: _teacherNameCtrl,
                              errorText: _errors['teacherName'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['teacherRole'],
                          child: _Field(
                            label: 'Teacher role',
                            child: RecallTextField(
                              field: 'teacherRole',
                              label: 'Designation',
                              controller: _teacherRoleCtrl,
                              errorText: _errors['teacherRole'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['teacherDepartment'],
                          child: _Field(
                            label: 'Teacher department',
                            child: RecallTextField(
                              field: 'teacherDepartment',
                              label: 'Department',
                              controller: _teacherDeptCtrl,
                              errorText: _errors['teacherDepartment'],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomBar(scheme),
          ],
        ),
      ),
    );
  }
}

/// Top card: the chosen subject (or a placeholder) and how much of the form
/// is filled in.
class _ProgressCard extends StatelessWidget {
  final String? subject;
  final int filled;
  final int total;

  const _ProgressCard({
    required this.subject,
    required this.filled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final complete = filled >= total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject ?? 'New topsheet',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleLarge,
                ),
              ),
              if (complete) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_circle_rounded, color: scheme.primary),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(
            complete
                ? 'Everything is filled in. Ready to generate.'
                : '$filled of $total required fields filled',
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: filled / total),
            duration: _motion(context, Motion.standard),
            curve: Motion.standardCurve,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: scheme.outlineVariant,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
/// A titled group of fields with a small "2/4" or "Done" indicator.
class _Section extends StatelessWidget {
  final String title;
  final IconData icon;
  final int done;
  final int total;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.icon,
    required this.done,
    required this.total,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final complete = done >= total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: scheme.primary),
              ),
              const SizedBox(width: 10),
              Text(title, style: textTheme.titleMedium),
              const Spacer(),
              if (complete) ...[
                Icon(Icons.check_circle_rounded, size: 16, color: scheme.primary),
                const SizedBox(width: 4),
                Text(
                  'Done',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ] else
                Text(
                  '$done/$total',
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 16),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Field with its name always visible above it.
class _Field extends StatelessWidget {
  final String label;
  final Widget child;

  const _Field({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final String? errorText;

  const _TextInput({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    textInputAction: TextInputAction.next,
    decoration: InputDecoration(hintText: hint, errorText: errorText),
  );
}

/// Tappable field that opens a picker. Shows a spinner while [loading] and
/// a red outline plus message when [errorText] is set.
class _PickerTile extends StatelessWidget {
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final bool loading;
  final String? errorText;
  final IconData trailing;

  const _PickerTile({
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.loading = false,
    this.errorText,
    this.trailing = Icons.keyboard_arrow_down_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final enabled = onTap != null || loading;
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          enabled: onTap != null,
          label: value ?? placeholder,
          excludeSemantics: true,
          onTap: onTap,
          child: Pressable(
            pressedScale: 0.99,
            onTap: onTap,
            child: AnimatedOpacity(
              opacity: enabled ? 1 : 0.55,
              duration: _motion(context, Motion.fast),
              child: AnimatedContainer(
                duration: _motion(context, Motion.fast),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: hasError ? scheme.error : Colors.transparent,
                    width: hasError ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value ?? placeholder,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge?.copyWith(
                          color: value == null
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (loading)
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      )
                    else
                      Icon(trailing, size: 20, color: scheme.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: textTheme.bodySmall?.copyWith(color: scheme.error),
            ),
          ),
      ],
    );
  }
}
/// Explains why the subject list is empty, with Retry when the cause may be
/// the connection.
class _SubjectNote extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _SubjectNote({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurface,
                height: 1.35,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// Full-width Generate button: idle -> spinner -> check, with a shake when
/// the form has errors.
class _GenerateButton extends StatefulWidget {
  final _GenState state;
  final VoidCallback onPressed;
  final int shakeSignal;

  const _GenerateButton({
    required this.state,
    required this.onPressed,
    required this.shakeSignal,
  });

  @override
  State<_GenerateButton> createState() => _GenerateButtonState();
}

class _GenerateButtonState extends State<_GenerateButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didUpdateWidget(_GenerateButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    final reduced =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        motionTierOf(context) == MotionTier.reduced;
    if (widget.shakeSignal != oldWidget.shakeSignal && !reduced) {
      _shake.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  static double _offsetFor(double t) {
    // 3 decaying half-cycles, settling back to 0 by t=1.
    if (t >= 1) return 0;
    final decay = 1 - t;
    return math.sin(t * math.pi * 3) * decay;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = switch (widget.state) {
      _GenState.idle => 'Generate PDF',
      _GenState.generating => 'Creating PDF\u2026',
      _GenState.done => 'Saved',
    };
    final icon = switch (widget.state) {
      _GenState.idle => Icon(
        Icons.picture_as_pdf_rounded,
        key: const ValueKey('idle'),
        size: 20,
        color: scheme.onPrimary,
      ),
      _GenState.generating => SizedBox(
        key: const ValueKey('spin'),
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: scheme.onPrimary,
        ),
      ),
      _GenState.done => Icon(
        Icons.check_rounded,
        key: const ValueKey('done'),
        size: 20,
        color: scheme.onPrimary,
      ),
    };
    return AnimatedBuilder(
      animation: _shake,
      builder: (context, child) => Transform.translate(
        offset: Offset(8 * _offsetFor(_shake.value), 0),
        child: child,
      ),
      child: Pressable(
        onTap: widget.state == _GenState.idle ? widget.onPressed : null,
        child: Container(
          height: 56,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: _motion(context, Motion.standard),
                reverseDuration: _motion(context, Motion.fast),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeOutCubic,
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: icon,
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: _motion(context, Motion.fast),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class _HintBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _HintBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 17,
                color: scheme.onPrimary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface,
                      height: 1.3,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Fill it once \u2014 ',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: 'generate, preview, and share in one flow.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Pressable(
              onTap: onDismiss,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PdfResultPage extends StatelessWidget {
  final Uint8List bytes;
  final String title;
  final String fileName;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const _PdfResultPage({
    required this.bytes,
    required this.title,
    required this.fileName,
    required this.onShare,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Ready to share',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) async => bytes,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              useActions: false,
              previewPageMargin: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              maxPageWidth: 680,
              scrollViewDecoration: BoxDecoration(color: scheme.surface),
              pdfPreviewPageDecoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              loadingWidget: Center(
                child: CircularProgressIndicator(color: scheme.primary),
              ),
              allowSharing: false,
              allowPrinting: false,
              pdfFileName: fileName,
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: scheme.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Pressable(
                        onTap: onSave,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: scheme.primary, width: 1.6),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.download_rounded, size: 19, color: scheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Save',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: Pressable(
                        onTap: onShare,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.share_rounded, size: 19, color: scheme.onPrimary),
                              const SizedBox(width: 8),
                              Text(
                                'Share',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: scheme.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
