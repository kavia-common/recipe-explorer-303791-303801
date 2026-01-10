import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_flutter_app/image/thumbnail.dart';

void main() {
  testWidgets('ThumbnailProvider computes bounded cache sizes and clamps',
      (WidgetTester tester) async {
    const provider = ThumbnailProvider(minPhysicalPx: 48, maxPhysicalPx: 256);

    final sizing = provider.computeFromConstraints(
      constraints: const BoxConstraints.tightFor(width: 200, height: 100),
      devicePixelRatio: 3.0,
      aspectRatio: 2.0,
    );

    // 200*3=600 should clamp to 256, snapped to multiple of 8.
    expect(sizing.cacheWidth, 256);
    // 100*3=300 clamps to 256.
    expect(sizing.cacheHeight, 256);
  });

  testWidgets('Thumbnail reserves space when aspectRatio is provided',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            child: Thumbnail.image(
              url: 'https://example.com/image.jpg',
              aspectRatio: 16 / 9,
            ),
          ),
        ),
      ),
    );

    // We don't actually fetch the network image; CachedNetworkImage will show placeholder.
    expect(find.byType(AspectRatio), findsOneWidget);
    expect(find.byIcon(Icons.image_outlined), findsOneWidget);
  });
}
