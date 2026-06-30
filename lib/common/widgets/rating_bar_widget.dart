import 'package:flutter/material.dart';
import 'package:acafe_customer/utill/color_resources.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';

class RatingBarWidget extends StatelessWidget {
  final double rating;
  final double size;
  final double fontSize;

  const RatingBarWidget({super.key, required this.rating, this.size = 18, this.fontSize =  Dimensions.fontSizeSmall});

  @override
  Widget build(BuildContext context) {

    return rating > 0 ? Row(mainAxisSize: MainAxisSize.min, children: [

      Text(rating.toStringAsFixed(1), style: rubikSemiBold.copyWith(fontSize: fontSize)),
      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

      Icon(Icons.star, color: ColorResources.getSecondaryColor(context), size: size),

    ]) : const SizedBox();
  }
}

