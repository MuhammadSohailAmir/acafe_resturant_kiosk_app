import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/product_model.dart';
import 'package:acafe_customer/features/profile/providers/profile_provider.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/features/auth/providers/auth_provider.dart';
import 'package:acafe_customer/features/wishlist/providers/wishlist_provider.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:provider/provider.dart';

import '../../helper/custom_snackbar_helper.dart';

class WishButtonWidget extends StatelessWidget {
  final Product? product;
  final EdgeInsetsGeometry edgeInset;
  const WishButtonWidget({super.key, required this.product, this.edgeInset = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {

    return Consumer<WishListProvider>(builder: (context, wishList, child) {
      return Padding(padding: edgeInset, child: Material(
        // color: Theme.of(context).primaryColor.withValues(alpha:wishList.wishIdList.contains(product!.id) ? 1 : 0.2),
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
        clipBehavior: Clip.hardEdge,
        elevation: 1,
        child: InkWell(
          onTap: ()=> _onTapWishButton(context),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: wishList.wishIdList.contains(product!.id)
                ? Icon(Icons.favorite, color: Theme.of(context).primaryColor, size: Dimensions.paddingSizeDefault)
                : const Icon(Icons.favorite_border, size: Dimensions.paddingSizeDefault),
          ),
        ),
      ));
    });
  }

  void _onTapWishButton(BuildContext context, ){
    final ProfileProvider profileProvider = Provider.of<ProfileProvider>(context, listen: false);
    final WishListProvider wishListProvider = Provider.of<WishListProvider>(context, listen: false);

    if(Provider.of<AuthProvider>(context, listen: false).isLoggedIn()) {
      List<int?> productIdList =[];
      productIdList.add(product!.id);

      if(wishListProvider.wishIdList.contains(product?.id)) {
        wishListProvider.removeFromWishList(product!, (){
          profileProvider.getUserInfo(true);
        });
      }else {
        wishListProvider.addToWishList(product!, (){
          profileProvider.getUserInfo(true);
        });
      }
    }else{
      showCustomSnackBarHelper(getTranslated('now_you_are_in_guest_mode', context));
    }

  }
}
