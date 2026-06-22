import 'package:acafe_customer/features/address/domain/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/features/address/providers/location_provider.dart';
import 'package:acafe_customer/utill/color_resources.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:acafe_customer/helper/custom_snackbar_helper.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class DeleteConfirmationDialogWidget extends StatelessWidget {
  final AddressModel addressModel;
  final int index;
  const DeleteConfirmationDialogWidget({super.key, required this.addressModel, required this.index});
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: SizedBox(
        width: 300,
        child: Column(mainAxisSize: MainAxisSize.min, children: [

          const SizedBox(height: 20),
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.contact_support, size: 50),
          ),

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: FittedBox(
              child: Text(getTranslated('want_to_delete', context)!, style: rubikRegular, textAlign: TextAlign.center, maxLines: 1),
            ),
          ),

          Divider(height: 0, color: ColorResources.getHintColor(context)),

           Row(children: [

            Expanded(child: InkWell(
              onTap: () {
                showDialog(context: context, barrierDismissible: false, builder: (context) => Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                  ),
                ));
                Provider.of<LocationProvider>(context, listen: false).deleteUserAddressByID(addressModel.id, index, (bool isSuccessful, String message) {
                  context.pop();
                  showCustomSnackBarHelper(message, isError: !isSuccessful);
                  context.pop();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                alignment: Alignment.center,
                decoration: const BoxDecoration(borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10))),
                child: Text(getTranslated('yes', context)!, style: rubikBold.copyWith(color: Theme.of(context).primaryColor)),
              ),
            )),

            Expanded(child: InkWell(
              onTap: () => context.pop(),
              child: Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: const BorderRadius.only(bottomRight: Radius.circular(10)),
                ),
                child: Text(getTranslated('no', context)!, style: rubikBold.copyWith(color: Colors.white)),
              ),
            )),

          ])
        ]),
      ),
    );
  }
}
