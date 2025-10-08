import 'package:animate_do/animate_do.dart' as animate_do;
import 'package:flutter/material.dart';

import 'constants.dart';

class CustomAnimatedButton extends StatefulWidget {
  const CustomAnimatedButton(this.text,
      {super.key, this.onTap, this.bgColor, this.textColor});
  final String text;
  final Color? textColor;
  final Color? bgColor;
  final VoidCallback? onTap;

  @override
  State<CustomAnimatedButton> createState() => __CustomAnimatedButtonState();
}

class __CustomAnimatedButtonState extends State<CustomAnimatedButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: animate_do.Tada(
        infinite: true,
        duration: Duration(milliseconds: 1200),
        curve: Curves.easeInOut,
        child: Directionality(
          textDirection: Constants.isRTL(widget.text)
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: ElevatedButton(
            onPressed: widget.onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.bgColor ?? Color(0xffeaeaea),
              foregroundColor: widget.textColor ?? Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 7,
            ),
            child: Text(
              widget.text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.textColor ?? Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: Constants.isRTL(widget.text) ? 'Vazir' : null,
                package: 'ivar_mobile_ads',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
