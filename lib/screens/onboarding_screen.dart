import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion.dart';
import '../data/departments.dart';
import '../data/recall_store.dart';
import '../db/app_database.dart';
import '../models/institute.dart';
import '../services/remote_data_service.dart';
import '../widgets/pressable.dart';
import 'library_screen.dart';
import 'onboarding/onboarding_motion.dart';
import 'onboarding/steps/department_step.dart';
import 'onboarding/steps/institute_step.dart';
import 'onboarding/steps/semester_step.dart';
import 'onboarding/steps/text_step.dart';
import 'onboarding/steps/welcome_step.dart';
import 'onboarding/widgets/chunky_button.dart';
import 'onboarding/widgets/step_bar.dart';

/* Hallmark · genre: dark-premium · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _formCount = 5;

  final _pageController = PageController();
  int _step = 0; // 0 = welcome, 1..5 = form steps

  final _nameCtrl = TextEditingController();
  final _indexCtrl = TextEditingController();

  List<Institute>? _institutes;
  bool _loadingInstitutes = true;
  bool _institutesFailed = false;
  Institute? _selectedInstitute;
  Department? _selectedDept;
  String? _selectedSemester;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // The list fills itself in as soon as data is available (saved copy
    // first, live data when it arrives) — the screen never has to wait.
    RemoteDataService.instance.institutes.addListener(_onInstitutesUpdated);
    _loadInstitutes();
  }

  @override
  void dispose() {
    RemoteDataService.instance.institutes.removeListener(_onInstitutesUpdated);
    _pageController.dispose();
    _nameCtrl.dispose();
    _indexCtrl.dispose();
    super.dispose();
  }

  void _onInstitutesUpdated() {
    final data = RemoteDataService.instance.institutes.value;
    if (!mounted || data == null) return;
    final list = data.map(Institute.fromJson).toList();
    setState(() {
      _institutes = list;
      _institutesFailed = false;
      _loadingInstitutes = false;
      // Keep the user's pick if the live list still has it.
      final id = _selectedInstitute?.id;
      if (id != null) {
        final match = list.where((i) => i.id == id);
        if (match.isNotEmpty) {
          _selectedInstitute = match.first;
        } else {
          _selectedInstitute = null;
          _selectedDept = null;
        }
      }
    });
  }

  Future<void> _loadInstitutes() async {
    final data = await RemoteDataService.instance.fetchInstitutes();
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _institutesFailed = true;
        _loadingInstitutes = false;
      });
      return;
    }
    _onInstitutesUpdated();
  }

  Future<void> _retryInstitutes() async {
    setState(() {
      _loadingInstitutes = true;
      _institutesFailed = false;
    });
    await _loadInstitutes();
  }

  bool get _isWelcome => _step == 0;
  int get _formStep => _step - 1;

  bool get _canProceed {
    switch (_formStep) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty;
      case 1:
        return _indexCtrl.text.trim().isNotEmpty;
      case 2:
        return _selectedInstitute != null;
      case 3:
        return _selectedDept != null;
      case 4:
        return _selectedSemester != null;
      default:
        return false;
    }
  }

  Future<void> _goTo(int step) async {
    HapticFeedback.selectionClick();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
    final d = onbMotion(context, Motion.slow);
    if (d == Duration.zero) {
      _pageController.jumpToPage(step);
      return;
    }
    await _pageController.animateToPage(
      step,
      duration: d,
      curve: Motion.standardCurve,
    );
  }

  Future<void> _next() async {
    if (_isWelcome) {
      _goTo(1);
      return;
    }
    if (!_canProceed) return;
    if (_formStep == _formCount - 1) {
      await _finish();
      return;
    }
    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) return;
    _goTo(_step - 1);
  }

  void _onInstituteSelected(Institute inst) {
    final depts = inst.departments
        .map(departmentByCode)
        .whereType<Department>()
        .toList();
    setState(() {
      _selectedInstitute = inst;
      // Only one option? Pre-select it so the user just taps next.
      _selectedDept = depts.length == 1 ? depts.first : null;
    });
  }

  /// Saves whatever has been filled in. Anything left empty can be set later
  /// in Settings > Edit profile or on the Create screen.
  Future<void> _persist() async {
    final inst = _selectedInstitute;
    final dept = _selectedDept;
    await RecallStore.instance.saveProfile(
      name: _nameCtrl.text.trim(),
      studentIndex: _indexCtrl.text.trim(),
      instituteId: inst?.id ?? '',
      instituteName: inst?.name ?? '',
      instituteCode: inst?.code,
      instituteAddress: inst?.address,
      instituteWebsite: inst?.website,
      deptCode: dept?.code,
      semester: _selectedSemester ?? '',
    );
    // Downloads keep running in the background after this screen is gone.
    if (dept != null) {
      unawaited(AppDatabase.instance.syncSubjects(dept.code, force: true));
    }
  }

  void _openLibrary() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LibraryScreen()));
  }

  /// Skip keeps what the user already entered instead of throwing it away.
  Future<void> _skip() async {
    if (_saving) return;
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    final nothingEntered = _nameCtrl.text.trim().isEmpty &&
        _indexCtrl.text.trim().isEmpty &&
        _selectedInstitute == null;
    if (nothingEntered) {
      await RecallStore.instance.skipOnboarding();
    } else {
      await _persist();
    }
    if (!mounted) return;
    _openLibrary();
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await _persist();
    if (!mounted) return;
    _openLibrary();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      // System back walks one step back instead of closing the app.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_saving) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              if (!_isWelcome) _buildHeader(scheme),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    const WelcomeStep(),
                    TextStep(
                      title: "What's your name?",
                      subtitle: 'Printed under "Submitted by" on every Topsheet.',
                      hint: 'Your full name',
                      controller: _nameCtrl,
                      capitalization: TextCapitalization.words,
                      onChanged: () => setState(() {}),
                      onSubmit: _next,
                    ),
                    TextStep(
                      title: 'Your roll or index?',
                      subtitle: 'Any format works, like 123456 or CST-M-2217.',
                      hint: 'Roll or index',
                      controller: _indexCtrl,
                      capitalization: TextCapitalization.characters,
                      onChanged: () => setState(() {}),
                      onSubmit: _next,
                    ),
                    InstituteStep(
                      loading: _loadingInstitutes,
                      failed: _institutesFailed,
                      onRetry: _retryInstitutes,
                      institutes: _institutes ?? [],
                      selected: _selectedInstitute,
                      onSelect: _onInstituteSelected,
                    ),
                    DepartmentStep(
                      institute: _selectedInstitute,
                      selected: _selectedDept,
                      onSelect: (d) => setState(() => _selectedDept = d),
                    ),
                    SemesterStep(
                      selected: _selectedSemester,
                      onSelect: (s) => setState(() => _selectedSemester = s),
                    ),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Back',
              child: Pressable(
                onTap: _saving ? null : _back,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
                ),
              ),
            ),
            Expanded(
              child: StepBar(current: _formStep, total: _formCount),
            ),
            Semantics(
              button: true,
              label: 'Skip setup',
              child: Pressable(
                onTap: _saving ? null : _skip,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Text(
                    'SKIP',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final isLast = !_isWelcome && _formStep == _formCount - 1;
    final enabled = (_isWelcome || _canProceed) && !_saving;
    final label = _isWelcome ? 'Get started' : (isLast ? 'Finish' : 'Continue');
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: ChunkyButton(
        label: label,
        enabled: enabled,
        loading: _saving,
        onTap: _next,
      ),
    );
  }
}
