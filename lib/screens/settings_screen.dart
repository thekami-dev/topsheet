import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/recall_store.dart';
import '../main.dart' show applyThemeMode, themeModeNotifier;
import '../services/install_source_service.dart';
import '../services/rate_prompt_service.dart';
import '../widgets/pressable.dart';
import 'edit_profile_screen.dart';

/* Hallmark · genre: dark-premium · macrostructure: Long Document
 * design-system: design.md · designed-as-app
 */

const _kGithubRepo = 'https://github.com/thekami-dev/topsheet';
const _kGithubOrg = 'https://github.com/thekami-dev';
const _kDiscord = 'https://www.thekami.tech/discord/';
const _kLinkedIn = 'https://www.linkedin.com/company/thekamiofficial';
const _kInstagram = 'https://www.instagram.com/thekami_official';
const _kFacebook = 'https://www.facebook.com/thekamidev/';
const _kSupport = 'https://www.supportkori.com/thekami';
const _kThekamiSite = 'https://www.thekami.tech';
const _kThekamiLogo = 'assets/images/thekami_logo.png';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;
  bool? _isPlayStore;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _packageInfo = info);
    });
    InstallSourceService.instance.isFromPlayStore().then((isPlayStore) {
      if (mounted) setState(() => _isPlayStore = isPlayStore);
    });
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  void _showAbout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final version = _packageInfo != null
            ? 'v${_packageInfo!.version} (${_packageInfo!.buildNumber})'
            : '…';
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Icon(
                        Icons.description_outlined,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Topsheet',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            version,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Generate clean, share-ready practical sheets for course '
                  'submissions — pick a department and subject, fill in '
                  'student and teacher details, and export a ready-to-print '
                  'PDF in seconds.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Divider(color: scheme.outlineVariant, height: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Made by',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Pressable(
                      onTap: () => _launch(_kThekamiSite),
                      child: Image.asset(_kThekamiLogo, height: 18),
                    ),
                  ],
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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SettingsGroup(
            title: 'Profile',
            children: [
              _SettingsTile(
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                title: 'Edit profile',
                subtitle: 'Name, index, institute, department, semester',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'General',
            children: [
              _SettingsTile(
                icon: const Icon(Icons.history_toggle_off_outlined, size: 20),
                title: 'Clear remembered values',
                subtitle:
                    'Forgets saved teacher, student, and batch suggestions',
                onTap: () async {
                  await RecallStore.instance.clearAll();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cleared remembered values'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Appearance',
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, mode, _) {
                  final current = switch (mode) {
                    ThemeMode.light => 'light',
                    ThemeMode.dark => 'dark',
                    ThemeMode.system => 'system',
                  };
                  return Column(
                    children: [
                      _ThemeOptionTile(
                        label: 'System default',
                        icon: Icons.brightness_auto_rounded,
                        selected: current == 'system',
                        onTap: () => applyThemeMode('system'),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: scheme.outlineVariant,
                      ),
                      _ThemeOptionTile(
                        label: 'Light',
                        icon: Icons.light_mode_outlined,
                        selected: current == 'light',
                        onTap: () => applyThemeMode('light'),
                      ),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: scheme.outlineVariant,
                      ),
                      _ThemeOptionTile(
                        label: 'Dark',
                        icon: Icons.dark_mode_outlined,
                        selected: current == 'dark',
                        onTap: () => applyThemeMode('dark'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'About',
            children: [
              _SettingsTile(
                icon: const Icon(Icons.info_outline_rounded, size: 20),
                title: 'About Topsheet',
                subtitle: 'Version, usage, and app details',
                onTap: _showAbout,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Community',
            children: [
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.discord,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                title: 'Discord',
                subtitle: 'Join the Thekami community',
                onTap: () => _launch(_kDiscord),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.linkedinIn,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                title: 'LinkedIn',
                onTap: () => _launch(_kLinkedIn),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.instagram,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                title: 'Instagram',
                onTap: () => _launch(_kInstagram),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.facebook,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                title: 'Facebook',
                onTap: () => _launch(_kFacebook),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Open Source',
            children: [
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.github,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                title: 'View source on GitHub',
                subtitle: 'Topsheet is free and open source',
                onTap: () => _launch(_kGithubRepo),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.github,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                title: 'Thekami on GitHub',
                onTap: () => _launch(_kGithubOrg),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: 'Support',
            children: [
              _SettingsTile(
                icon: Icon(
                  _isPlayStore == false ? Icons.star_outline_rounded : Icons.star_rounded,
                  size: 20,
                ),
                title: _isPlayStore == false ? 'Star on GitHub' : 'Rate Topsheet',
                subtitle: _isPlayStore == false
                    ? 'Give the project a star — it helps a lot'
                    : 'Enjoying the app? Leave a rating',
                onTap: () => RatePromptService.instance.requestRatingOrStar(),
              ),
              _SettingsTile(
                icon: const Icon(Icons.favorite_outline_rounded, size: 20),
                title: 'Support this project',
                subtitle: 'Help keep Thekami\'s apps free',
                onTap: () => _launch(_kSupport),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: Pressable(
              onTap: () => _launch(_kThekamiSite),
              child: Column(
                children: [
                  Text(
                    'MADE BY',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Image.asset(_kThekamiLogo, height: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsGroup({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.9,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: scheme.outlineVariant,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// icon accepts a pre-built Widget (Icon or FaIcon) so this tile works with
/// both Material icons and Font Awesome brand icons.
class _SettingsTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            SizedBox(width: 20, child: Center(child: icon)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, size: 20, color: scheme.primary)
            else
              Icon(
                Icons.circle_outlined,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
