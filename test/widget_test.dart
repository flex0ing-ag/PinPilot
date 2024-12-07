import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:combine/main.dart'; // Make sure the path is correct

void main() {
  testWidgets('AppBar title and QR/Image buttons are present', (WidgetTester tester) async {
    // Build the CombinedScannerApp and trigger a frame.
    await tester.pumpWidget(CombinedScannerApp());

    // Verify that the AppBar title is "Combined Scanner".
    expect(find.text('Combined Scanner'), findsOneWidget);

    // Verify that both QR and Image buttons are present.
    expect(find.text('QR Code Scanner'), findsOneWidget);
    expect(find.text('Image Scanner'), findsOneWidget);

    // Optionally, you can tap one of the buttons to test the interaction:
    await tester.tap(find.text('QR Code Scanner'));
    await tester.pump(); // Rebuild the widget with the new state

    // Add further expectations here based on what happens after tapping the button if needed.
  });
}
