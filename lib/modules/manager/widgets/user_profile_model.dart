import 'package:final_project/modules/manager/controllers/user_profile_provider.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class UserProfileForm extends StatelessWidget {
  const UserProfileForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => provider.pickAndUploadProfilePicture(),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              provider.profilePicNotifier.value != null
                                  ? NetworkImage(
                                    provider.profilePicNotifier.value!,
                                  )
                                  : null,
                          child:
                              provider.profilePicNotifier.value == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => provider.pickAndUploadProfilePicture(),
                          child: const CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blueAccent,
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Name
                TextFormField(
                  controller: provider.nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: _purpleOutlineBorder(),
                    enabledBorder: _purpleOutlineBorder(),
                    focusedBorder: _purpleOutlineBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Email
                TextFormField(
                  controller: provider.emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: _purpleOutlineBorder(),
                    enabledBorder: _purpleOutlineBorder(),
                    focusedBorder: _purpleOutlineBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: provider.passwordController,
                  obscureText: !provider.passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Change Password',
                    border: _purpleOutlineBorder(),
                    enabledBorder: _purpleOutlineBorder(),
                    focusedBorder: _purpleOutlineBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        provider.passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.blueAccent,
                      ),
                      onPressed: () => provider.togglePasswordVisibility(),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // DOB with ValueListenableBuilder
                ValueListenableBuilder<String>(
                  valueListenable: provider.dobNotifier,
                  builder: (context, value, _) {
                    return TextFormField(
                      controller: TextEditingController(text: value),
                      readOnly: true,
                      onTap: () => provider.pickDate(context),
                      decoration: InputDecoration(
                        labelText: 'Date of Birth (YYYY-MM-DD)',
                        border: _purpleOutlineBorder(),
                        enabledBorder: _purpleOutlineBorder(),
                        focusedBorder: _purpleOutlineBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Address
                TextFormField(
                  controller: provider.addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: _purpleOutlineBorder(),
                    enabledBorder: _purpleOutlineBorder(),
                    focusedBorder: _purpleOutlineBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Contact Number
                TextFormField(
                  controller: provider.contactController,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    border: _purpleOutlineBorder(),
                    enabledBorder: _purpleOutlineBorder(),
                    focusedBorder: _purpleOutlineBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),

                // Role display
                Text(
                  'Role: ${provider.role ?? 'Unknown'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),

                // Save Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => provider.updateProfile(context),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  OutlineInputBorder _purpleOutlineBorder() {
    return OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.blueAccent),
      borderRadius: BorderRadius.circular(8),
    );
  }
}
