import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/recall_store.dart';
import '../services/install_source_service.dart';
import '../services/rate_prompt_service.dart';
import '../widgets/pressable.dart';
import 'edit_profile_screen.dart';
import 'themes_screen.dart';

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
        padding: EdgeInsets.fromLTRB(16, 12, 16, 32 + MediaQuery.viewPaddingOf(context).bottom),
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
            title: 'Appearance',
            children: [
              _SettingsTile(
                icon: const Icon(Icons.palette_outlined, size: 20),
                title: 'Themes',
                subtitle: 'Light, dark and colour themes',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ThemesScreen()),
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
            title: 'Connect & Support',
            children: [
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.discord,
                  size: 18,
                ),
                title: 'Discord',
                subtitle: 'Join the Thekami community',
                onTap: () => _launch(_kDiscord),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.instagram,
                  size: 18,
                ),
                title: 'Instagram',
                onTap: () => _launch(_kInstagram),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.facebook,
                  size: 18,
                ),
                title: 'Facebook',
                onTap: () => _launch(_kFacebook),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.linkedinIn,
                  size: 18,
                ),
                title: 'LinkedIn',
                onTap: () => _launch(_kLinkedIn),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.github,
                  size: 18,
                ),
                title: 'Topsheet on GitHub',
                subtitle: 'Free and open source \u2014 view the code',
                onTap: () => _launch(_kGithubRepo),
              ),
              _SettingsTile(
                icon: FaIcon(
                  FontAwesomeIcons.github,
                  size: 18,
                ),
                title: 'Thekami on GitHub',
                onTap: () => _launch(_kGithubOrg),
              ),
              _SettingsTile(
                icon: Icon(
                  _isPlayStore == false
                      ? Icons.star_outline_rounded
                      : Icons.star_rounded,
                  size: 20,
                ),
                title: _isPlayStore == false ? 'Star on GitHub' : 'Rate Topsheet',
                subtitle: _isPlayStore == false
                    ? 'Give the project a star \u2014 it helps a lot'
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
          padding: const EdgeInsets.only(bottom: 10, left: 14),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.secondary),
          ),
        ),
        // Material (not Container) so InkWell ripples show on top of it.
        Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: IconTheme(
                data: IconThemeData(color: scheme.secondary, size: 20),
                child: icon,
              ),
            ),
            const SizedBox(width: 16),
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
