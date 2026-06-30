import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/config_model.dart';
import 'package:acafe_kiosk/features/cart/providers/cart_provider.dart';
import 'package:acafe_kiosk/helper/branch_helper.dart';
import 'package:acafe_kiosk/helper/responsive_helper.dart';
import 'package:acafe_kiosk/features/branch/providers/branch_provider.dart';
import 'package:acafe_kiosk/features/splash/providers/splash_provider.dart';
import 'package:acafe_kiosk/localization/language_constrants.dart';
import 'package:acafe_kiosk/utill/dimensions.dart';
import 'package:acafe_kiosk/utill/images.dart';
import 'package:acafe_kiosk/utill/styles.dart';
import 'package:acafe_kiosk/common/widgets/custom_image_widget.dart';
import 'package:acafe_kiosk/helper/custom_snackbar_helper.dart';
import 'package:provider/provider.dart';

class BranchItemWidget extends StatelessWidget {
  final BranchValue? branchesValue;
  final bool isItemChange;

  const BranchItemWidget({super.key, this.branchesValue, required this.isItemChange});

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final CartProvider cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Consumer<BranchProvider>(
      builder: (context, branchProvider, _) {
        return Material(
          type: MaterialType.transparency,
          child: InkWell(

            onTap: () async {

              if(!branchesValue!.branches!.status!){
                showCustomSnackBarHelper('${branchesValue!.branches!.name} ${getTranslated('close_now', context)}');
              }
              else if(branchesValue?.branches?.id != branchProvider.getBranchId() && cartProvider.cartList.isNotEmpty) {
                BranchHelper.dialogOrBottomSheet(
                  context,
                  onPressRight: (){
                    branchProvider.updateBranchId(branchesValue!.branches!.id);
                    BranchHelper.setBranch(context);
                    cartProvider.getCartData(context);
                  },
                  title: getTranslated('you_have_some_food', context)!,
                );
              }else if(branchesValue?.branches?.id == branchProvider.getBranchId()){
                showCustomSnackBarHelper(getTranslated('this_is_your_current_branch', context));
              }
              else if(branchesValue!.branches!.status!) {

                BranchHelper.dialogOrBottomSheet(
                  context,
                  onPressRight: (){
                    branchProvider.updateBranchId(branchesValue!.branches!.id);
                    BranchHelper.setBranch(context);
                    cartProvider.getCartData(context);
                  },
                  title: getTranslated('switch_branch_effect', context)!,
                );
              }else{
                showCustomSnackBarHelper('${branchesValue!.branches!.name} ${getTranslated('close_now', context)}');
              }

            },
            child: ResponsiveHelper.isDesktop(context) ? SizedBox(
              width: 370,
              child: Stack(clipBehavior: Clip.hardEdge, children: [
                Container(
                    margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
                    child: Material(
                      elevation: 2,
                      color: branchProvider.selectedBranchId == branchesValue!.branches!.id
                          ? Theme.of(context).primaryColor.withValues(alpha:0.1)
                          : Theme.of(context).cardColor,
                      clipBehavior: Clip.hardEdge,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Theme.of(context).primaryColor.withValues(alpha:branchProvider.selectedBranchId == branchesValue!.branches!.id ? 0.8 : 0.1), width: 2),
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Column(children: [

                        Expanded(flex: 2, child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(Dimensions.radiusDefault),
                            topLeft: Radius.circular(Dimensions.radiusDefault),
                          ),
                          child: Container(
                            color: Theme.of(context).canvasColor,
                            child: Stack(children: [
                              CustomImageWidget(
                                placeholder: Images.branchBanner,
                                fit: BoxFit.cover,
                                width: Dimensions.webScreenWidth,
                                image: '${splashProvider.baseUrls!.branchImageUrl}/${branchesValue!.branches!.coverImage}',
                              ),

                              if(!branchesValue!.branches!.status!) Container(color: Colors.black.withValues(alpha:0.6)),

                              if(!branchesValue!.branches!.status!)  Positioned.fill(
                                child: Opacity(opacity: 0.7, child: Align(
                                  alignment: Alignment.center,
                                  child: Container(
                                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.1),width: 2),
                                      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),


                                    ),
                                    child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                                      const Icon(
                                        Icons.schedule_outlined,
                                        color: Colors.white,
                                        size: Dimensions.paddingSizeDefault,
                                      ),
                                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                                      Text(
                                        getTranslated('temporary_closed', context)!,
                                        style: poppinsRegular.copyWith(
                                          fontSize: Dimensions.fontSizeSmall,
                                          color: Colors.white,
                                        ),
                                      ),

                                    ]),
                                  ),
                                )),
                              ),
                            ]),
                          ),
                        )),

                        Expanded(child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(Dimensions.radiusDefault), bottomRight: Radius.circular(Dimensions.radiusDefault),
                            ),
                          ),
                          child: const SizedBox(),

                        )),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                      ]),
                    ),
                  ),

                Positioned(
                  bottom: Dimensions.paddingSizeDefault,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        BranchLogoView(branchesValue: branchesValue),
                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(branchesValue!.branches!.name!, style: rubikSemiBold),
                          const SizedBox(height: Dimensions.paddingSizeExtraSmall),

                          Row(children: [
                            Icon(Icons.location_on, size: Dimensions.paddingSizeLarge, color: Theme.of(context).primaryColor),
                            const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                            Text(
                              branchesValue!.branches!.address != null
                                  ? branchesValue!.branches!.address!.length > 20
                                  ? '${branchesValue!.branches!.address!.substring(0, 20)}...'
                                  : branchesValue!.branches!.address! : branchesValue!.branches!.name!,
                              style: rubikRegular.copyWith(color: Theme.of(context).primaryColor, fontSize: Dimensions.fontSizeSmall),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                            ),

                          ]),
                        ]),
                      ],
                    ),
                  ),
                ),

                if(branchesValue!.distance != -1) Positioned.fill(
                  bottom: Dimensions.paddingSizeDefault,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeDefault, vertical: Dimensions.paddingSizeSmall),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        '${branchesValue!.distance.toStringAsFixed(3)} ${getTranslated('km', context)}',
                        style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeLarge),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),

                      Text(getTranslated('away', context)!, style: rubikSemiBold.copyWith(
                        fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).disabledColor,
                      )),

                    ]),
                  ),
                ),
              ]),
            ) : BranchItemViewMobile(branchesValue: branchesValue),
          ),
        );
      }
    );
  }
}

