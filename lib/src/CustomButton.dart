import 'package:flutter/material.dart';

class CustomButton {
  static ButtonStyle DefaultButton(Color backgroundColor) {
    return ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
        ),
      ),
      elevation: WidgetStateProperty.all<double>(10),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.fromLTRB(100, 12, 100, 12)),
      backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
    );
  }

  static ButtonStyle WhiteButton(Color backgroundColor) {
    return ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30)),
          side: BorderSide(
              color: Colors.black, width: 1), // Tambahkan border hitam
        ),
      ),
      elevation: WidgetStateProperty.all<double>(10),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.fromLTRB(100, 12, 100, 12)),
      backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
    );
  }

  static ButtonStyle NewModel(Color backgroundColor) {
    return ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      elevation: WidgetStateProperty.all<double>(10),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.fromLTRB(20, 10, 20, 10)),
      backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
    );
  }

  static ButtonStyle GoogleButton(Color backgroundColor) {
    return ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      elevation: WidgetStateProperty.all<double>(5),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.fromLTRB(10, 0, 10, 0)),
      backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
    );
  }

  static ButtonStyle miniButton(Color backgroundColor) {
    return ButtonStyle(
      shape: WidgetStateProperty.all<OutlinedBorder>(
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
      elevation: WidgetStateProperty.all<double>(5),
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(
          const EdgeInsets.fromLTRB(10, 0, 10, 0)),
      backgroundColor: WidgetStateProperty.all<Color>(backgroundColor),
    );
  }
}
