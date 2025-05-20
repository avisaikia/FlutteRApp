import 'package:final_project/modules/manager/controllers/user_profile_provider.dart';
import 'package:final_project/modules/manager/widgets/user_profile_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ManagerProfilePage extends StatelessWidget {
  const ManagerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileProvider()..loadProfile(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manager Profile'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: UserProfileForm(),
      ),
    );
  }
}
