import 'package:flutter/material.dart';
import 'package:acafe_customer/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_customer/common/widgets/footer_widget.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';

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
          if(ResponsiveHelper.isDesktop(context)) const FooterWidget(),
        ],
      ),
    );
  }
}