class BranchItemViewMobile extends StatelessWidget {
  final BranchValue? branchesValue;
  const BranchItemViewMobile({super.key, required this.branchesValue});

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final bool isOpen = branchesValue?.branches?.status ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeExtraSmall),
      child: Material(
        elevation: 2,
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [

        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CustomImageWidget(
              placeholder: Images.placeholderImage,
              height: 76, width: 76, fit: BoxFit.cover,
              image: '${splashProvider.baseUrls!.branchImageUrl}/${branchesValue?.branches?.image}',
            ),
          ),

          if(!isOpen) Positioned.fill(child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.black.withValues(alpha: 0.55),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.schedule_rounded, color: Colors.white, size: 22),
          )),
        ]),

        const SizedBox(width: Dimensions.paddingSizeDefault),

        Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${branchesValue?.branches?.name}', style: rubikSemiBold, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),

          Row(children: [
            Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).hintColor),
            const SizedBox(width: 3),

            Expanded(child: Text(
              '${branchesValue?.branches?.address}',
              style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall, color: Theme.of(context).hintColor),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            )),
          ]),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isOpen ? Colors.green : Theme.of(context).primaryColor).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                getTranslated(isOpen ? 'open_now' : 'close_now', context)!,
                style: rubikSemiBold.copyWith(fontSize: 10, color: isOpen ? Colors.green.shade700 : Theme.of(context).primaryColor),
              ),
            ),

            if(branchesValue!.distance != -1) ...[
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Flexible(child: Text(
                '${branchesValue!.distance.toStringAsFixed(1)} ${getTranslated('km', context)} ${getTranslated('away', context)!}',
                style: rubikRegular.copyWith(fontSize: 11, color: Theme.of(context).hintColor),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              )),
            ],
          ]),
        ])),

        const SizedBox(width: Dimensions.paddingSizeSmall),
        Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Theme.of(context).hintColor),
          ]),
        ),
      ),
    );
  }
}

class BranchLogoView extends StatelessWidget {
  const BranchLogoView({
    super.key,
    required this.branchesValue,
  });

  final BranchValue? branchesValue;

  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha:0.3)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          child: CustomImageWidget(
            placeholder: Images.placeholderImage,
            height: 80, width: 80,
            fit: BoxFit.cover,
            image: '${splashProvider.baseUrls!.branchImageUrl}/${branchesValue?.branches!.image}',
          ),

        ),
      );
  }
}
