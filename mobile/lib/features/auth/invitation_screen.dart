import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/navigation/app_routes.dart';

class InvitationScreen extends StatefulWidget {
  const InvitationScreen({super.key});

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  final _codeController = TextEditingController();

  void _submitCode() {
    if (_codeController.text.isNotEmpty) {
      AppRoutes.navigateAndReplace(context, AppRoutes.profileSetup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Invitation Code')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 16.h),
            Text(
              'Please enter your invitation code to continue.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 32.h),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Invitation Code',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submitCode(),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: _submitCode,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50.h),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
