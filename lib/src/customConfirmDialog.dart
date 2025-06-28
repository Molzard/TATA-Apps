import 'package:flutter/material.dart';
// import 'package:TATA/src/CustomColors.dart';

class CustomConfirmDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Ya',
    String cancelText = 'Tidak',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontFamily: 'NotoSanSemiBold',
              fontSize: 16,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'NotoSanSemiBold',
              fontSize: 14,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelText,
                style: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'NotoSanSemiBold',
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmText,
                style: const TextStyle(
                  color: Color.fromRGBO(52, 127, 77, 1),
                  fontFamily: 'NotoSanSemiBold',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
