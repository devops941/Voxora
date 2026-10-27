import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:voxora/core/theme/app_colors.dart';

class GoogleAccountItem {
  final String name;
  final String email;
  final String googleId;
  final String? avatarUrl;

  const GoogleAccountItem({
    required this.name,
    required this.email,
    required this.googleId,
    this.avatarUrl,
  });
}

class GoogleAccountPicker {
  static const String _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>
''';

  /// Shows the Google Account Selector bottom sheet
  static Future<GoogleAccountItem?> show(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultAccounts = [
      const GoogleAccountItem(
        name: 'Rahul Sharma',
        email: 'rahul.sharma@gmail.com',
        googleId: 'google_109283746591029384756',
      ),
      const GoogleAccountItem(
        name: 'Rahul Personal',
        email: 'rahul.dev@gmail.com',
        googleId: 'google_209182736451928374651',
      ),
    ];

    return showModalBottomSheet<GoogleAccountItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header
              Row(
                children: [
                  SvgPicture.string(_googleSvg, width: 24, height: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Text(
                  'Choose an account to continue to Voxora',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Account Items
              ...defaultAccounts.map((account) {
                return _buildAccountTile(
                  context: ctx,
                  isDark: isDark,
                  account: account,
                  onTap: () => Navigator.pop(ctx, account),
                );
              }),

              // Use another account
              _buildAddAccountTile(
                context: ctx,
                isDark: isDark,
                onAdd: (customAccount) => Navigator.pop(ctx, customAccount),
              ),

              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Legal / Consent Note
              Text(
                'To continue, Google will share your name, email address, and profile picture with Voxora. Before using Voxora, you can review our Privacy Policy and Terms of Service.',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                      : const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildAccountTile({
    required BuildContext context,
    required bool isDark,
    required GoogleAccountItem account,
    required VoidCallback onTap,
  }) {
    final initial = account.name.isNotEmpty ? account.name[0].toUpperCase() : 'G';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF4285F4),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : const Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    account.email,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildAddAccountTile({
    required BuildContext context,
    required bool isDark,
    required Function(GoogleAccountItem) onAdd,
  }) {
    return InkWell(
      onTap: () async {
        final emailController = TextEditingController();
        final nameController = TextEditingController();
        final result = await showDialog<GoogleAccountItem>(
          context: context,
          builder: (dialogCtx) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              title: const Text('Add Google Account'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      hintText: 'e.g., Rahul Sharma',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Google Email',
                      hintText: 'e.g., user@gmail.com',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final email = emailController.text.trim();
                    final name = nameController.text.trim();
                    if (email.isNotEmpty && email.contains('@')) {
                      Navigator.pop(
                        dialogCtx,
                        GoogleAccountItem(
                          name: name.isNotEmpty ? name : 'Google User',
                          email: email,
                          googleId: 'google_${DateTime.now().millisecondsSinceEpoch}',
                        ),
                      );
                    }
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );

        if (result != null) {
          onAdd(result);
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
              child: Icon(
                Icons.person_add_alt_1_outlined,
                size: 20,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Use another account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
