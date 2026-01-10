import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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

  /// Creates an `ImageProvider` that deterministically stays "loading" until
  /// [ControlledTestImageProvider.complete] is called.
  ///
  /// This allows us to capture a stable "placeholder" golden.
  static ControlledTestImageProvider controlledLoadingImageProvider() {
    return ControlledTestImageProvider(bytes: _k2x2PngBytes);
  }

  /// Creates an `ImageProvider` that deterministically fails to decode/load.
  ///
  /// This allows us to capture error rendering without any I/O.
  static ImageProvider failingTestImageProvider() {
    return const FailingTestImageProvider();
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

  /// A harness variant that embeds the [child] in a scrollable, so widgets that
  /// depend on [Scrollable.recommendDeferredLoadingForContext] can be tested.
  ///
  /// [topPadding] controls how far the child is placed below the viewport. When
  /// [topPadding] is large, the child starts offscreen (good for "deferred"
  /// snapshots). When small/zero, the child is immediately in view.
  static Widget scrollHarness({
    required Widget child,
    required double devicePixelRatio,
    required Size viewportSize,
    required double topPadding,
    Color background = const Color(0xFFFFFFFF),
  }) {
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
          size: viewportSize,
          devicePixelRatio: devicePixelRatio,
          textScaler: const TextScaler.linear(1.0),
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: ColoredBox(
            color: background,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: viewportSize.width,
                height: viewportSize.height,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    SizedBox(height: topPadding),
                    Center(child: child),
                    const SizedBox(height: 400),
                  ],
                ),
              ),
            ),
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
      if (testDir.path.endsWith('/test/') || testDir.path.endsWith(r'\\test\\')) {
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

/// An `ImageProvider` for tests that does not resolve until [complete] is called.
class ControlledTestImageProvider
    extends ImageProvider<ControlledTestImageProvider> {
  ControlledTestImageProvider({required this.bytes});

  final Uint8List bytes;

  final Completer<void> _gate = Completer<void>();

  /// Allows the image to resolve (transitioning from placeholder to image).
  void complete() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<ControlledTestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ControlledTestImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    ControlledTestImageProvider key,
    ImageDecoderCallback decode,
  ) {
    // Flutter 3.29+ ImageDecoderCallback expects an ImmutableBuffer.
    final Future<ui.Codec> codecFuture = _gate.future.then((_) async {
      final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      return decode(buffer);
    });

    return OneFrameImageStreamCompleter(
      codecFuture.then((ui.Codec codec) async {
        final ui.FrameInfo frame = await codec.getNextFrame();
        return ImageInfo(image: frame.image);
      }),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ControlledTestImageProvider && identical(other.bytes, bytes);

  @override
  int get hashCode => identityHashCode(bytes);
}

/// An `ImageProvider` that always fails to decode/load (deterministic error).
class FailingTestImageProvider extends ImageProvider<FailingTestImageProvider> {
  const FailingTestImageProvider();

  @override
  Future<FailingTestImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<FailingTestImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    FailingTestImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      Future<ImageInfo>.error(StateError('FailingTestImageProvider error')),
    );
  }

  @override
  bool operator ==(Object other) => other is FailingTestImageProvider;

  @override
  int get hashCode => runtimeType.hashCode;
}
