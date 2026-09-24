import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/departments.dart';
import '../models/topsheet_data.dart' show semesters;
import '../data/recall_store.dart';
import '../models/institute.dart';
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

  static const _steps = ['Name', 'Index', 'Institute', 'Department', 'Semester'];

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

  bool get _canProceed {
    switch (_step) {
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

  Future<void> _next() async {
    if (!_canProceed) return;
    HapticFeedback.selectionClick();
    if (_step == _steps.length - 1) {
      await _finish();
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) return;
    HapticFeedback.selectionClick();
    setState(() => _step--);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
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
    // Warm the subject cache for the picked department in the background —
    // this is what makes the app usable offline right after onboarding.
    unawaited(RemoteDataService.instance.fetchSubjects(_selectedDept!.code));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LibraryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  if (_step > 0)
                    Pressable(
                      onTap: _back,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Row(
                      children: List.generate(_steps.length, (i) {
                        final active = i <= _step;
                        return Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              right: i == _steps.length - 1 ? 0 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: active
                                  ? scheme.primary
                                  : scheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      }),
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
                height: 52,
                child: Pressable(
                  onTap: _canProceed && !_saving ? _next : null,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _canProceed
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
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
                            _step == _steps.length - 1 ? 'Get started' : 'Continue',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: _canProceed ? Colors.white : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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
          const SizedBox(height: 28),
          Expanded(child: child),
        ],
      ),
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
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        style: Theme.of(context).textTheme.headlineSmall,
        decoration: const InputDecoration(
          hintText: 'Your full name',
          border: InputBorder.none,
        ),
        onChanged: (_) => onChanged(),
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
      title: 'Your student index?',
      subtitle: 'This appears on your generated Topsheets too.',
      child: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        style: Theme.of(context).textTheme.headlineSmall,
        decoration: const InputDecoration(
          hintText: 'e.g. 123456',
          border: InputBorder.none,
        ),
        onChanged: (_) => onChanged(),
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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == institutes.length) {
                  return _NotListedNotice(scheme: scheme);
                }
                final inst = institutes[i];
                final isSelected = selected?.id == inst.id;
                return Pressable(
                  onTap: () => onSelect(inst),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? scheme.primary : scheme.outlineVariant,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            inst.name,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Can't find your institute?",
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Email info@thekami.tech or join our Discord and we\u2019ll add it.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : ListView.separated(
              itemCount: depts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = depts[i];
                final isSelected = selected?.code == d.code;
                return Pressable(
                  onTap: () => onSelect(d),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? scheme.primary : scheme.outlineVariant,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${d.shortName} \u00b7 ${d.longName}',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle_rounded, color: scheme.primary, size: 20),
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
      subtitle: "You can change this anytime when creating a Topsheet.",
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
                color: isSelected ? scheme.primary : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
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
