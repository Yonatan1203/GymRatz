import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final results = snapshot.data!;
        final isOffline =
            results.contains(ConnectivityResult.none) || results.isEmpty;

        if (!isOffline) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
          color: Colors.orange.shade800,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 14.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                'You\'re offline \u2014 data will sync when connected',
                style: TextStyle(color: Colors.white, fontSize: 12.sp),
              ),
            ],
          ),
        );
      },
    );
  }
}
