import 'package:amazon_clone_tutorial/features/account/widgets/account_button.dart';
import 'package:flutter/material.dart';
import 'package:amazon_clone_tutorial/features/account/services/account_services.dart';

class TopButtons extends StatelessWidget {
  const TopButtons({super.key});

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feature coming soon!')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            AccountButton(
              text: 'Your Orders',
              onTap: () => Navigator.pushNamed(context, '/orders'),
              // Replace '/orders' with actual route if you have it
            ),
            AccountButton(
              text: 'Turn Seller',
              onTap: () => _showComingSoon(context), // Assuming no route yet
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            AccountButton(
              text: 'Log Out',
              onTap: () => AccountServices().logOut(context),
            ),
            AccountButton(
              text: 'Your Wish List',
              onTap: () =>
                  _showComingSoon(context), // No route? Show coming soon
            ),
          ],
        ),
      ],
    );
  }
}
