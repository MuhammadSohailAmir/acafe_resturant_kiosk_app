import 'package:flutter/material.dart';
import 'package:acafe_customer/common/widgets/custom_asset_image_widget.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/features/chat/domain/models/conversation_model.dart';
import 'package:acafe_customer/features/chat/providers/chat_provider.dart';
import 'package:acafe_customer/features/order/domain/models/order_model.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/date_converter_helper.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

class ChatItemWidget extends StatelessWidget {
  final DeliverymanConversation? deliverymanConversation;
  final bool isSelected;
  final bool fromSplash;

  const ChatItemWidget({
    super.key, this.deliverymanConversation, required this.isSelected, this.fromSplash = false,
  });


  @override
  Widget build(BuildContext context) {
    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);
    final ChatProvider chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return Stack(children: [


      Material(
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        child: Stack(children: [
          InkWell(
            onTap: () {

              if(ResponsiveHelper.isDesktop(context)) {
                chatProvider.onChangeCurrentDeliveryMan(DeliveryMan(
                  fName: deliverymanConversation?.order?.deliveryMan?.fName,
                  lName: deliverymanConversation?.order?.deliveryMan?.lName,
                  image: deliverymanConversation?.order?.deliveryMan?.image,
                ));
                chatProvider.onChangeChatOrderId(deliverymanConversation?.orderId, isUpdate: true);
                chatProvider.getMessages(context, 1, deliverymanConversation?.orderId ?? -1, true, isUpdate: true);

              }else {
                RouterHelper.getChatRoute(
                  fromSplash: fromSplash,
                  orderId: deliverymanConversation?.orderId ?? -1,
                  action: RouteAction.pushReplacement,
                );

              }

            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge, vertical: Dimensions.paddingSizeSmall),
              child: Row(children: [

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    shape: BoxShape.circle,
                  ),
                  width: 50, height: 50,
                  child:  Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                    child: CustomImageWidget(
                      fit: BoxFit.contain,
                      image: '${splashProvider.baseUrls?.deliveryManImageUrl}/${deliverymanConversation?.order?.deliveryMan?.image}',
                      placeholder: deliverymanConversation == null ? Images.logo : Images.placeholderUser,
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),

                Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(
                      deliverymanConversation == null ? getTranslated('admin', context)! :
                      '${deliverymanConversation?.order?.deliveryMan?.fName} ${deliverymanConversation?.order?.deliveryMan?.lName}',
                      style: rubikSemiBold.copyWith(fontSize: Dimensions.fontSizeSmall, color: isSelected ? Theme.of(context).cardColor : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: Dimensions.paddingSizeDefault),


                    if(deliverymanConversation != null || chatProvider.conversationModel?.adminLastConversation?.updatedAt != null) Text(
                      DateConverterHelper.localDateToIsoStringAMPM(deliverymanConversation == null
                          ? chatProvider.conversationModel!.adminLastConversation!.updatedAt!.toLocal()
                          : deliverymanConversation!.updatedAt!.toLocal(), context),
                      style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: isSelected ? Theme.of(context).cardColor : null),
                    ),
                  ]),
                  const SizedBox(height: Dimensions.paddingSizeExtraSmall),



                  if(deliverymanConversation != null) ...[
                    Row(children: [
                      Text('${getTranslated('order_id', context)} : ${deliverymanConversation?.orderId}', style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeSmall),),
                    ]),
                    const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                  ],


                  Row(children: [

                    Expanded(child: Text(
                      deliverymanConversation == null
                          ? chatProvider.conversationModel?.adminLastConversation?.message ?? ''
                          : (deliverymanConversation?.messages?.isNotEmpty ?? false) ? deliverymanConversation?.messages?.first.message  ?? '' : '',
                      style: rubikRegular.copyWith(fontSize: Dimensions.fontSizeExtraSmall, color: isSelected ? Theme.of(context).cardColor : null),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )),

                  ]),

                ])),

              ]),
            ),
          ),

        ]),
      ),

      if(isSelected) Positioned(
        top: 0, left: 0,
        child: CustomAssetImageWidget(Images.pinSvg, width: 20, height: 20, color: Theme.of(context).cardColor),
      ),
    ]);
  }
}