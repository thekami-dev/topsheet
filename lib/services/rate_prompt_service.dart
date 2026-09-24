import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import 'install_source_service.dart';

const _kGithubRepo = 'https://github.com/thekami-dev/topsheet'\;

/// Shows the right ask depending on where the app came from: a native
/// Play Store rating prompt for Play installs, or a GitHub star request
/// (opened in browser) for sideloaded/GitHub-Release installs.
class RatePromptService {
  RatePromptService._();
  static final RatePromptService instance = RatePromptService._();

  Future<void> requestRatingOrStar() async {
    final isPlayStore = await InstallSourceService.instance.isFromPlayStore();
    if (isPlayStore) {
      final inAppReview = InAppReview.instance;
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } else {
      final uri = Uri.parse(_kGithubRepo);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
