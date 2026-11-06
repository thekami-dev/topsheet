import 'package:flutter/material.dart';

/// Page shell shared by Settings, Social and About: large collapsing title
/// bar, then a flat list.
class SettingsPage extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsPage({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(title: Text(title)),
          SliverList(delegate: SliverChildListDelegate(children)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 32 + MediaQuery.viewPaddingOf(context).bottom,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small coloured heading above a group of tiles.
class SettingsSection extends StatelessWidget {
  final String title;

  const SettingsSection(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// One row. [icon] is a ready-made widget (HugeIcon or FaIcon) so brand
/// icons and normal icons both work.
class SettingsTile extends StatelessWidget {
  final Widget icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: icon,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: onTap,
    );
  }
}
