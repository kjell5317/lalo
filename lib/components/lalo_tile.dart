import 'package:flutter/material.dart';

class LaloTile extends StatelessWidget {
  const LaloTile(
      {Key? key,
      required this.onTap,
      required this.color,
      required this.text,
      required this.icon})
      : super(key: key);

  final Function() onTap;
  final Color color;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
