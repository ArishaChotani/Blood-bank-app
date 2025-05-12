import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_bank_app/general/main.dart';
import 'package:blood_bank_app/screens/donor/donor_list_screen.dart';
import 'package:blood_bank_app/screens/reciever/receiver_list_screen.dart';

void main() {
  group('Blood Bank App Tests', () {
    testWidgets('App launches correctly', (WidgetTester tester) async {
      // Build our app
      await tester.pumpWidget(const BloodBankApp());

      // Verify the app title is shown
      expect(find.text('Blood Bank App'), findsOneWidget);
    });

    testWidgets('Navigation to Donor Screen works', (WidgetTester tester) async {
      await tester.pumpWidget(const BloodBankApp());

      // Tap the donor navigation item
      await tester.tap(find.byIcon(Icons.bloodtype));
      await tester.pumpAndSettle();

      // Verify we're on the donor screen
      expect(find.byType(DonorListScreen), findsOneWidget);
      expect(find.text('Donors List'), findsOneWidget);
    });

    testWidgets('Navigation to Receiver Screen works', (WidgetTester tester) async {
      await tester.pumpWidget(const BloodBankApp());

      // Tap the receiver navigation item
      await tester.tap(find.byIcon(Icons.medical_services));
      await tester.pumpAndSettle();

      // Verify we're on the receiver screen
      expect(find.byType(ReceiverListScreen), findsOneWidget);
      expect(find.text('Receivers List'), findsOneWidget);
    });

    testWidgets('Donor List displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DonorListScreen(),
      ));

      await tester.pump(); // Allow the widget to build

      // Verify donor list items appear
      expect(find.byType(ListTile), findsWidgets);
      expect(find.byIcon(Icons.bloodtype), findsWidgets);
    });

    testWidgets('Receiver List displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ReceiverListScreen(),
      ));

      await tester.pump(); // Allow the widget to build

      // Verify receiver list items appear
      expect(find.byType(ListTile), findsWidgets);
      expect(find.byIcon(Icons.medical_services), findsWidgets);
    });

    testWidgets('Donor details dialog shows correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: DonorListScreen(),
      ));

      await tester.pump(); // Allow the widget to build

      // Tap the first donor
      await tester.tap(find.byType(ListTile).first);
          await tester.pump();

      // Verify the dialog appears with donor details
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Age:'), findsOneWidget);
      expect(find.text('Blood Group:'), findsOneWidget);
    });

    testWidgets('Receiver details dialog shows correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: ReceiverListScreen(),
      ));

      await tester.pump(); // Allow the widget to build

      // Tap the first receiver
      await tester.tap(find.byType(ListTile).first);
          await tester.pump();

      // Verify the dialog appears with receiver details
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Age:'), findsOneWidget);
      expect(find.text('Blood Group:'), findsOneWidget);
    });
  });
}