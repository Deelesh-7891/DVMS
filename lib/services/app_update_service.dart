import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  // ============================================================
  // CHECK FOR UPDATE
  // ============================================================

  static Future<void> checkForUpdate(
    BuildContext context,
  ) async {
    try {
      debugPrint('======================================');
      debugPrint('CHECKING APP UPDATE');
      debugPrint('======================================');

      final AppUpdateInfo updateInfo =
          await InAppUpdate.checkForUpdate();

      debugPrint(
        'Update Availability: '
        '${updateInfo.updateAvailability}',
      );

      debugPrint(
        'Available Version Code: '
        '${updateInfo.availableVersionCode}',
      );

      debugPrint(
        'Immediate Update Allowed: '
        '${updateInfo.immediateUpdateAllowed}',
      );

      debugPrint(
        'Flexible Update Allowed: '
        '${updateInfo.flexibleUpdateAllowed}',
      );

      debugPrint('======================================');

      // ========================================================
      // NO UPDATE
      // ========================================================

      if (updateInfo.updateAvailability !=
          UpdateAvailability.updateAvailable) {
        debugPrint('NO UPDATE AVAILABLE');
        return;
      }

      // ========================================================
      // CONTEXT CHECK
      // ========================================================

      if (!context.mounted) return;

      // ========================================================
      // SHOW CUSTOM DIALOG
      // ========================================================

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Update Available',
            ),
            content: const Text(
              'A new version of Demo Vehicle Management '
              'is available. Please update the app to '
              'continue with the latest features and fixes.',
            ),
            actions: [
              // ================================================
              // LATER
              // ================================================

              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  'Later',
                ),
              ),

              // ================================================
              // UPDATE NOW
              // ================================================

              ElevatedButton(
                onPressed: () async {
                  Navigator.of(dialogContext).pop();

                  await _startUpdate(
                    updateInfo,
                  );
                },
                child: const Text(
                  'Update Now',
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint(
        'APP UPDATE ERROR: $e',
      );
    }
  }

  // ============================================================
  // START UPDATE
  // ============================================================

  static Future<void> _startUpdate(
    AppUpdateInfo updateInfo,
  ) async {
    try {
      // ========================================================
      // IMMEDIATE UPDATE
      // ========================================================

      if (updateInfo.immediateUpdateAllowed) {
        debugPrint(
          'STARTING IMMEDIATE UPDATE',
        );

        await InAppUpdate.performImmediateUpdate();

        return;
      }

      // ========================================================
      // FLEXIBLE UPDATE
      // ========================================================

      if (updateInfo.flexibleUpdateAllowed) {
        debugPrint(
          'STARTING FLEXIBLE UPDATE',
        );

        await InAppUpdate.startFlexibleUpdate();

        return;
      }

      debugPrint(
        'NO UPDATE METHOD ALLOWED',
      );
    } catch (e) {
      debugPrint(
        'UPDATE INSTALL ERROR: $e',
      );
    }
  }
}