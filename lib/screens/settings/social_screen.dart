import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'links.dart';
import 'settings_widgets.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      title: 'Social',
      children: [
        SettingsTile(
          icon: const FaIcon(FontAwesomeIcons.discord, size: 22),
          title: 'Discord',
          subtitle: 'Join the Thekami community',
          onTap: () => openLink(context, kDiscord),
        ),
        SettingsTile(
          icon: const FaIcon(FontAwesomeIcons.instagram, size: 22),
          title: 'Instagram',
          onTap: () => openLink(context, kInstagram),
        ),
        SettingsTile(
          icon: const FaIcon(FontAwesomeIcons.facebook, size: 22),
          title: 'Facebook',
          onTap: () => openLink(context, kFacebook),
        ),
        SettingsTile(
          icon: const FaIcon(FontAwesomeIcons.linkedinIn, size: 22),
          title: 'LinkedIn',
          onTap: () => openLink(context, kLinkedIn),
        ),
      ],
    );
  }
}
