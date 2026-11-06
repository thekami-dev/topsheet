import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const kGithubRepo = 'https://github.com/thekami-dev/topsheet';
const kGithubOrg = 'https://github.com/thekami-dev';
const kDiscord = 'https://www.thekami.tech/discord/';
const kLinkedIn = 'https://www.linkedin.com/company/thekamiofficial';
const kInstagram = 'https://www.instagram.com/thekami_official';
const kFacebook = 'https://www.facebook.com/thekamidev/';
const kSupport = 'https://www.supportkori.com/thekami';
const kThekamiSite = 'https://www.thekami.tech';
const kThekamiLogo = 'assets/images/thekami_logo.png';

Future<void> openLink(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Could not open $url')));
  }
}
