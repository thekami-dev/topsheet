import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/departments.dart';
import '../data/recall_store.dart';
import '../models/institute.dart';
import '../models/topsheet_data.dart' show semesters;
import '../services/remote_data_service.dart';
import '../widgets/pressable.dart';
import 'library_screen.dart';

/* Hallmark · genre: dark-premium · macrostructure: Workbench
 * design-system: design.md · designed-as-app
 */

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  final _nameCtrl = TextEditingController();
  final _indexCtrl = TextEditingController();

  List<Institute>? _institutes;
  bool _loadingInstitutes = true;
  Institute? _selectedInstitute;
  Department? _selectedDept;
  String? _selectedSemester;
  bool _saving = false;

  // Step 0 is the welcome screen — not part of the progress bar/skip flow.
  static const _formSteps = ['Name', 'Index', 'Institute', 'Department', 'Semester'];

  @override
  void initState() {
    super.initState();
    _loadInstitutes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    _indexCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInstitutes() async {
    final data = await RemoteDataService.instance.fetchInstitutes();
    if (!mounted) return;
    setState(() {
      _institutes = data?.map(Institute.fromJson).toList() ?? [];
      _loadingInstitutes = false;
    });
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
    setState(() => _step = step);
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_isWelcome) {
      _goTo(1);
      return;
    }
    if (!_canProceed) return;
    if (_formStep == _formSteps.length - 1) {
      await _finish();
      return;
    }
    _goTo(_step + 1);
  }

  void _back() {
    if (_step == 0) return;
    _goTo(_step - 1);
  }

  Future<void> _skip() async {
    HapticFeedback.mediumImpact();
    await RecallStore.instance.skipOnboarding();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LibraryScreen()));
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    await RecallStore.instance.saveProfile(
      name: _nameCtrl.text.trim(),
      studentIndex: _indexCtrl.text.trim(),
      instituteId: _selectedInstitute!.id,
      instituteName: _selectedInstitute!.name,
      deptCode: _selectedDept!.code,
      semester: _selectedSemester!,
    );
    unawaited(RemoteDataService.instance.fetchSubjects(_selectedDept!.code));
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LibraryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (!_isWelcome)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Pressable(
                      onTap: _back,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 14),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: scheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(_formSteps.length, (i) {
                          final active = i <= _formStep;
                          return Expanded(
                            child: Container(
                              height: 3,
                              margin: EdgeInsets.only(
                                right: i == _formSteps.length - 1 ? 0 : 6,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? scheme.primary
                                    : scheme.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Pressable(
                      onTap: _skip,
                      child: Text(
                        'Skip',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomeStep(onSkip: _skip),
                  _NameStep(controller: _nameCtrl, onChanged: () => setState(() {})),
                  _IndexStep(controller: _indexCtrl, onChanged: () => setState(() {})),
                  _InstituteStep(
                    loading: _loadingInstitutes,
                    institutes: _institutes ?? [],
                    selected: _selectedInstitute,
                    onSelect: (inst) => setState(() {
                      _selectedInstitute = inst;
                      _selectedDept = null;
                    }),
                  ),
                  _DepartmentStep(
                    institute: _selectedInstitute,
                    selected: _selectedDept,
                    onSelect: (d) => setState(() => _selectedDept = d),
                  ),
                  _SemesterStep(
                    selected: _selectedSemester,
                    onSelect: (s) => setState(() => _selectedSemester = s),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: Pressable(
                  onTap: (_isWelcome || _canProceed) && !_saving ? _next : null,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (_isWelcome || _canProceed)
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _isWelcome
                                ? 'Get started'
                                : (_formStep == _formSteps.length - 1
                                      ? 'Finish'
                                      : 'Continue'),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: (_isWelcome || _canProceed)
                                      ? Colors.white
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
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
}

class _WelcomeStep extends StatelessWidget {
  final VoidCallback onSkip;
  const _WelcomeStep({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Welcome to\nTopsheet',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 14),
          Text(
            'A quick setup so your details are ready every time you '
            'generate a practical sheet. Takes less than a minute.',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 28),
          Pressable(
            onTap: onSkip,
            child: Text(
              'Skip for now',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Shared minimalist text-input look — underline only, no box/border, so it
/// reads as a real form rather than a boxed "AI-generated" widget.
class _UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback onChanged;

  const _UnderlineField({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      autofocus: true,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: Theme.of(
        context,
      ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      cursorColor: scheme.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontWeight: FontWeight.w600,
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: UnderlineInputBorder(borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _NameStep({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "What's your name?",
      subtitle: "We'll use this on every Topsheet you generate.",
      child: _UnderlineField(
        controller: controller,
        hint: 'Your full name',
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,
      ),
    );
  }
}

class _IndexStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;

  const _IndexStep({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Your roll or index?',
      subtitle:
          'Any format works \u2014 numbers, or something like CST-M-2217.',
      child: _UnderlineField(
        controller: controller,
        hint: 'e.g. 123456 or CST-M-2217',
        textCapitalization: TextCapitalization.characters,
        onChanged: onChanged,
      ),
    );
  }
}

class _InstituteStep extends StatelessWidget {
  final bool loading;
  final List<Institute> institutes;
  final Institute? selected;
  final ValueChanged<Institute> onSelect;

  const _InstituteStep({
    required this.loading,
    required this.institutes,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StepScaffold(
      title: 'Your institute?',
      subtitle: 'We use this to load the right subjects for you.',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : institutes.isEmpty
          ? _NotListedNotice(scheme: scheme)
          : ListView.separated(
              itemCount: institutes.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                if (i == institutes.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _NotListedNotice(scheme: scheme),
                  );
                }
                final inst = institutes[i];
                final isSelected = selected?.id == inst.id;
                return Pressable(
                  onTap: () => onSelect(inst),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            inst.name,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? scheme.primary : null,
                                ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded, color: scheme.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
class _NotListedNotice extends StatelessWidget {
  final ColorScheme scheme;
  const _NotListedNotice({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.5),
        children: const [
          TextSpan(text: "Can't find your institute? Email "),
          TextSpan(
            text: 'info@thekami.tech',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: ' or join our Discord and we\u2019ll add it.'),
        ],
      ),
    );
  }
}

class _DepartmentStep extends StatelessWidget {
  final Institute? institute;
  final Department? selected;
  final ValueChanged<Department> onSelect;

  const _DepartmentStep({
    required this.institute,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final depts = (institute?.departments ?? [])
        .map(departmentByCode)
        .whereType<Department>()
        .toList();
    return _StepScaffold(
      title: 'Your department?',
      subtitle: 'Subjects for this department will be ready offline too.',
      child: depts.isEmpty
          ? Text(
              'No departments listed for this institute yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : ListView.separated(
              itemCount: depts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final d = depts[i];
                final isSelected = selected?.code == d.code;
                return Pressable(
                  onTap: () => onSelect(d),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${d.shortName} \u00b7 ${d.longName}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected ? scheme.primary : null,
                                ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_rounded, color: scheme.primary, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _SemesterStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;

  const _SemesterStep({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StepScaffold(
      title: 'Current semester?',
      subtitle: 'You can change this anytime when creating a Topsheet.',
      child: GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
        children: semesters.map((s) {
          final isSelected = selected == s;
          return Pressable(
            onTap: () => onSelect(s),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? scheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? scheme.primary : scheme.outlineVariant,
                ),
              ),
              child: Text(
                s,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isSelected ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
