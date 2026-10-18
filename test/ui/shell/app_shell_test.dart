import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/vlc_modern.dart';

void main() {
  group('AppShellController Auto-Hide & Lock Hide Tests', () {
    test('Default desktop inactivity duration is 1800ms and mobile is 3000ms', () {
      final controller = AppShellController();
      expect(controller.desktopInactivityDuration, const Duration(milliseconds: 1800));
      expect(controller.mobileInactivityDuration, const Duration(milliseconds: 3000));
      expect(controller.isUiVisible, true);
      expect(controller.isLockedHidden, false);
      expect(controller.isDrawerOpen, false);
      controller.dispose();
    });

    test('Auto-hide timer hides UI after inactivity duration expires', () async {
      final controller = AppShellController(
        desktopInactivityDuration: const Duration(milliseconds: 50),
      );

      expect(controller.isUiVisible, true);
      controller.resetInactivityTimer(true);

      // Wait for timer to expire
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.isUiVisible, false);

      // Re-triggering showUi makes it visible again
      controller.showUi(restartTimer: false);
      expect(controller.isUiVisible, true);

      controller.dispose();
    });

    test('Hovering interactive controls prevents auto-hide', () async {
      final controller = AppShellController(
        desktopInactivityDuration: const Duration(milliseconds: 50),
      );

      controller.setHoveringControls(true, true);
      expect(controller.isHoveringControls, true);
      expect(controller.isUiVisible, true);

      // Wait longer than timer
      await Future<void>.delayed(const Duration(milliseconds: 80));
      // UI must remain visible because user is actively hovering/interacting with controls
      expect(controller.isUiVisible, true);

      // Leaving controls restarts the countdown
      controller.setHoveringControls(false, true);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(controller.isUiVisible, false);

      controller.dispose();
    });

    test('toggleLockHide (Ctrl+H / Cmd+H) completely locks UI hidden', () {
      final controller = AppShellController();
      expect(controller.isLockedHidden, false);
      expect(controller.isUiVisible, true);

      // Lock hide
      controller.toggleLockHide();
      expect(controller.isLockedHidden, true);
      expect(controller.isUiVisible, false);

      // showUi should not reveal chrome while locked
      controller.showUi();
      expect(controller.isUiVisible, false);

      // Unlock
      controller.toggleLockHide();
      expect(controller.isLockedHidden, false);
      expect(controller.isUiVisible, true);

      controller.dispose();
    });

    test('Drawer controls keep UI visible and track active tab index', () {
      final controller = AppShellController();
      expect(controller.isDrawerOpen, false);

      controller.openDrawer(2);
      expect(controller.isDrawerOpen, true);
      expect(controller.activeDrawerTab, 2);
      expect(controller.isUiVisible, true);

      // Toggling same tab closes drawer
      controller.toggleDrawer(2);
      expect(controller.isDrawerOpen, false);

      // Toggling different tab opens that tab
      controller.toggleDrawer(3);
      expect(controller.isDrawerOpen, true);
      expect(controller.activeDrawerTab, 3);

      controller.dispose();
    });

    test('Queue drawer controls toggle and close correctly', () {
      final controller = AppShellController();
      expect(controller.isQueueOpen, false);

      controller.openQueue();
      expect(controller.isQueueOpen, true);
      expect(controller.isDrawerOpen, false);
      expect(controller.isUiVisible, true);

      controller.toggleQueue();
      expect(controller.isQueueOpen, false);

      controller.toggleQueue();
      expect(controller.isQueueOpen, true);

      // Opening inspector drawer automatically closes queue
      controller.openDrawer(1);
      expect(controller.isDrawerOpen, true);
      expect(controller.isQueueOpen, false);

      controller.dispose();
    });
  });

  group('AppShell Widget Layering Tests', () {
    testWidgets('Renders video surface, top bar, and bottom controls', (tester) async {
      final controller = AppShellController();

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: AppShell(
            playerController: VlcPlayerController.mock(),
            shellController: controller,
            videoSurface: Container(
              key: const ValueKey('video_surface'),
              color: Colors.black,
            ),
            topBar: Container(
              key: const ValueKey('top_bar'),
              height: 48,
              child: const Text('Top Bar'),
            ),
            bottomControls: Container(
              key: const ValueKey('bottom_controls'),
              height: 60,
              child: const Text('Bottom Controls'),
            ),
            queueDrawer: Container(
              key: const ValueKey('queue_drawer'),
              child: const Text('Queue Drawer Content'),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('video_surface')), findsOneWidget);
      expect(find.byKey(const ValueKey('top_bar')), findsOneWidget);
      expect(find.byKey(const ValueKey('bottom_controls')), findsOneWidget);
      expect(find.byKey(const ValueKey('queue_drawer')), findsOneWidget);

      controller.dispose();
    });
  });
}

