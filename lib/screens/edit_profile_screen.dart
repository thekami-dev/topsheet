import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/departments.dart';
import '../data/recall_store.dart';
import '../db/app_database.dart';
import '../models/institute.dart';
import '../models/topsheet_data.dart' show semesters;
import '../services/remote_data_service.dart';
import '../widgets/pressable.dart';
import '../widgets/searchable_picker.dart';

/* Hallmark · genre: dark-premium · macrostructure: Long Document
 * design-system: design.md · designed-as-app
 */

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _indexCtrl = TextEditingController();

  // The institute is kept as plain fields (from the saved profile) so the
  // screen never has to wait for the network. [_institute] is the full
  // object, resolved in the background; it only supplies the department list.
  Institute? _institute;
  String? _instituteId;
  String? _instituteName;
  String? _instCode;
  String? _instAddress;
  String? _instWebsite;

  Department? _department;
  String? _semester;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _indexCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await RecallStore.instance.loadProfile();
    if (!mounted) return;
    if (profile != null) {
      _nameCtrl.text = profile['name'] as String? ?? '';
      _indexCtrl.text = profile['studentIndex'] as String? ?? '';
      final sem = profile['semester'] as String?;
      _semester = (sem == null || sem.isEmpty) ? null : sem;
      final deptCode = profile['deptCode'] as int?;
      if (deptCode != null) _department = departmentByCode(deptCode);
      _instituteId = profile['instituteId'] as String?;
      _instituteName = profile['instituteName'] as String?;
      _instCode = profile['instituteCode'] as String?;
      _instAddress = profile['instituteAddress'] as String?;
      _instWebsite = profile['instituteWebsite'] as String?;
    }
    setState(() => _loading = false);
    unawaited(_resolveInstitute());
  }

  /// Finds the full institute object (for its department list) without
  /// blocking the screen.
  Future<void> _resolveInstitute() async {
    final id = _instituteId;
    if (id == null) return;
    final list = await RemoteDataService.instance.fetchInstitutes();
    if (!mounted || list == null || _instituteId != id) return;
    for (final json in list) {
      if (json['id'] == id) {
        setState(() => _institute = Institute.fromJson(json));
        return;
      }
    }
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
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
      _institute = result;
      _instituteId = result.id;
      _instituteName = result.name;
      _instCode = result.code;
      _instAddress = result.address;
      _instWebsite = result.website;
      // Keep the department when the new institute offers it too.
      final keep =
          _department != null && result.departments.contains(_department!.code);
      if (!keep) _department = null;
      _dirty = true;
    });
  }

  Future<void> _pickDepartment() async {
    if (_instituteId == null) return;
    // Until the institute object is resolved (offline, no cache), fall back
    // to the full list instead of doing nothing.
    final depts = _institute == null
        ? btebDepartments
        : _institute!.departments
              .map(departmentByCode)
              .whereType<Department>()
              .toList();
    final result = await showSearchablePicker<Department>(
      context: context,
      title: 'Select Department',
      items: depts,
      labelOf: (d) => '${d.longName} (${d.shortName})',
      subtitleOf: (d) => 'Code ${d.code}',
    );
    if (result == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      _department = result;
      _dirty = true;
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
      _semester = result;
      _dirty = true;
    });
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _indexCtrl.text.trim().isNotEmpty &&
      _instituteId != null &&
      _instituteName != null &&
      _department != null &&
      _semester != null;

  Future<void> _save() async {
    if (!_canSave || _saving) return;
    setState(() => _saving = true);
    await RecallStore.instance.saveProfile(
      name: _nameCtrl.text.trim(),
      studentIndex: _indexCtrl.text.trim(),
      instituteId: _instituteId!,
      instituteName: _instituteName!,
      instituteCode: _instCode,
      instituteAddress: _instAddress,
      instituteWebsite: _instWebsite,
      deptCode: _department!.code,
      semester: _semester!,
    );
    unawaited(AppDatabase.instance.syncSubjects(_department!.code, force: true));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.of(context).pop();
  }

  Future<void> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('Your edits have not been saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  32 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                children: [
                  Text('NAME', style: labelStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) {
                      _touch();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('STUDENT INDEX', style: labelStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _indexCtrl,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 123456 or CST-M-2217',
                    ),
                    onChanged: (_) {
                      _touch();
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  _FieldTile(
                    label: 'Institute',
                    value: _instituteName,
                    onTap: _pickInstitute,
                  ),
                  const SizedBox(height: 12),
                  _FieldTile(
                    label: 'Department',
                    value: _department == null
                        ? null
                        : '${_department!.shortName} \u00b7 ${_department!.longName}',
                    placeholder: _instituteId == null
                        ? 'Select an institute first'
                        : 'Not selected',
                    enabled: _instituteId != null,
                    onTap: _pickDepartment,
                  ),
                  const SizedBox(height: 12),
                  _FieldTile(
                    label: 'Semester',
                    value: _semester,
                    onTap: _pickSemester,
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Pressable(
                      onTap: _canSave && !_saving ? _save : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _canSave
                              ? scheme.primary
                              : scheme.surfaceContainerHighest,
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
                            : Text(
                                'Save',
                                style: textTheme.labelLarge?.copyWith(
                                  color: _canSave
                                      ? scheme.onPrimary
                                      : scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (!_canSave)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Fill in every field to save.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodySmall?.copyWith(
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

class _FieldTile extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final bool enabled;
  final VoidCallback onTap;

  const _FieldTile({
    required this.label,
    required this.value,
    this.placeholder = 'Not selected',
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label, ${value ?? placeholder}',
      excludeSemantics: true,
      onTap: enabled ? onTap : null,
      child: Pressable(
        onTap: enabled ? onTap : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.55,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        value ?? placeholder,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: value == null ? scheme.onSurfaceVariant : null,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
