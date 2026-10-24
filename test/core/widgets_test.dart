import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhive_mobile/core/theme/app_theme.dart';
import 'package:hostelhive_mobile/core/utils/password_strength.dart';
import 'package:hostelhive_mobile/core/widgets/app_text_field.dart';
import 'package:hostelhive_mobile/core/widgets/category_pill.dart';
import 'package:hostelhive_mobile/core/widgets/confirmation_screen.dart';
import 'package:hostelhive_mobile/core/widgets/empty_state_widget.dart';
import 'package:hostelhive_mobile/core/widgets/info_alert_box.dart';
import 'package:hostelhive_mobile/core/widgets/password_checklist.dart';
import 'package:hostelhive_mobile/core/widgets/password_strength_meter.dart';
import 'package:hostelhive_mobile/core/widgets/primary_app_bar.dart';
import 'package:hostelhive_mobile/core/widgets/primary_button.dart';
import 'package:hostelhive_mobile/core/widgets/status_badge.dart';
import 'package:hostelhive_mobile/core/widgets/usage_progress_circle.dart';

Widget wrap(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('PrimaryButton', () {
    testWidgets('given it is enabled, when tapped, then it calls onPressed', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(PrimaryButton(label: 'Sign in', onPressed: () => taps++)),
      );

      await tester.tap(find.text('Sign in'));

      expect(taps, 1);
    });

    testWidgets(
      'given it is loading, then it shows a spinner and ignores taps',
      (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          wrap(
            PrimaryButton(
              label: 'Sign in',
              isLoading: true,
              onPressed: () => taps++,
            ),
          ),
        );

        await tester.tap(find.byType(PrimaryButton));

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Sign in'), findsNothing);
        expect(taps, 0);
      },
    );

    testWidgets('given onPressed is null, then tapping does nothing', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const PrimaryButton(label: 'Disabled', onPressed: null)),
      );

      await tester.tap(find.text('Disabled'));

      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets(
      'given outlined, destructive and icon options, then they render',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            Column(
              children: [
                PrimaryButton(
                  label: 'Outline',
                  onPressed: () {},
                  isOutlined: true,
                ),
                PrimaryButton(
                  label: 'Delete',
                  onPressed: () {},
                  isDestructive: true,
                  trailingIcon: Icons.arrow_forward,
                ),
              ],
            ),
          ),
        );

        expect(find.text('Outline'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
      },
    );
  });

  group('AppTextField', () {
    testWidgets('given a label, then it is shown in upper case', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const AppTextField(label: 'Email')));

      expect(find.text('EMAIL'), findsOneWidget);
    });

    testWidgets('given text is typed, then onChanged receives it', (
      tester,
    ) async {
      String? changed;
      await tester.pumpWidget(
        wrap(AppTextField(label: 'Name', onChanged: (v) => changed = v)),
      );

      await tester.enterText(find.byType(TextFormField), 'Sanuthi');

      expect(changed, 'Sanuthi');
    });

    testWidgets(
      'given a password field, when the eye is tapped, then it toggles',
      (tester) async {
        await tester.pumpWidget(
          wrap(const AppTextField(label: 'Password', isPassword: true)),
        );

        EditableText field() => tester.widget(find.byType(EditableText));
        expect(field().obscureText, isTrue);

        await tester.tap(find.byIcon(Icons.visibility_outlined));
        await tester.pump();

        expect(field().obscureText, isFalse);
        expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'given an invalid value, when validated, then the error shows',
      (tester) async {
        final formKey = GlobalKey<FormState>();
        await tester.pumpWidget(
          wrap(
            Form(
              key: formKey,
              child: AppTextField(
                label: 'Email',
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
            ),
          ),
        );

        formKey.currentState!.validate();
        await tester.pump();

        expect(find.text('Required'), findsOneWidget);
      },
    );
  });

  group('PrimaryAppBar', () {
    testWidgets('given a title, then it is shown with a back button', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(appBar: PrimaryAppBar(title: 'Reset password')),
        ),
      );

      expect(find.text('Reset password'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('given the back button is tapped, then onBack is called', (
      tester,
    ) async {
      var backs = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: PrimaryAppBar(title: 'Detail', onBack: () => backs++),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));

      expect(backs, 1);
    });

    testWidgets('given showBack is false, then no back button is shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            appBar: PrimaryAppBar(
              title: 'Passes',
              showBack: false,
              actions: [Icon(Icons.notifications_none)],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });
  });

  group('StatusBadge and CategoryPill', () {
    testWidgets('given a status, then the badge shows it in upper case', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const StatusBadge(status: 'Pending')));

      expect(find.text('PENDING'), findsOneWidget);
    });

    testWidgets('given a custom label, then the badge shows the label', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const StatusBadge(status: 'approved', label: 'Approved by warden'),
        ),
      );

      expect(find.text('APPROVED BY WARDEN'), findsOneWidget);
    });

    testWidgets('given a category, then the pill shows it in upper case', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const CategoryPill(label: 'Safety')));

      expect(find.text('SAFETY'), findsOneWidget);
    });
  });

  group('InfoAlertBox', () {
    testWidgets('given info and warning types, then both render their text', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const Column(
            children: [
              InfoAlertBox(title: 'Need help?', description: 'Call ext. 2040'),
              InfoAlertBox(
                title: 'Heads up',
                description: 'Check your inbox',
                type: AlertType.warning,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Need help?'), findsOneWidget);
      expect(find.text('Check your inbox'), findsOneWidget);
    });
  });

  group('PasswordStrengthMeter', () {
    testWidgets('given each strength, then the matching label is shown', (
      tester,
    ) async {
      for (final entry in {
        PasswordStrength.weak: 'Weak',
        PasswordStrength.medium: 'Medium',
        PasswordStrength.strong: 'Strong',
      }.entries) {
        await tester.pumpWidget(
          wrap(PasswordStrengthMeter(strength: entry.key)),
        );

        expect(find.text(entry.value), findsOneWidget);
      }
    });

    testWidgets('given an empty password, then no strength label is shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const PasswordStrengthMeter(
            strength: PasswordStrength.weak,
            isEmpty: true,
          ),
        ),
      );

      expect(find.text('Strength'), findsOneWidget);
      expect(find.text('Weak'), findsNothing);
    });
  });

  group('PasswordChecklist', () {
    testWidgets('given a partly valid password, then met rules show a tick', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(PasswordChecklist(rules: PasswordRules.of('Abcdefg1'))),
      );

      expect(find.byIcon(Icons.check), findsNWidgets(3));
      expect(find.text('One symbol'), findsOneWidget);
    });

    testWidgets('given an empty password, then no rule is ticked', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(PasswordChecklist(rules: PasswordRules.of(''))),
      );

      expect(find.byIcon(Icons.check), findsNothing);
    });
  });

  group('EmptyStateWidget', () {
    testWidgets('given a button, when tapped, then it calls the callback', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        wrap(
          SizedBox(
            height: 700,
            child: EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'No passes yet',
              description: 'Request late access to get started',
              buttonLabel: 'Request late access',
              onButtonPressed: () => taps++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Request late access'));

      expect(find.text('No passes yet'), findsOneWidget);
      expect(taps, 1);
    });

    testWidgets('given no button label, then no button is shown', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const SizedBox(
            height: 700,
            child: EmptyStateWidget(
              icon: Icons.inbox_outlined,
              title: 'Nothing here',
              description: 'Come back later',
            ),
          ),
        ),
      );

      expect(find.byType(PrimaryButton), findsNothing);
    });
  });

  group('UsageProgressCircle', () {
    testWidgets('given 67 percent usage, then it is shown as 67%', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const UsageProgressCircle(percentage: 0.67)),
      );

      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('given a value above one, then it is clamped to 100%', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const UsageProgressCircle(percentage: 1.4)));

      expect(find.text('100%'), findsOneWidget);
    });
  });

  group('ConfirmationScreen', () {
    testWidgets('given full content, then details and both buttons work', (
      tester,
    ) async {
      var primary = 0;
      var secondary = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ConfirmationScreen(
            title: 'Complaint submitted',
            subtitle: 'Your complaint has been recorded',
            description: 'We will notify you.',
            detailLabel: 'Ticket ID',
            detailValue: 'CMP-1001',
            primaryLabel: 'Back to Home',
            onPrimaryPressed: () => primary++,
            secondaryLabel: 'View complaint',
            onSecondaryPressed: () => secondary++,
          ),
        ),
      );

      expect(find.text('CMP-1001'), findsOneWidget);
      expect(find.text('Ticket ID'), findsOneWidget);

      await tester.tap(find.text('Back to Home'));
      await tester.tap(find.text('View complaint'));

      expect(primary, 1);
      expect(secondary, 1);
    });

    testWidgets('given minimal content, then optional parts are hidden', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: ConfirmationScreen(
            title: 'Done',
            subtitle: 'All set',
            primaryLabel: 'OK',
            onPrimaryPressed: () {},
          ),
        ),
      );

      expect(find.byType(PrimaryButton), findsOneWidget);
      expect(find.text('Ticket ID'), findsNothing);
    });
  });
}
