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
  int _step = 0; // 0 = welcome, 1..5 = form steps

  final _nameCtrl = TextEditingController();
  final _indexCtrl = TextEditingController();

  List<Institute>? _institutes;
  bool _loadingInstitutes = true;
  Institute? _selectedInstitute;
  Department? _selectedDept;
  String? _selectedSemester;
  bool _saving = false;

  static const _formSteps = [
    'Name',
    'Index',
    'Institute',
    'Department',
    'Semester',
  ];

  // Shown by the "?" button: why each step asks what it asks.
  static const _helpTitles = [
    'Why we ask your name',
    'Why we ask your roll or index',
    'Why we ask your institute',
    'Why we ask your department',
    'Why we ask your semester',
  ];

  static const _helpBodies = [
    'Printed under "Submitted by" on every Topsheet, so you never retype it. '
        'It stays on your device. You can change it anytime in '
        'Settings > Edit profile.',
    'Printed next to your name on the Topsheet and pre-filled whenever you '
        'create one. Any format works.',
    'The institute name, code, address and website go in the header of every '
        'Topsheet. It also decides which departments you can pick next.',
    'Used to load the right subjects for you. They are downloaded once and '
        'then work offline.',
    'Pre-selects your semester when you create a Topsheet. You can still '
        'change it each time.',
  ];

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
    FocusManager.instance.primaryFocus?.unfocus();
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
      instituteCode: _selectedInstitute!.code,
      instituteAddress: _selectedInstitute!.address,
      instituteWebsite: _selectedInstitute!.website,
      deptCode: _selectedDept!.code,
      semester: _selectedSemester!,
    );
    unawaited(RemoteDataService.instance.fetchSubjects(_selectedDept!.code));
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LibraryScreen()));
  }

  void _showHelp() {
    HapticFeedback.selectionClick();
    final i = _formStep;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_helpTitles[i], style: theme.textTheme.titleLarge),
                const SizedBox(height: 10),
                Text(
                  _helpBodies[i],
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(scheme),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  const _WelcomeStep(),
                  _NameStep(
                    controller: _nameCtrl,
                    onChanged: () => setState(() {}),
                    onSubmit: _next,
                  ),
                  _IndexStep(
                    controller: _indexCtrl,
                    onChanged: () => setState(() {}),
                    onSubmit: _next,
                  ),
                  _InstituteStep(
                    loading: _loadingInstitutes,
                    institutes: _institutes ?? [],
                    selected: _selectedInstitute,
                    onSelect: _onInstituteSelected,
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
            _buildFooter(scheme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            if (!_isWelcome)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Text(
                  '${_formStep + 1}/${_formSteps.length}',
                  style: textTheme.labelLarge?.copyWith(
                    color: scheme.onSurface,
                  ),
                ),
              ),
            const Spacer(),
            if (!_isWelcome)
              Semantics(
                button: true,
                label: 'Why we ask this',
                child: Pressable(
                  onTap: _showHelp,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                      Icons.help_outline_rounded,
                      color: scheme.onSurfaceVariant,
                      size: 22,
                    ),
                  ),
                ),
              ),
            Pressable(
              onTap: _saving ? null : _skip,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Text(
                  'Skip',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(ColorScheme scheme) {
    final isLast = !_isWelcome && _formStep == _formSteps.length - 1;
    final enabled = (_isWelcome || _canProceed) && !_saving;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Row(
        children: [
          if (!_isWelcome)
            Semantics(
              button: true,
              label: 'Back',
              child: Pressable(
                onTap: _saving ? null : _back,
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: scheme.onSurface),
                ),
              ),
            ),
          const Spacer(),
          Semantics(
            button: true,
            label: isLast ? 'Finish' : 'Next',
            child: Pressable(
              onTap: enabled ? _next : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 72,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enabled
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
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
                    : Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: enabled
                            ? Colors.white
                            : scheme.onSurfaceVariant,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 36, 28, 16),
      children: [
        Text('Welcome to\nTopsheet', style: textTheme.displaySmall),
        const SizedBox(height: 14),
        Text(
          'Make a clean, share-ready practical sheet in a few taps. '
          'Set up once, and your details are ready every time.',
          style: textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        const _FeatureRow(
          icon: Icons.bolt_rounded,
          title: 'Sheets in seconds',
          body: 'Pick the subject, fill in the details, get a PDF.',
        ),
        const _FeatureRow(
          icon: Icons.history_rounded,
          title: 'Remembers for you',
          body: 'Name, batch and teacher are suggested next time.',
        ),
        const _FeatureRow(
          icon: Icons.cloud_off_rounded,
          title: 'Works offline',
          body: 'Subjects are saved for offline use, and your sheets stay on '
              'your phone.',
        ),
        const SizedBox(height: 8),
        Text(
          'Setup is 5 quick questions and takes under a minute.',
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: scheme.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
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
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
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
          const SizedBox(height: 24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Same filled + bordered look as the fields in the rest of the app
/// (comes from the app-wide InputDecorationTheme).
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextCapitalization textCapitalization;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _InputField({
    required this.controller,
    required this.hint,
    this.textCapitalization = TextCapitalization.none,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.topCenter,
      child: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: textCapitalization,
        textInputAction: TextInputAction.next,
        cursorColor: scheme.primary,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontSize: 18),
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        onChanged: (_) => onChanged(),
        onSubmitted: (_) => onSubmit(),
      ),
    );
  }
}

class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _NameStep({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: "What's your name?",
      subtitle: "We'll use this on every Topsheet you generate.",
      child: _InputField(
        controller: controller,
        hint: 'Your full name',
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,
        onSubmit: onSubmit,
      ),
    );
  }
}

class _IndexStep extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _IndexStep({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Your roll or index?',
      subtitle: 'Any format works \u2014 numbers, or something like CST-M-2217.',
      child: _InputField(
        controller: controller,
        hint: 'e.g. 123456 or CST-M-2217',
        textCapitalization: TextCapitalization.characters,
        onChanged: onChanged,
        onSubmit: onSubmit,
      ),
    );
  }
}

/// Selectable card used for institute and department lists.
class _OptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primary.withValues(alpha: 0.10)
              : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? scheme.secondary : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 12),
              Icon(Icons.check_circle_rounded, color: scheme.primary, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}

String? _instituteSubtitle(Institute i) {
  final parts = <String>[
    if (i.code != null && i.code!.isNotEmpty) 'Code ${i.code}',
    if (i.address != null && i.address!.isNotEmpty) i.address!,
  ];
  return parts.isEmpty ? null : parts.join(' \u00b7 ');
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
      subtitle: 'Shown in the header of your Topsheet.',
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : institutes.isEmpty
          ? _NotListedNotice(scheme: scheme)
          : ListView.separated(
              itemCount: institutes.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == institutes.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: _NotListedNotice(scheme: scheme),
                  );
                }
                final inst = institutes[i];
                return _OptionCard(
                  title: inst.name,
                  subtitle: _instituteSubtitle(inst),
                  selected: selected?.id == inst.id,
                  onTap: () => onSelect(inst),
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.5,
        ),
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
      subtitle: 'Subjects for it are saved for offline use too.',
      child: depts.isEmpty
          ? Text(
              'No departments listed for this institute yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : ListView.separated(
              itemCount: depts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final d = depts[i];
                return _OptionCard(
                  title: d.longName,
                  subtitle: '${d.shortName} \u00b7 Code ${d.code}',
                  selected: selected?.code == d.code,
                  onTap: () => onSelect(d),
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
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
