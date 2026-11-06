import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
import '../widgets/recall_text_field.dart';
import '../widgets/searchable_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import 'create/create_widgets.dart';
import 'create/generate_button.dart';
import 'create/pdf_result_page.dart';
import 'profile/picker_field.dart';

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

  GenState _genState = GenState.idle;
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
    if (_genState != GenState.idle) return;
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
    setState(() => _genState = GenState.generating);
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
      setState(() => _genState = GenState.done);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _genState = GenState.idle);
      if (mounted) await _showPdfSheet(bytes, displayName.trim());
    } catch (_) {
      if (mounted) _toast("Couldn't create the PDF. Please try again.");
    } finally {
      if (mounted && _genState == GenState.generating) {
        setState(() => _genState = GenState.idle);
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
      MaterialPageRoute(
        builder: (_) => PdfResultPage(
          bytes: bytes,
          title: title,
          fileName: _pdfFileNameFor(title),
          onShare: () => _sharePdf(bytes, title),
          onSave: () => _savePdf(bytes, title),
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
              color: scheme.surface,
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                12 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: GenerateButton(
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
                    CreateHeader(
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
                              child: HintBanner(
                                onDismiss: () {
                                  RecallStore.instance.markHintSeen();
                                  setState(() => _showHint = false);
                                },
                              ),
                            )
                          : const SizedBox(width: double.infinity),
                    ),
                    const SizedBox(height: 28),
                    FormSection(
                      title: 'Course',
                      done: courseDone,
                      total: 3,
                      children: [
                        PickerField(
                          label: 'Institute',
                          value: _data.instituteName.isEmpty
                              ? null
                              : _data.instituteName,
                          onTap: _pickInstitute,
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['department'],
                          child: PickerField(
                            label: 'Department',
                            value: _data.department == null
                                ? null
                                : '${_data.department!.longName} (${_data.department!.shortName})',
                            errorText: _errors['department'],
                            onTap: _pickDepartment,
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['semester'],
                          child: PickerField(
                            label: 'Semester',
                            value: _data.semester.isEmpty
                                ? null
                                : _data.semester,
                            errorText: _errors['semester'],
                            onTap: _pickSemester,
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['subject'],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              PickerField(
                                label: 'Subject',
                                value: _data.subject?.name,
                                enabled: subjectReady,
                                disabledHint:
                                    'Choose department and semester first',
                                loading: _loadingSubjects,
                                errorText: _errors['subject'],
                                onTap: _pickSubject,
                              ),
                              if (_subjectNote != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: SubjectNote(
                                    message: _subjectNote!,
                                    onRetry: _subjectNoteRetry
                                        ? () => _pickSubject(forceDownload: true)
                                        : null,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FormSection(
                      title: 'Experiment',
                      done: experimentDone,
                      total: 4,
                      children: [
                        KeyedSubtree(
                          key: _fieldKeys['exptNo'],
                          child: TextField(
                            controller: _exptNoCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Experiment no.',
                              hintText: 'e.g. 3',
                              errorText: _errors['exptNo'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['exptName'],
                          child: RecallTextField(
                            field: 'exptName',
                            label: 'Experiment name',
                            controller: _exptNameCtrl,
                            errorText: _errors['exptName'],
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['dateOfExpt'],
                          child: PickerField(
                            label: 'Date of experiment',
                            value: _data.dateOfExpt == null
                                ? null
                                : _df.format(_data.dateOfExpt!),
                            icon: HugeIcons.strokeRoundedCalendar01,
                            errorText: _errors['dateOfExpt'],
                            onTap: () => _pickDate(isSubmission: false),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['submissionDate'],
                          child: PickerField(
                            label: 'Submission date',
                            value: _data.submissionDate == null
                                ? null
                                : _df.format(_data.submissionDate!),
                            icon: HugeIcons.strokeRoundedCalendar01,
                            errorText: _errors['submissionDate'],
                            onTap: () => _pickDate(isSubmission: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FormSection(
                      title: 'Student',
                      done: studentDone,
                      total: 4,
                      children: [
                        KeyedSubtree(
                          key: _fieldKeys['studentName'],
                          child: RecallTextField(
                            field: 'studentName',
                            label: 'Student name',
                            controller: _studentNameCtrl,
                            errorText: _errors['studentName'],
                            onSelected: _fillStudentProfile,
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['studentIndex'],
                          child: RecallTextField(
                            field: 'studentIndex',
                            label: 'Student index',
                            controller: _studentIndexCtrl,
                            errorText: _errors['studentIndex'],
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['boardRoll'],
                          child: TextField(
                            controller: _boardRollCtrl,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'Board roll',
                              errorText: _errors['boardRoll'],
                            ),
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['batch'],
                          child: RecallTextField(
                            field: 'batch',
                            label: 'Batch',
                            controller: _batchCtrl,
                            errorText: _errors['batch'],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    FormSection(
                      title: 'Teacher',
                      done: teacherDone,
                      total: 3,
                      children: [
                        KeyedSubtree(
                          key: _fieldKeys['teacherName'],
                          child: RecallTextField(
                            field: 'teacherName',
                            label: 'Teacher name',
                            controller: _teacherNameCtrl,
                            errorText: _errors['teacherName'],
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['teacherRole'],
                          child: RecallTextField(
                            field: 'teacherRole',
                            label: 'Teacher role',
                            controller: _teacherRoleCtrl,
                            errorText: _errors['teacherRole'],
                          ),
                        ),
                        KeyedSubtree(
                          key: _fieldKeys['teacherDepartment'],
                          child: RecallTextField(
                            field: 'teacherDepartment',
                            label: 'Teacher department',
                            controller: _teacherDeptCtrl,
                            errorText: _errors['teacherDepartment'],
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
