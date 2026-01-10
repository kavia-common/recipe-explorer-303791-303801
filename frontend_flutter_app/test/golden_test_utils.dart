import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shared utilities for deterministic, cross-platform golden tests.
///
/// Notes:
/// - We avoid any network image provider to prevent flakiness.
/// - We use `GoldenFileComparator` with a predictable directory.
/// - We load a known font into the test font manager to stabilize text metrics.
/// - We override `MediaQuery.devicePixelRatio` to validate sizing across DPRs.
class GoldenTestUtils {
  GoldenTestUtils._();

  /// Directory (under `test/`) that stores golden PNGs.
  static const String goldenDir = 'goldens';

  /// Default pixel-comparison tolerance for minor raster differences.
  ///
  /// Keep small; golden tests should be strict. Adjust only if needed for CI.
  static const double defaultGoldenTolerance = 0.02;

  /// A stable, tiny PNG (data URI) used as the decoded image source.
  ///
  /// This avoids network I/O and file-system dependencies while still exercising
  /// `Image` decode/paint paths.
  ///
  /// The image is 2x2 pixels with distinct colors:
  /// top-left red, top-right green, bottom-left blue, bottom-right white.
  static final Uint8List _k2x2PngBytes = base64Decode(
    // 2x2 RGBA PNG
    // Generated once and embedded to keep tests hermetic.
    'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAG0lEQVQImWNgoBpgYGBg+M+ABRgYGBgAAGwABQ0KpKkAAAAASUVORK5CYII=',
  );

  /// Creates an in-memory `ImageProvider` suitable for golden tests.
  static ImageProvider stableTestImageProvider() {
    return MemoryImage(_k2x2PngBytes);
  }

  /// Wraps a widget with a deterministic test harness:
  /// - fixed `MediaQuery` (size + devicePixelRatio)
  /// - `MaterialApp`/`ThemeData` (stable baseline theme)
  /// - center alignment and background for consistent screenshots
  static Widget harness({
    required Widget child,
    required double devicePixelRatio,
    required Size surfaceSize,
    Color background = const Color(0xFFFFFFFF),
  }) {
    // Use a very plain theme to reduce variability.
    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
    );

    return MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(
          size: surfaceSize,
          devicePixelRatio: devicePixelRatio,
          textScaler: const TextScaler.linear(1.0),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: background,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  /// Configures golden comparison to use `test/goldens/` directory.
  ///
  /// Call once per file in `setUpAll`.
  static void configureGoldens() {
    final GoldenFileComparator currentComparator = goldenFileComparator;
    // `flutter test --update-goldens` writes relative to the comparator base URL.
    // Using a comparator rooted at `test/` makes paths predictable.
    if (currentComparator is LocalFileComparator) {
      // If already a LocalFileComparator, just ensure the base is `test/`.
      final Uri testDir = currentComparator.basedir;
      if (testDir.path.endsWith('/test/') || testDir.path.endsWith(r'\test\')) {
        return;
      }
    }

    goldenFileComparator = LocalFileComparator(
      // Base golden dir is `<project>/test/`
      Uri.parse('${Directory.current.uri}test/'),
    );
  }

  /// Loads a deterministic font for all golden tests.
  ///
  /// We use the bundled `Ahem.ttf` font from the Flutter SDK test assets, which
  /// is available in Flutter's test environment.
  ///
  /// This stabilizes text layout and rasterization across platforms.
  static Future<void> loadTestFont() async {
    // `Ahem.ttf` is a special fixed-size font used by Flutter tests.
    final ByteData fontData =
        await rootBundle.load('packages/flutter_test/fonts/Ahem.ttf');

    final FontLoader loader = FontLoader('Ahem')
      ..addFont(Future<ByteData>.value(fontData));

    await loader.load();
  }

  /// Pumps the widget and waits for animations/frames to settle.
  static Future<void> pumpForGolden(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    // Ensure first frame + any AnimatedSwitcher fades settle.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  /// Returns the relative golden file path under `test/`.
  static String goldenPath(String fileName) => '$goldenDir/$fileName';
}
