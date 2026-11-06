import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../data/recall_store.dart';
import 'edit_profile_screen.dart';
import 'settings/about_screen.dart';
import 'settings/settings_widgets.dart';
import 'settings/social_screen.dart';
import 'themes_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Settings',
      children: [
        const SettingsSection('Profile'),
        SettingsTile(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedUserCircle, size: 24),
          title: 'Edit profile',
          subtitle: 'Name, index, institute, department, semester',
          onTap: () => _open(context, const EditProfileScreen()),
        ),
        const SettingsSection('Appearance'),
        SettingsTile(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedPalette, size: 24),
          title: 'Themes',
          subtitle: 'Light, dark and colour themes',
          onTap: () => _open(context, const ThemesScreen()),
        ),
        const SettingsSection('General'),
        SettingsTile(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 24),
          title: 'Clear remembered values',
          subtitle: 'Forgets saved teacher, student, and batch suggestions',
          onTap: () async {
            await RecallStore.instance.clearAll();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cleared remembered values')),
              );
            }
          },
        ),
        const SettingsSection('More'),
        SettingsTile(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 24),
          title: 'Social',
          subtitle: 'Discord, Instagram, Facebook, LinkedIn',
          onTap: () => _open(context, const SocialScreen()),
        ),
        SettingsTile(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedInformationCircle,
            size: 24,
          ),
          title: 'About',
          subtitle: 'Version, open source, rate and support',
          onTap: () => _open(context, const AboutScreen()),
        ),
      ],
    );
  }
}
