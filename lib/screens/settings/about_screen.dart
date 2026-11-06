import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../services/install_source_service.dart';
import '../../services/rate_prompt_service.dart';
import 'links.dart';
import 'settings_widgets.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _info;
  bool? _isPlayStore;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
    InstallSourceService.instance.isFromPlayStore().then((v) {
      if (mounted) setState(() => _isPlayStore = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final version = _info != null
        ? 'Version ${_info!.version} (${_info!.buildNumber})'
        : '';
    final notPlayStore = _isPlayStore == false;

    return SettingsPage(
      title: 'About',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPdf01,
                  size: 36,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 16),
              Text('Topsheet', style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                version,
                style: textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Generate clean, share-ready practical sheets for course '
                'submissions. Pick a department and subject, fill in student '
                'and teacher details, and export a ready-to-print PDF in '
                'seconds.',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            ],
          ),
        ),
        const SettingsSection('Open source'),
        SettingsTile(
          icon: const FaIcon(FontAwesomeIcons.github, size: 22),
          title: 'Topsheet on GitHub',
          subtitle: 'Free and open source. View the code',
          onTap: () => openLink(context, kGithubRepo),
        ),
        SettingsTile(
          icon: const FaIcon(FontAwesomeIcons.github, size: 22),
          title: 'Thekami on GitHub',
          onTap: () => openLink(context, kGithubOrg),
        ),
        const SettingsSection('Support'),
        SettingsTile(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedStar, size: 24),
          title: notPlayStore ? 'Star on GitHub' : 'Rate Topsheet',
          subtitle: notPlayStore
              ? 'Give the project a star, it helps a lot'
              : 'Enjoying the app? Leave a rating',
          onTap: () => RatePromptService.instance.requestRatingOrStar(),
        ),
        SettingsTile(
          icon: HugeIcon(icon: HugeIcons.strokeRoundedFavourite, size: 24),
          title: 'Support this project',
          subtitle: "Help keep Thekami's apps free",
          onTap: () => openLink(context, kSupport),
        ),
        const SizedBox(height: 32),
        Center(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => openLink(context, kThekamiSite),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Made by',
                    style: textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Image.asset(kThekamiLogo, height: 22),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
