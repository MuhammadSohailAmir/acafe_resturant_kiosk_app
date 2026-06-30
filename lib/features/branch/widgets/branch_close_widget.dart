import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_kiosk/localization/language_constrants.dart';
import 'package:acafe_kiosk/utill/dimensions.dart';
import 'package:acafe_kiosk/utill/images.dart';
import 'package:acafe_kiosk/utill/styles.dart';

class BranchCloseWidget extends StatelessWidget {
  const BranchCloseWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,children: [

                const CustomAssetImageWidget(Images.branchClose),
                const SizedBox(height: Dimensions.paddingSizeSmall),

                Text(
                  getTranslated('all_our_branches', context)!,
                  style: rubikSemiBold.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeLarge),
                ),

              ]),
            ),
          ),
        ],
      ),
    );
  }
}