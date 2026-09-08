import 'package:flutter/material.dart';

import '../../domain/entities/app_user.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.expectedRole,
    required this.currentRole,
    required this.child,
  });

  final AppRole expectedRole;
  final AppRole currentRole;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (currentRole != expectedRole) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 44),
                const SizedBox(height: 12),
                const Text('Access denied for this role.'),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go back'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return child;
  }
}
