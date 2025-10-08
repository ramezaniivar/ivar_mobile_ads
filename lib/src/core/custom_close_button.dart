import 'package:flutter/material.dart';

import 'constants.dart';

class CustomCloseButton extends StatelessWidget {
  const CustomCloseButton(
      {super.key,
      required this.maxTime,
      required this.currentTime,
      required this.onTap,
      this.isRtl});
  final VoidCallback onTap;
  final int maxTime;
  final int currentTime;
  final bool? isRtl;

  double _calculateAdTimeProgress({
    required double maxTime,
    required double currentTime,
  }) {
    if (maxTime <= 0) return 0;
    double progress = currentTime / maxTime;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isComplated = currentTime == 0;

    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedSwitcher(
          duration: Duration(milliseconds: 400),
          child: InkWell(
            onTap: isComplated ? onTap : null,
            borderRadius: BorderRadius.circular(30),
            child: Container(
              height: 30,
              width: isComplated ? null : 30,
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white70, width: 1.5),
                color: Colors.white60,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 5,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 400),
                  child: isComplated
                      ? Row(
                          spacing: 2,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Close',
                              style: TextStyle(
                                color: Color.fromARGB(255, 29, 29, 36),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(
                              Icons.close,
                              size: 18,
                              color: Color.fromARGB(255, 29, 29, 36),
                            ),
                          ],
                        )
                      : SizedBox()
                  // : Text(
                  //     isRtl ?? false
                  //         ? Constants.convertToPersianNumbers(
                  //             currentTime.toString())
                  //         : currentTime.toString(),
                  //     maxLines: 1,
                  //     style: TextStyle(
                  //       color: Color.fromARGB(255, 29, 29, 36),
                  //       fontSize: 12,
                  //       fontWeight: FontWeight.w600,
                  //       fontFamily: isRtl ?? false ? 'Vazir' : null,
                  //       package: 'ivar_mobile_ads',
                  //     ),
                  //   ),
                  ),
            ),
          ),
        ),

        //progress
        if (!isComplated)
          Positioned.fill(
            left: 1,
            top: 1,
            right: 1,
            bottom: 1,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.amberAccent,
              value: _calculateAdTimeProgress(
                maxTime: maxTime.toDouble(),
                currentTime: currentTime.toDouble(),
              ),
            ),
          ),

        //timer
        if (!isComplated)
          Text(
            isRtl ?? false
                ? Constants.convertToPersianNumbers(currentTime.toString())
                : currentTime.toString(),
            maxLines: 1,
            style: TextStyle(
              color: Color.fromARGB(255, 29, 29, 36),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: isRtl ?? false ? 'Vazir' : null,
              package: 'ivar_mobile_ads',
            ),
          ),
      ],
    );
  }
}
