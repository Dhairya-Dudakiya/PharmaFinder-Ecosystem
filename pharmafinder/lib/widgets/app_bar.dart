import 'package:flutter/material.dart';
import 'package:pharmafinder/utils/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showNotifications;

  const CustomAppBar({super.key, this.showNotifications = true});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme().primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.medical_services,
              color: AppTheme.lightTheme().primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'PharmaFinder',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppTheme.lightTheme().primaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: showNotifications
          ? [
              Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_none,
                      size: 28,
                      color: Colors.grey[700],
                    ),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 12,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF44336),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ]
          : null,
    );
  }
}
