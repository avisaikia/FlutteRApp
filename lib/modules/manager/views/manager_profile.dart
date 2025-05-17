import 'package:final_project/modules/manager/widgets/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagerProfilePage extends StatelessWidget {
  const ManagerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manager Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/manager-dashboard'),
        ),
      ),
      body: UserProfileForm(role: 'manager'),
    );
  }
}
