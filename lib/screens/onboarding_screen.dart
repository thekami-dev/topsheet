import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/motion.dart';
import '../data/departments.dart';
import '../data/recall_store.dart';
import '../db/app_database.dart';
import '../models/institute.dart';
import '../models/topsheet_data.dart' show semesters;
import '../services/remote_data_service.dart';
import '../widgets/pressable.dart';
import 'library_screen.dart';

/* Hallmark · genre: dark-premium · macrostructure: Workbench
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
    final d = _motion(context, Motion.slow);
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
                    const _WelcomeStep(),
                    _TextStep(
                      title: "What's your name?",
                      subtitle: 'Printed under "Submitted by" on every Topsheet.',
                      hint: 'Your full name',
                      controller: _nameCtrl,
                      capitalization: TextCapitalization.words,
                      onChanged: () => setState(() {}),
                      onSubmit: _next,
                    ),
                    _TextStep(
                      title: 'Your roll or index?',
                      subtitle: 'Any format works, like 123456 or CST-M-2217.',
                      hint: 'Roll or index',
                      controller: _indexCtrl,
                      capitalization: TextCapitalization.characters,
                      onChanged: () => setState(() {}),
                      onSubmit: _next,
                    ),
                    _InstituteStep(
                      loading: _loadingInstitutes,
                      failed: _institutesFailed,
                      onRetry: _retryInstitutes,
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
              child: _StepBar(current: _formStep, total: _formCount),
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
                    'Skip',
                    style: textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFooter(ColorScheme scheme) {
    final isLast = !_isWelcome && _formStep == _formCount - 1;
    final enabled = (_isWelcome || _canProceed) && !_saving;
    final label = _isWelcome ? 'Get started' : (isLast ? 'Finish' : 'Continue');
    final fg = enabled ? scheme.onPrimary : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: Pressable(
          onTap: enabled ? _next : null,
          child: AnimatedContainer(
            duration: _motion(context, Motion.standard),
            curve: Motion.standardCurve,
            height: 56,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? scheme.primary : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(28),
            ),
            child: _saving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: scheme.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: fg,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isLast
                            ? Icons.check_rounded
                            : Icons.arrow_forward_rounded,
                        color: fg,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Segmented progress bar: one segment per form step.
class _StepBar extends StatelessWidget {
  final int current;
  final int total;

  const _StepBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dur = _motion(context, Motion.standard);
    return Semantics(
      label: 'Step ${current + 1} of $total',
      child: Row(
        children: [
          for (var i = 0; i < total; i++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
                child: AnimatedContainer(
                  duration: dur,
                  curve: Motion.standardCurve,
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= current
                        ? scheme.primary
                        : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// First screen: just the greeting, nothing else.
class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: _motion(context, const Duration(milliseconds: 700)),
        curve: Motion.standardCurve,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - v)),
            child: child,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome to',
              style: textTheme.titleLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Topsheet',
              style: TextStyle(
                fontFamily: 'Pacifico',
                fontSize: 60,
                height: 1.25,
                color: scheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Big title, one calm line of explanation, then the step's content.
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
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Name / roll step: one large line with an underline, no box around it.
class _TextStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final String hint;
  final TextEditingController controller;
  final TextCapitalization capitalization;
  final VoidCallback onChanged;
  final VoidCallback onSubmit;

  const _TextStep({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.controller,
    required this.capitalization,
    required this.onChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _StepScaffold(
      title: title,
      subtitle: subtitle,
      child: Align(
        alignment: Alignment.topCenter,
        child: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: capitalization,
          textInputAction: TextInputAction.next,
          cursorColor: scheme.primary,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: scheme.primary, width: 2),
            ),
          ),
          onChanged: (_) => onChanged(),
          onSubmitted: (_) => onSubmit(),
        ),
      ),
    );
  }
}

/// Rounded search field shared by the institute and department lists.
class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pill = BorderRadius.circular(28);
    return TextField(
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search_rounded),
        border: OutlineInputBorder(
          borderRadius: pill,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: pill,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: pill,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// One list row: plain text with a hairline under it. The selected row turns
/// accent-coloured and shows a tick (its space is always reserved, so
/// nothing shifts).
class _PickRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PickRow({
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.99,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
              ),
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
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? scheme.primary : scheme.onSurface,
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
              const SizedBox(width: 12),
              SizedBox(
                width: 24,
                height: 24,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: _motion(context, Motion.fast),
                  child: Icon(
                    Icons.check_rounded,
                    color: scheme.primary,
                    size: 22,
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

String? _instituteSubtitle(Institute i) {
  final parts = <String>[
    if (i.code != null && i.code!.isNotEmpty) 'Code ${i.code}',
    if (i.address != null && i.address!.isNotEmpty) i.address!,
  ];
  return parts.isEmpty ? null : parts.join(' \u00b7 ');
}

/// Shown when institutes couldn't be loaded and nothing is saved yet.
class _LoadFailed extends StatelessWidget {
  final VoidCallback onRetry;

  const _LoadFailed({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 14),
            Text("Couldn't load institutes", style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Check your internet connection and try again.\n'
              'Or tap Skip and finish this later in Settings.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
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

class _InstituteStep extends StatefulWidget {
  final bool loading;
  final bool failed;
  final VoidCallback onRetry;
  final List<Institute> institutes;
  final Institute? selected;
  final ValueChanged<Institute> onSelect;

  const _InstituteStep({
    required this.loading,
    required this.failed,
    required this.onRetry,
    required this.institutes,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_InstituteStep> createState() => _InstituteStepState();
}

class _InstituteStepState extends State<_InstituteStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.institutes
        : widget.institutes.where((i) {
            return i.name.toLowerCase().contains(q) ||
                (i.code ?? '').toLowerCase().contains(q) ||
                (i.address ?? '').toLowerCase().contains(q);
          }).toList();

    final Widget body;
    if (widget.loading) {
      body = const _ListSkeleton();
    } else if (widget.failed) {
      body = _LoadFailed(onRetry: widget.onRetry);
    } else if (widget.institutes.isEmpty) {
      body = _NotListedNotice(scheme: scheme);
    } else {
      body = Column(
        children: [
          _SearchField(
            hint: 'Search institute',
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: filtered.length + 1,
              itemBuilder: (context, i) {
                if (i == filtered.length) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 16),
                    child: _NotListedNotice(scheme: scheme),
                  );
                }
                final inst = filtered[i];
                return _PickRow(
                  title: inst.name,
                  subtitle: _instituteSubtitle(inst),
                  selected: widget.selected?.id == inst.id,
                  onTap: () => widget.onSelect(inst),
                );
              },
            ),
          ),
        ],
      );
    }
    return _StepScaffold(
      title: 'Your institute?',
      subtitle: 'Goes in the header of every Topsheet.',
      child: body,
    );
  }
}

class _DepartmentStep extends StatefulWidget {
  final Institute? institute;
  final Department? selected;
  final ValueChanged<Department> onSelect;

  const _DepartmentStep({
    required this.institute,
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_DepartmentStep> createState() => _DepartmentStepState();
}

class _DepartmentStepState extends State<_DepartmentStep> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final all = (widget.institute?.departments ?? [])
        .map(departmentByCode)
        .whereType<Department>()
        .toList();
    // Only worth showing a search box when the list is long.
    final showSearch = all.length > 5;
    final q = showSearch ? _query.trim().toLowerCase() : '';
    final filtered = q.isEmpty
        ? all
        : all.where((d) {
            return d.longName.toLowerCase().contains(q) ||
                d.shortName.toLowerCase().contains(q) ||
                d.code.toString().contains(q);
          }).toList();
    return _StepScaffold(
      title: 'Your department?',
      subtitle: 'Loads the right subjects, saved for offline use.',
      child: all.isEmpty
          ? Text(
              'No departments listed for this institute yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            )
          : Column(
              children: [
                if (showSearch) ...[
                  _SearchField(
                    hint: 'Search department',
                    onChanged: (v) => setState(() => _query = v),
                  ),
                  const SizedBox(height: 8),
                ],
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No matches',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final d = filtered[i];
                            return _PickRow(
                              title: d.longName,
                              subtitle: '${d.shortName} \u00b7 Code ${d.code}',
                              selected: widget.selected?.code == d.code,
                              onTap: () => widget.onSelect(d),
                            );
                          },
                        ),
                ),
              ],
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
      subtitle: 'Pre-selected when you create a Topsheet. You can change it each time.',
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: semesters.map((s) {
            final isSelected = selected == s;
            return Semantics(
              button: true,
              selected: isSelected,
              label: 'Semester $s',
              excludeSemantics: true,
              onTap: () => onSelect(s),
              child: Pressable(
                onTap: () => onSelect(s),
                child: AnimatedContainer(
                  duration: _motion(context, Motion.fast),
                  curve: Motion.standardCurve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isSelected ? scheme.primary : scheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    s,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}


/// Placeholder rows shown while the institute list loads.
class _ListSkeleton extends StatefulWidget {
  const _ListSkeleton();

  @override
  State<_ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<_ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motion(context, Motion.slow) == Duration.zero) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bar = scheme.surfaceContainerHighest;
    return Semantics(
      label: 'Loading',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = Curves.easeInOut.transform(_c.value);
          return Opacity(
            opacity: 0.55 + 0.45 * t,
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          width: 200 + (i % 3) * 40.0,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 10,
                          width: 100,
                          decoration: BoxDecoration(
                            color: bar,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
