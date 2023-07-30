import 'package:flutter/material.dart';

import 'package:lalo/services/globals.dart';

class LaloAppBar extends StatelessWidget implements PreferredSizeWidget {
  const LaloAppBar({Key? key, required this.name}) : super(key: key);
  final String name;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(name),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: CircleAvatar(
              backgroundColor: Colors.grey[400],
              child: Text(
                user!.displayName?.substring(0, 2).toUpperCase() ?? 'HI',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
