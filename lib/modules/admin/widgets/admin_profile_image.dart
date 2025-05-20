import 'package:final_project/core/services/shared_preferences.dart';
import 'package:flutter/material.dart';

class AdminProfileImage extends StatelessWidget {
  const AdminProfileImage({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: SessionHelper.profilePicNotifier,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blueAccent, width: 3),
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundImage:
                (value != null && value.isNotEmpty)
                    ? NetworkImage(value)
                    : const AssetImage('assets/profile_placeholder.png'),
          ),
        );
      },
    );
  }
}
