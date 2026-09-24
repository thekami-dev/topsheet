import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/departments.dart';
import '../models/topsheet_data.dart' show semesters;
import '../data/recall_store.dart';
import '../models/institute.dart';
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

  Institute? _institute;
  Department? _department;
  String? _semester;
  bool _loading = true;
  bool _saving = false;

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
    final institutes = await RemoteDataService.instance.fetchInstitutes();
    if (!mounted) return;
    if (profile != null) {
      _nameCtrl.text = profile['name'] as String? ?? '';
      _indexCtrl.text = profile['studentIndex'] as String? ?? '';
      _semester = (profile['semester'] as String?)?.isEmpty ?? true
          ? null
          : profile['semester'] as String;
      final deptCode = profile['deptCode'] as int?;
      if (deptCode != null) _department = departmentByCode(deptCode);
      final instId = profile['instituteId'] as String?;
      if (instId != null && institutes != null) {
        for (final json in institutes) {
          if (json['id'] == instId) {
            _institute = Institute.fromJson(json);
            break;
          }
        }
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _pickInstitute() async {
    final institutes = await RemoteDataService.instance.fetchInstitutes();
    if (institutes == null || !mounted) return;
    final list = institutes.map(Institute.fromJson).toList();
    final result = await showSearchablePicker<Institute>(
      context: context,
      title: 'Select Institute',
      items: list,
      labelOf: (i) => i.name,
    );
    if (result != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _institute = result;
        _department = null;
      });
    }
  }

  Future<void> _pickDepartment() async {
    if (_institute == null) return;
    final depts = _institute!.departments
        .map(departmentByCode)
        .whereType<Department>()
        .toList();
    final result = await showSearchablePicker<Department>(
      context: context,
      title: 'Select Department',
      items: depts,
      labelOf: (d) => '${d.shortName} \u00b7 ${d.longName}',
    );
    if (result != null) {
      HapticFeedback.selectionClick();
      setState(() => _department = result);
    }
  }

  Future<void> _pickSemester() async {
    final result = await showSearchablePicker<String>(
      context: context,
      title: 'Select Semester',
      items: semesters,
      labelOf: (s) => s,
    );
    if (result != null) {
      HapticFeedback.selectionClick();
      setState(() => _semester = result);
    }
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _indexCtrl.text.trim().isNotEmpty &&
      _institute != null &&
      _department != null &&
      _semester != null;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    await RecallStore.instance.saveProfile(
      name: _nameCtrl.text.trim(),
      studentIndex: _indexCtrl.text.trim(),
      instituteId: _institute!.id,
      instituteName: _institute!.name,
      deptCode: _department!.code,
      semester: _semester!,
    );
    unawaited(RemoteDataService.instance.fetchSubjects(_department!.code));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  'NAME',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                Text(
                  'STUDENT INDEX',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _indexCtrl,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                _FieldTile(
                  label: 'Institute',
                  value: _institute?.name,
                  onTap: _pickInstitute,
                ),
                const SizedBox(height: 12),
                _FieldTile(
                  label: 'Department',
                  value: _department == null
                      ? null
                      : '${_department!.shortName} \u00b7 ${_department!.longName}',
                  enabled: _institute != null,
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
                  height: 50,
                  child: Pressable(
                    onTap: _canSave && !_saving ? _save : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _canSave
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
                              'Save',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: _canSave
                                        ? Colors.white
                                        : scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FieldTile extends StatelessWidget {
  final String label;
  final String? value;
  final bool enabled;
  final VoidCallback onTap;

  const _FieldTile({
    required this.label,
    required this.value,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Pressable(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
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
                    value ?? 'Not selected',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: value == null ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
