import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

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
import '../models/topsheet_data.dart';
import '../pdf/topsheet_pdf.dart';
import '../widgets/pressable.dart';
import '../widgets/recall_text_field.dart';
import '../widgets/searchable_picker.dart';
import 'settings_screen.dart';

enum _FabState { idle, generating, done }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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

  final _settingsButtonKey = GlobalKey();
  final _scrollController = ScrollController();

  _FabState _fabState = _FabState.idle;
  int _fabShakeSignal = 0;
  bool _showHint = false;
  final Map<String, String?> _errors = {};
  String? _lastSavedDraft;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreLastPicks().whenComplete(_restoreDraft);
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

  Map<String, dynamic> _draftJson() => {
    'deptCode': _data.department?.code,
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

    Department? dept;
    final deptCode = draft['deptCode'] as int?;
    if (deptCode != null) dept = departmentByCode(deptCode);
    Subject? subject;
    if (dept != null) {
      final subjectCode = draft['subjectCode'] as int?;
      if (subjectCode != null) {
        final subjects = await AppDatabase.instance.subjectsForDept(dept.code);
        for (final s in subjects) {
          if (s.code == subjectCode) {
            subject = s;
            break;
          }
        }
      }
    }

    if (!mounted) return;
    setState(() {
      if (dept != null) _data.department = dept;
      if (subject != null) _data.subject = subject;
      _data.semester = draft['semester'] as String? ?? _data.semester;
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
      if (submissionDate != null)
        _data.submissionDate = DateTime.tryParse(submissionDate);
    });
  }

  Future<void> _restoreLastPicks() async {
    final last = await RecallStore.instance.lastPicks();
    if (last == null) return;
    final (deptCode, subjectCode, semester) = last;
    final dept = departmentByCode(deptCode);
    if (dept == null) return;
    final subjects = await AppDatabase.instance.subjectsForDept(deptCode);
    Subject? subject;
    for (final s in subjects) {
      if (s.code == subjectCode) {
        subject = s;
        break;
      }
    }
    if (!mounted) return;
    setState(() {
      _data.department = dept;
      _data.subject = subject;
      _data.semester = semester;
    });
  }

  Future<void> _pickDepartment() async {
    final result = await showSearchablePicker<Department>(
      context: context,
      title: 'Select Department',
      items: btebDepartments,
      labelOf: (d) => '${d.shortName} — ${d.longName}',
      subtitleOf: (d) => 'Code ${d.code}',
    );
    if (result != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _data.department = result;
        _data.subject = null;
        _errors.remove('department');
      });
    }
  }

  Future<void> _pickSubject() async {
    if (_data.department == null) return;
    final subjects = await AppDatabase.instance.subjectsForDept(
      _data.department!.code,
    );
    if (subjects.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No seeded subjects for this department yet'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final result = await showSearchablePicker<Subject>(
      context: context,
      title: 'Select Subject',
      items: subjects,
      labelOf: (s) => s.name,
      subtitleOf: (s) => 'Code ${s.code} · Semester ${s.semester}',
    );
    if (result != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _data.subject = result;
        _errors.remove('subject');
      });
    }
  }

  Future<void> _pickDate({required bool isSubmission}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isSubmission) {
        _data.submissionDate = picked;
      } else {
        _data.dateOfExpt = picked;
      }
    });
  }

  void _syncTextFields() {
    _data.exptNo = int.tryParse(_exptNoCtrl.text);
    _data.exptName = _exptNameCtrl.text;
    _data.studentName = _studentNameCtrl.text;
    _data.studentIndex = _studentIndexCtrl.text;
    _data.boardRoll = int.tryParse(_boardRollCtrl.text);
    _data.batch = _batchCtrl.text;
    _data.teacherName = _teacherNameCtrl.text;
    _data.teacherRole = _teacherRoleCtrl.text;
    _data.teacherDepartment = _teacherDeptCtrl.text;
  }

  bool _validate() {
    _errors.clear();
    if (_data.department == null) _errors['department'] = 'Required';
    if (_data.subject == null) _errors['subject'] = 'Required';
    if (_exptNoCtrl.text.trim().isEmpty) _errors['exptNo'] = 'Required';
    if (_exptNameCtrl.text.trim().isEmpty) _errors['exptName'] = 'Required';
    if (_data.dateOfExpt == null) _errors['dateOfExpt'] = 'Required';
    if (_data.submissionDate == null) _errors['submissionDate'] = 'Required';
    if (_studentNameCtrl.text.trim().isEmpty)
      _errors['studentName'] = 'Required';
    if (_studentIndexCtrl.text.trim().isEmpty)
      _errors['studentIndex'] = 'Required';
    if (_boardRollCtrl.text.trim().isEmpty) _errors['boardRoll'] = 'Required';
    if (_data.semester.isEmpty) _errors['semester'] = 'Required';
    if (_batchCtrl.text.trim().isEmpty) _errors['batch'] = 'Required';
    if (_teacherNameCtrl.text.trim().isEmpty)
      _errors['teacherName'] = 'Required';
    if (_teacherRoleCtrl.text.trim().isEmpty)
      _errors['teacherRole'] = 'Required';
    if (_teacherDeptCtrl.text.trim().isEmpty)
      _errors['teacherDepartment'] = 'Required';
    return _errors.isEmpty;
  }

  Future<void> _generatePdf() async {
    _syncTextFields();
    setState(() {});
    if (!_validate()) {
      setState(() => _fabShakeSignal++);
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill in the highlighted fields')),
      );
      return;
    }
    setState(() => _fabState = _FabState.generating);
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
          : '${_data.exptName} — ${_data.subject?.name ?? ''}';
      await _saveToRecents(bytes, displayName.trim());
      await RecallStore.instance.clearDraft();

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

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _fabState = _FabState.done);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _fabState = _FabState.idle);
      if (mounted) await _showPdfSheet(bytes, displayName.trim());
    } finally {
      if (mounted && _fabState == _FabState.generating) {
        setState(() => _fabState = _FabState.idle);
      }
    }
  }

  Future<void> _saveToRecents(Uint8List bytes, String name) async {
    final dir = await getApplicationDocumentsDirectory();
    final topsheetsDir = Directory(p.join(dir.path, 'topsheets'));
    if (!await topsheetsDir.exists())
      await topsheetsDir.create(recursive: true);
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

  Future<void> _showPdfSheet(Uint8List bytes, String name) {
    final scheme = Theme.of(context).colorScheme;
    final title = name.isEmpty ? 'Topsheet' : name;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ColoredBox(
                  color: scheme.primaryContainer.withValues(alpha: 0.65),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onPrimaryContainer,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Generated successfully. Preview, then share instantly.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: scheme.onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Pressable(
                          onTap: () => _sharePdf(bytes, title),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.share_rounded,
                                  size: 18,
                                  color: scheme.onPrimary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Share',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: scheme.onPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 8, 8),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => _sharePdf(bytes, title),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.ios_share_rounded,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Pressable(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PdfPreview(
                build: (format) async => bytes,
                canChangeOrientation: false,
                canChangePageFormat: false,
                canDebug: false,
                scrollViewDecoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                ),
                pdfPreviewPageDecoration: BoxDecoration(
                  color: scheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.15),
                      blurRadius: 8,
                    ),
                  ],
                ),
                allowSharing: true,
                allowPrinting: false,
                pdfFileName: _pdfFileNameFor(title),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fillStudentProfile(String name) async {
    final profile = await RecallStore.instance.studentProfile(name);
    if (profile == null || !mounted) return;
    setState(() {
      _studentIndexCtrl.text =
          profile['studentIndex'] ?? _studentIndexCtrl.text;
      _boardRollCtrl.text = profile['boardRoll'] ?? _boardRollCtrl.text;
      _batchCtrl.text = profile['batch'] ?? _batchCtrl.text;
      _errors.remove('studentIndex');
      _errors.remove('boardRoll');
      _errors.remove('batch');
    });
  }

  void _openSettings() {
    final tier = motionTierOf(context);
    Navigator.of(
      context,
    ).push(_SettingsRoute(reduced: tier == MotionTier.reduced));
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Topsheet'),
            Text(
              'Generate clean, share-ready practical sheets',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0.08,
              ),
            ),
          ],
        ),
        actions: [
          Pressable(
            key: _settingsButtonKey,
            onTap: _openSettings,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.tune_rounded),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          const _AtmosphereBackground(),
          SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              children: [
                AnimatedSize(
                  duration: Motion.standard,
                  curve: Motion.standardCurve,
                  alignment: Alignment.topCenter,
                  child: _showHint
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _HintBanner(
                            onDismiss: () {
                              RecallStore.instance.markHintSeen();
                              setState(() => _showHint = false);
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                _Section(
                  title: 'Course',
                  children: [
                    _PickerField(
                      label: 'Department',
                      value: _data.department == null
                          ? null
                          : '${_data.department!.shortName} · ${_data.department!.longName}',
                      onTap: _pickDepartment,
                      errorText: _errors['department'],
                    ),
                    const SizedBox(height: 12),
                    _PickerField(
                      label: 'Subject',
                      value: _data.subject?.name,
                      enabled: _data.department != null,
                      onTap: _pickSubject,
                      errorText: _errors['subject'],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Experiment',
                  children: [
                    _TextInput(
                      controller: _exptNoCtrl,
                      label: 'Experiment no.',
                      keyboardType: TextInputType.number,
                      errorText: _errors['exptNo'],
                    ),
                    const SizedBox(height: 12),
                    RecallTextField(
                      field: 'exptName',
                      label: 'Experiment name',
                      controller: _exptNameCtrl,
                      errorText: _errors['exptName'],
                    ),
                    const SizedBox(height: 12),
                    _PickerField(
                      label: 'Date of experiment',
                      value: _data.dateOfExpt == null
                          ? null
                          : _df.format(_data.dateOfExpt!),
                      onTap: () => _pickDate(isSubmission: false),
                      errorText: _errors['dateOfExpt'],
                    ),
                    const SizedBox(height: 12),
                    _PickerField(
                      label: 'Submission date',
                      value: _data.submissionDate == null
                          ? null
                          : _df.format(_data.submissionDate!),
                      onTap: () => _pickDate(isSubmission: true),
                      errorText: _errors['submissionDate'],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Student',
                  children: [
                    RecallTextField(
                      field: 'studentName',
                      label: 'Student name',
                      controller: _studentNameCtrl,
                      errorText: _errors['studentName'],
                      onSelected: _fillStudentProfile,
                    ),
                    const SizedBox(height: 12),
                    RecallTextField(
                      field: 'studentIndex',
                      label: 'Student index',
                      controller: _studentIndexCtrl,
                      errorText: _errors['studentIndex'],
                    ),
                    const SizedBox(height: 12),
                    _TextInput(
                      controller: _boardRollCtrl,
                      label: 'Board roll',
                      keyboardType: TextInputType.number,
                      errorText: _errors['boardRoll'],
                    ),
                    const SizedBox(height: 12),
                    _PickerField(
                      label: 'Semester',
                      value: _data.semester.isEmpty ? null : _data.semester,
                      errorText: _errors['semester'],
                      onTap: () async {
                        final result = await showSearchablePicker<String>(
                          context: context,
                          title: 'Select Semester',
                          items: semesters,
                          labelOf: (s) => s,
                        );
                        if (result != null) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _data.semester = result;
                            _errors.remove('semester');
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    RecallTextField(
                      field: 'batch',
                      label: 'Batch',
                      controller: _batchCtrl,
                      errorText: _errors['batch'],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Teacher',
                  children: [
                    RecallTextField(
                      field: 'teacherName',
                      label: 'Teacher name',
                      controller: _teacherNameCtrl,
                      errorText: _errors['teacherName'],
                    ),
                    const SizedBox(height: 12),
                    RecallTextField(
                      field: 'teacherRole',
                      label: 'Teacher role',
                      controller: _teacherRoleCtrl,
                      errorText: _errors['teacherRole'],
                    ),
                    const SizedBox(height: 12),
                    RecallTextField(
                      field: 'teacherDepartment',
                      label: 'Teacher department',
                      controller: _teacherDeptCtrl,
                      errorText: _errors['teacherDepartment'],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _GenerateFab(
        state: _fabState,
        onPressed: _generatePdf,
        shakeSignal: _fabShakeSignal,
      ),
    );
  }
}

/// FAB that morphs idle → spinner → check, instead of swapping widgets flatly.
class _GenerateFab extends StatefulWidget {
  final _FabState state;
  final VoidCallback onPressed;
  final int shakeSignal;

  const _GenerateFab({
    required this.state,
    required this.onPressed,
    required this.shakeSignal,
  });

  @override
  State<_GenerateFab> createState() => _GenerateFabState();
}

class _GenerateFabState extends State<_GenerateFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didUpdateWidget(_GenerateFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shakeSignal != oldWidget.shakeSignal &&
        motionTierOf(context) != MotionTier.reduced) {
      _shakeController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
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
    final tier = motionTierOf(context);
    final label = switch (widget.state) {
      _FabState.idle => 'Generate & Share',
      _FabState.generating => 'Generating…',
      _FabState.done => 'Saved',
    };
    final icon = switch (widget.state) {
      _FabState.idle => const Icon(
        Icons.picture_as_pdf_outlined,
        key: ValueKey('idle'),
      ),
      _FabState.generating => const SizedBox(
        key: ValueKey('spin'),
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      ),
      _FabState.done => const Icon(Icons.check_rounded, key: ValueKey('done')),
    };
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) => Transform.translate(
        offset: Offset(8 * _offsetFor(_shakeController.value), 0),
        child: child,
      ),
      child: FloatingActionButton.extended(
        heroTag: 'generate',
        onPressed: widget.state == _FabState.idle ? widget.onPressed : null,
        icon: AnimatedSwitcher(
          duration: tier == MotionTier.reduced ? Motion.fast : Motion.standard,
          reverseDuration: Motion.fast,
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeOutCubic,
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: icon,
        ),
        label: AnimatedSwitcher(
          duration: Motion.fast,
          child: Text(label, key: ValueKey(label)),
        ),
      ),
    );
  }
}

/// Settings push that slides in from — and dismisses back toward — the
/// settings button's own position, so entry/exit share one path.
class _SettingsRoute extends PageRouteBuilder<void> {
  _SettingsRoute({required bool reduced})
    : super(
        transitionDuration: reduced ? Motion.fast : Motion.standard,
        reverseTransitionDuration: Motion.fast,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (reduced) {
            return FadeTransition(opacity: animation, child: child);
          }
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(opacity: curved, child: child),
          );
        },
      );
}

class _HintBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _HintBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primaryContainer.withValues(alpha: 0.85),
            scheme.tertiaryContainer.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
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
                      color: scheme.onPrimaryContainer,
                      height: 1.3,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Fill it once — ',
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
                  color: scheme.onPrimaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A plain grouped block, iOS-Settings style: a small muted caption sits
/// above an unadorned rounded container — no card border, no shadow, no
/// per-section icon or accent color.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            title.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.74),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.36),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }
}

class _TextInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final String? errorText;

  const _TextInput({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: keyboardType,
    decoration: InputDecoration(hintText: label, errorText: errorText),
  );
}

class _PickerField extends StatelessWidget {
  final String label;
  final String? value;
  final VoidCallback onTap;
  final bool enabled;
  final String? errorText;

  const _PickerField({
    required this.label,
    required this.value,
    required this.onTap,
    this.enabled = true,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) => Pressable(
    pressedScale: 0.99,
    onTap: enabled ? onTap : null,
    child: AnimatedOpacity(
      opacity: enabled ? 1 : 0.5,
      duration: Motion.fast,
      curve: Curves.easeOutCubic,
      child: InputDecorator(
        decoration: InputDecoration(hintText: label, errorText: errorText),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? 'Select…',
                style: TextStyle(
                  color: value == null
                      ? Theme.of(context).hintColor
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
            ),
          ],
        ),
      ),
    ),
  );
}

class _AtmosphereBackground extends StatelessWidget {
  const _AtmosphereBackground();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface,
            scheme.surfaceContainerLow.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -70,
            child: _BlurOrb(
              color: scheme.primary.withValues(alpha: 0.16),
              size: 260,
            ),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: _BlurOrb(
              color: scheme.tertiary.withValues(alpha: 0.13),
              size: 290,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _BlurOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    ),
  );
}
