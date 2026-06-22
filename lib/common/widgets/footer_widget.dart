import 'package:flutter/material.dart';
import 'package:acafe_customer/common/models/config_model.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/features/language/providers/localization_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:acafe_customer/common/widgets/on_hover_widget.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class FooterWidget extends StatefulWidget {
  const FooterWidget({super.key});

  @override
  State<FooterWidget> createState() => _FooterWidgetState();
}

class _FooterWidgetState extends State<FooterWidget> {
  List<LinkModel> quickLinks = [
    LinkModel(title: 'contact_us', route: ()=> RouterHelper.getSupportRoute()),
    LinkModel(title: 'privacy_policy', route: ()=> RouterHelper.getPolicyRoute()),
    LinkModel(title: 'terms_and_condition', route: ()=> RouterHelper.getTermsRoute()),
    LinkModel(title: 'about_us', route: ()=> RouterHelper.getAboutUsRoute()),
  ];

  List<LinkModel> accountLink = [
    LinkModel(title: 'profile', route: ()=> RouterHelper.getProfileRoute()),
    LinkModel(title: 'address', route: ()=> RouterHelper.getAddressRoute()),
    LinkModel(title: 'live_chat', route: ()=> RouterHelper.getChatRoute()),
    LinkModel(title: 'my_order', route: ()=> RouterHelper.getDashboardRoute('order')),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final ConfigModel configModel =  Provider.of<SplashProvider>(context, listen: false).configModel!;
    final isLtr = Provider.of<LocalizationProvider>(context, listen: false).isLtr;
    final paddingSizeWidth = (MediaQuery.of(context).size.width - Dimensions.webScreenWidth) / 2;

    final textColor = Colors.white.withValues(alpha:0.7);


    return Stack(children: [
      Container(
        margin: const EdgeInsets.only(top: 50),
        padding: const EdgeInsets.only(top: 50, bottom: 20),
        width: double.maxFinite,
        decoration: BoxDecoration(
          color: Colors.black,
          image: DecorationImage(
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha:0.2), BlendMode.dstATop),
            image: const AssetImage(Images.footerBackgroundImage), fit: BoxFit.cover,
          ),
        ),
        child: Center(child: Column(
          children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: paddingSizeWidth),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                SizedBox(width: Dimensions.webScreenWidth, child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Expanded(flex: 5, child: Padding(
                      padding: EdgeInsets.only(
                        right: isLtr ?  Dimensions.paddingSizeDefault : 0,
                        left: isLtr ?  Dimensions.paddingSizeDefault : 0,
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const SizedBox(height: Dimensions.paddingSizeSmall),

                        Provider.of<SplashProvider>(context).baseUrls != null ?  Consumer<SplashProvider>(
                          builder:(context, splash, child) => ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                            child: CustomImageWidget(
                              image: '${splash.baseUrls?.restaurantImageUrl}/${splash.configModel!.restaurantLogo}',
                              placeholder: Images.webAppBarLogo,
                              fit: BoxFit.contain,
                              width: 120, height: 70,
                            ),
                          ),
                        ) : const SizedBox(),


                        const SizedBox(height: Dimensions.paddingSizeSmall),
                        if(configModel.footerDescription?.isNotEmpty ?? false) Text(
                          (configModel.footerDescription ?? '').replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n'),
                          style: rubikRegular.copyWith(
                            color: textColor, fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeLarge),



                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          if(configModel.socialMediaLink!.isNotEmpty) Text(getTranslated('follow_us_on', context)!, style: rubikRegular.copyWith(
                            color: Colors.white, fontSize: Dimensions.fontSizeSmall,
                          )),

                          SizedBox(height: 50, child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemCount: configModel.socialMediaLink!.length,
                            itemBuilder: (BuildContext context, index){
                              String? icon = Images.getShareIcon(configModel.socialMediaLink![index].name ?? '');

                              return  configModel.socialMediaLink!.isNotEmpty && icon.isNotEmpty ? InkWell(
                                onTap: (){
                                  _launchURL(configModel.socialMediaLink![index].link!);
                                },
                                child: Padding(
                                  padding: EdgeInsets.only(left: isLtr && index  == 0 ? 0 : 4, right: !isLtr && index == 0 ? 0 : 4),
                                  child: Image.asset(icon, height: Dimensions.paddingSizeExtraLarge,
                                    width: Dimensions.paddingSizeExtraLarge, fit: BoxFit.contain,
                                  ),
                                ),
                              ):const SizedBox();

                            },)),
                        ]),
                      ],
                      ),
                    )),

                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Text(getTranslated('my_account', context)!, style: rubikBold.copyWith(color: Colors.white)),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: accountLink.map((link) => OnHoverWidget(builder: (hovered)=> Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                          child: InkWell(
                            onTap:()=> link.route(),
                            child: Text(getTranslated(link.title, context)!, style: hovered ? rubikSemiBold.copyWith(
                              color: Theme.of(context).primaryColor,
                            ) : rubikRegular.copyWith(
                              color: textColor, fontSize: Dimensions.fontSizeSmall,
                            )),
                          ),
                        ))).toList(),
                      ),
                    ])),

                    Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start,children: [
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Text(getTranslated('quick_links', context)!, style: rubikBold.copyWith(color: Colors.white)),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: quickLinks.map((link) => OnHoverWidget(builder: (hovered)=> Padding(
                          padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
                          child: InkWell(
                            onTap:()=> link.route(),
                            child: Text(getTranslated(link.title, context)!, style: hovered ? rubikSemiBold.copyWith(
                              color: Theme.of(context).primaryColor,
                            ) : rubikRegular.copyWith(
                              color: textColor, fontSize: Dimensions.fontSizeSmall,
                            )),
                          ),
                        ))).toList(),
                      ),
                    ])),


                    configModel.playStoreConfig!.status! || configModel.appStoreConfig!.status!?
                    Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Text( configModel.playStoreConfig!.status! || configModel.appStoreConfig!.status!
                          ? getTranslated('download_our_apps', context)!
                          : getTranslated('download_our_app', context)!, style: rubikBold.copyWith(
                        color: Colors.white,
                      )),
                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      Row(mainAxisAlignment: MainAxisAlignment.start,
                        children: [

                          if(configModel.playStoreConfig!.status!) InkWell(
                            onTap:() => _launchURL(configModel.playStoreConfig!.link!),
                            child: Image.asset(Images.playStore,height: 50,fit: BoxFit.contain),
                          ),
                          const SizedBox(width: Dimensions.paddingSizeDefault),

                          if(configModel.appStoreConfig!.status!) InkWell(
                            onTap:() => _launchURL(configModel.appStoreConfig!.link!),
                            child: Image.asset(Images.appStore,height: 50,fit: BoxFit.contain),
                          ),

                        ],),

                    ])) : const SizedBox(),

                  ],
                )),

              ]),
            ),

            const Divider(thickness: .5),

            SizedBox(width: (Dimensions.webScreenWidth / 1.5), child: Text(
             configModel.footerCopyright ?? '${getTranslated('copyright', context)} ${configModel.restaurantName}',
              overflow: TextOverflow.ellipsis,maxLines: 1, textAlign: TextAlign.center, style: poppinsRegular.copyWith(
              color: Colors.white.withValues(alpha:0.7), fontSize: Dimensions.fontSizeSmall,
            ),
            )),
            const SizedBox(height: Dimensions.paddingSizeDefault),
          ],
        )),
      ),




    ]);
  }
}


_launchURL(String url) async {
  if (await canLaunchUrl(Uri.parse(url))) {
    await launchUrl(Uri.parse(url));
  } else {
    throw 'Could not launch $url';
  }
}

class LinkModel{
  final String title;
  final Function route;

  LinkModel({required this.title, required this.route});

}


