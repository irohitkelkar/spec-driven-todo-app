import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final String screenshotDirPath =
      Platform.environment['SCREENSHOT_DIR'] ?? 'build/integration_screenshots';
  final Directory screenshotDir = Directory(screenshotDirPath);
  if (!screenshotDir.existsSync()) {
    screenshotDir.createSync(recursive: true);
  }

  await integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? args,
        ]) async {
          final File image = File('${screenshotDir.path}/$screenshotName.png');
          image.writeAsBytesSync(screenshotBytes);
          return image.existsSync() && image.lengthSync() > 0;
        },
    writeResponseOnFailure: true,
  );
}
