import 'package:flutter/material.dart';
import 'package:kpsslingo/core/theme/app_dimensions.dart';

class Gaps {
  static const Widget xs  = SizedBox(height: AppDimensions.xs,  width: AppDimensions.xs);
  static const Widget sm  = SizedBox(height: AppDimensions.sm,  width: AppDimensions.sm);
  static const Widget md  = SizedBox(height: AppDimensions.md,  width: AppDimensions.md);
  static const Widget lg  = SizedBox(height: AppDimensions.lg,  width: AppDimensions.lg);
  static const Widget xl  = SizedBox(height: AppDimensions.xl,  width: AppDimensions.xl);
  static const Widget xxl = SizedBox(height: AppDimensions.xxl, width: AppDimensions.xxl);
  static const Widget xxxl = SizedBox(height: 60, width: 60);

  static Widget h(double v) => SizedBox(height: v);
  static Widget w(double v) => SizedBox(width: v);
}
