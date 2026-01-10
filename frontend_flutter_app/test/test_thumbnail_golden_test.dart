import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter_app/image/thumbnail.dart';

import 'golden_test_utils.dart';

void main() {
  setUpAll(() async {
    GoldenTestUtils.configureGoldens();
    await GoldenTestUtils.loadTestFont();
  });

  group('Thumbnail golden tests (multiple DPRs and sizes)', () {
    // Common DPRs we want to validate.
    const List<double> dprs = <double>[1.0, 2.0, 3.0];

    // List context: typically fixed width thumbnail with 4:3 aspect ratio.
    // In app code: RecipeCard uses width: 120 and aspectRatio: 4/3
    const Size listTileLogicalSize = Size(120, 90); // 4:3

    // A slightly larger list size variant (e.g., tablet / landscape / alternate density).
    const Size listTileLargeLogicalSize = Size(200, 120); // 5:3

    // Grid context: square image, similar to RecipeGridTile (aspectRatio: 1).
    const Size gridTileLogicalSize = Size(160, 160);

    Future<void> expectGoldenForSizeAndDpr({
      required WidgetTester tester,
      required String variant,
      required Size logicalSize,
      required double dpr,
    }) async {
      final ImageProvider provider = GoldenTestUtils.stableTestImageProvider();

      // Surface size should be larger than the widget to avoid clipping.
      final Size surfaceSize = Size(
        logicalSize.width + 40,
        logicalSize.height + 40,
      );

      // Build a constrained Thumbnail using the in-memory provider.
      final Widget widget = GoldenTestUtils.harness(
        devicePixelRatio: dpr,
        surfaceSize: surfaceSize,
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: Thumbnail.image(
            provider: provider,
            // Supply aspect ratio consistent with the constraints, so the widget
            // reserves space similarly to real app usage.
            aspectRatio: logicalSize.width / logicalSize.height,
            fit: BoxFit.cover,
            // Make border radius obvious/stable in goldens.
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            // Stable background under placeholder/error (should not be shown).
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
      );

      await GoldenTestUtils.pumpForGolden(tester, widget);

      // Ensure the image has decoded/painted.
      // MemoryImage resolves synchronously but Image may still need a frame.
      await tester.pump(const Duration(milliseconds: 50));

      final String fileName =
          'thumbnail_${variant}_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png';

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(GoldenTestUtils.goldenPath(fileName)),
      );
    }

    testWidgets('List thumbnail at 120x90 renders consistently across DPRs',
        (WidgetTester tester) async {
      for (final double dpr in dprs) {
        await expectGoldenForSizeAndDpr(
          tester: tester,
          variant: 'list',
          logicalSize: listTileLogicalSize,
          dpr: dpr,
        );
      }
    });

    testWidgets('List thumbnail at 200x120 renders consistently across DPRs',
        (WidgetTester tester) async {
      for (final double dpr in dprs) {
        await expectGoldenForSizeAndDpr(
          tester: tester,
          variant: 'list',
          logicalSize: listTileLargeLogicalSize,
          dpr: dpr,
        );
      }
    });

    testWidgets('Grid thumbnail at 160x160 renders consistently across DPRs',
        (WidgetTester tester) async {
      for (final double dpr in dprs) {
        await expectGoldenForSizeAndDpr(
          tester: tester,
          variant: 'grid',
          logicalSize: gridTileLogicalSize,
          dpr: dpr,
        );
      }
    });

    testWidgets('Thumbnail placeholder is stable when provider fails',
        (WidgetTester tester) async {
      // Use an invalid image provider to force errorBuilder; keep deterministic UI.
      final ImageProvider badProvider = MemoryImage(
        Uint8List.fromList(<int>[0, 1, 2, 3]),
      );

      const Size logicalSize = Size(120, 90);
      const double dpr = 2.0;

      final Widget widget = GoldenTestUtils.harness(
        devicePixelRatio: dpr,
        surfaceSize: const Size(200, 160),
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: Thumbnail.image(
            provider: badProvider,
            aspectRatio: logicalSize.width / logicalSize.height,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            backgroundColor: const Color(0xFFF9FAFB),
          ),
        ),
      );

      await GoldenTestUtils.pumpForGolden(tester, widget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          GoldenTestUtils.goldenPath(
            'thumbnail_error_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png',
          ),
        ),
      );
    });
  });
}
