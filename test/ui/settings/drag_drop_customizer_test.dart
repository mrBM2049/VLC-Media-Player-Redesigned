import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vlc_modern/models/toolbar_customizer_models.dart';
import 'package:vlc_modern/theme/theme.dart';
import 'package:vlc_modern/ui/settings/drag_drop_customizer.dart';

void main() {
  group('DragDropLayoutCustomizer Tests (Task 5.3)', () {
    testWidgets('Renders header, profiles dropdown, drop zones, and available tool palette', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: DragDropLayoutCustomizer(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Customize Interface & Toolbars'), findsOneWidget);
      expect(find.text('Reset Layout'), findsOneWidget);
      expect(find.text('Top Player Bar Layout'), findsOneWidget);
      expect(find.text('Bottom Transport Row Layout'), findsOneWidget);
      expect(find.text('AVAILABLE TOOL PALETTE (Drag into bars above)'), findsOneWidget);

      // Verify standard buttons present in bottom drop zone
      expect(find.text('Play / Pause'), findsWidgets); // chip + palette
      expect(find.text('Volume & Mute'), findsWidgets);
    });

    testWidgets('Switches toolbar profiles and updates active buttons', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ToolbarProfile? savedProfile;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: DragDropLayoutCustomizer(
              onProfileSaved: (p) => savedProfile = p,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open profile dropdown
      await tester.tap(find.text('Standard (Balanced)'));
      await tester.pumpAndSettle();

      // Select Minimalist profile
      await tester.tap(find.text('Minimalist (Cinematic)').last);
      await tester.pumpAndSettle();

      expect(savedProfile?.id, equals('minimal'));
      expect(savedProfile?.bottomBarButtons.length, equals(3));
    });

    testWidgets('Removes button from drop zone when close icon is tapped', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      ToolbarProfile? savedProfile;

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: Scaffold(
            body: DragDropLayoutCustomizer(
              onProfileSaved: (p) => savedProfile = p,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final initialTopCount = ToolbarProfile.standard.topBarButtons.length;

      // Find first close icon (on top bar first chip)
      final closeIcons = find.byIcon(Icons.close);
      expect(closeIcons, findsWidgets);

      await tester.tap(closeIcons.first);
      await tester.pumpAndSettle();

      expect(savedProfile?.topBarButtons.length, equals(initialTopCount - 1));
    });

    testWidgets('Reset Layout restores Standard profile', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: VlcThemeData.dark().toThemeData(),
          home: const Scaffold(
            body: DragDropLayoutCustomizer(
              initialProfile: ToolbarProfile.minimal,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Layout'));
      await tester.pumpAndSettle();

      expect(find.text('Toolbars reset to Standard layout.'), findsOneWidget);
      expect(find.text('Standard (Balanced)'), findsOneWidget);
    });
  });
}
