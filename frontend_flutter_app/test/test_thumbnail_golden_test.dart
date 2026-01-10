import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter_app/image/lazy_image.dart';
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

    // Common logical sizes across typical contexts.
    const Size listTileLogicalSize = Size(120, 90); // 4:3
    const Size listTileLargeLogicalSize = Size(200, 120); // 5:3
    const Size gridTileLogicalSize = Size(160, 160); // square
    const Size detailHeaderLogicalSize = Size(320, 180); // 16:9-ish

    Future<void> expectGoldenForProvider({
      required WidgetTester tester,
      required String fileName,
      required double dpr,
      required Size logicalSize,
      required ImageProvider provider,
      Widget? placeholder,
      Widget? error,
    }) async {
      final Size surfaceSize = Size(
        logicalSize.width + 40,
        logicalSize.height + 40,
      );

      final Widget widget = GoldenTestUtils.harness(
        devicePixelRatio: dpr,
        surfaceSize: surfaceSize,
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: Thumbnail.image(
            provider: provider,
            aspectRatio: logicalSize.width / logicalSize.height,
            fit: BoxFit.cover,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            backgroundColor: const Color(0xFFF9FAFB),
            placeholder: placeholder,
            error: error,
          ),
        ),
      );

      await GoldenTestUtils.pumpForGolden(tester, widget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(GoldenTestUtils.goldenPath(fileName)),
      );
    }

    Future<void> expectGoldenLoadedAcrossDprs({
      required WidgetTester tester,
      required String variant,
      required Size logicalSize,
    }) async {
      for (final double dpr in dprs) {
        final ImageProvider provider = GoldenTestUtils.stableTestImageProvider();

        final String fileName =
            'thumbnail_${variant}_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png';

        await expectGoldenForProvider(
          tester: tester,
          fileName: fileName,
          dpr: dpr,
          logicalSize: logicalSize,
          provider: provider,
        );
      }
    }

    testWidgets('List thumbnail at 120x90 renders consistently across DPRs',
        (WidgetTester tester) async {
      await expectGoldenLoadedAcrossDprs(
        tester: tester,
        variant: 'list',
        logicalSize: listTileLogicalSize,
      );
    });

    testWidgets('List thumbnail at 200x120 renders consistently across DPRs',
        (WidgetTester tester) async {
      await expectGoldenLoadedAcrossDprs(
        tester: tester,
        variant: 'list',
        logicalSize: listTileLargeLogicalSize,
      );
    });

    testWidgets('Grid thumbnail at 160x160 renders consistently across DPRs',
        (WidgetTester tester) async {
      await expectGoldenLoadedAcrossDprs(
        tester: tester,
        variant: 'grid',
        logicalSize: gridTileLogicalSize,
      );
    });

    testWidgets('Detail header thumbnail at 320x180 renders consistently across DPRs',
        (WidgetTester tester) async {
      await expectGoldenLoadedAcrossDprs(
        tester: tester,
        variant: 'detail',
        logicalSize: detailHeaderLogicalSize,
      );
    });

    testWidgets('Error state renders consistently across sizes and DPRs',
        (WidgetTester tester) async {
      for (final Size logicalSize in <Size>[
        listTileLogicalSize,
        gridTileLogicalSize,
        detailHeaderLogicalSize,
      ]) {
        for (final double dpr in dprs) {
          final ImageProvider provider = GoldenTestUtils.failingTestImageProvider();

          final String fileName =
              'thumbnail_error_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png';

          await expectGoldenForProvider(
            tester: tester,
            fileName: fileName,
            dpr: dpr,
            logicalSize: logicalSize,
            provider: provider,
          );
        }
      }
    });

    testWidgets('Loading/placeholder state renders before image resolves',
        (WidgetTester tester) async {
      for (final Size logicalSize in <Size>[
        listTileLogicalSize,
        gridTileLogicalSize,
        detailHeaderLogicalSize,
      ]) {
        for (final double dpr in dprs) {
          final ControlledTestImageProvider provider =
              GoldenTestUtils.controlledLoadingImageProvider();

          // Pump once to capture the "loading" state.
          await expectGoldenForProvider(
            tester: tester,
            fileName:
                'thumbnail_loading_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png',
            dpr: dpr,
            logicalSize: logicalSize,
            provider: provider,
          );

          // Now resolve the image and capture the "loaded" state for the same provider,
          // to ensure deterministic transition.
          provider.complete();

          final String loadedFileName =
              'thumbnail_loading_resolved_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png';

          await expectGoldenForProvider(
            tester: tester,
            fileName: loadedFileName,
            dpr: dpr,
            logicalSize: logicalSize,
            provider: provider,
          );
        }
      }
    });

    testWidgets('LazyLoad deferred vs in-view phases render deterministically',
        (WidgetTester tester) async {
      // We test the LazyLoad wrapper directly (used by Thumbnail for network),
      // but keep the expensive child a non-network Thumbnail(provider: ...) to
      // remain hermetic while still validating lazy/deferred UI composition.
      const Size logicalSize = gridTileLogicalSize;

      for (final double dpr in dprs) {
        // Phase 1: deferred/offscreen -> placeholder shown.
        {
          final ImageProvider provider = GoldenTestUtils.stableTestImageProvider();

          final Widget thumb = SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: LazyLoad(
              preload: 0, // strict: must be in viewport
              placeholder: const _TestPlaceholder(),
              builder: (_) => Thumbnail.image(
                provider: provider,
                aspectRatio: 1,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
            ),
          );

          final Widget harness = GoldenTestUtils.scrollHarness(
            devicePixelRatio: dpr,
            viewportSize: const Size(240, 240),
            // Place the widget far below the viewport so it is deferred.
            topPadding: 800,
            child: thumb,
          );

          await GoldenTestUtils.pumpForGolden(tester, harness);

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              GoldenTestUtils.goldenPath(
                'thumbnail_lazy_deferred_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png',
              ),
            ),
          );
        }

        // Phase 2: in-view -> builder shown (image rendered).
        {
          final ImageProvider provider = GoldenTestUtils.stableTestImageProvider();

          final Widget thumb = SizedBox(
            width: logicalSize.width,
            height: logicalSize.height,
            child: LazyLoad(
              preload: 0,
              placeholder: const _TestPlaceholder(),
              builder: (_) => Thumbnail.image(
                provider: provider,
                aspectRatio: 1,
                fit: BoxFit.cover,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
            ),
          );

          final Widget harness = GoldenTestUtils.scrollHarness(
            devicePixelRatio: dpr,
            viewportSize: const Size(240, 240),
            // Put the widget in view immediately.
            topPadding: 0,
            child: thumb,
          );

          await GoldenTestUtils.pumpForGolden(tester, harness);

          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile(
              GoldenTestUtils.goldenPath(
                'thumbnail_lazy_inview_${logicalSize.width.toInt()}x${logicalSize.height.toInt()}_dpr${dpr.toInt()}.png',
              ),
            ),
          );
        }
      }
    });
  });
}

class _TestPlaceholder extends StatelessWidget {
  const _TestPlaceholder();

  @override
  Widget build(BuildContext context) {
    // Deliberately visually distinct from Thumbnail's default placeholder to
    // make lazy-loading phases obvious in goldens.
    return Container(
      color: const Color(0xFFE5E7EB), // gray-200
      alignment: Alignment.center,
      child: const Icon(Icons.hourglass_empty),
    );
  }
}
