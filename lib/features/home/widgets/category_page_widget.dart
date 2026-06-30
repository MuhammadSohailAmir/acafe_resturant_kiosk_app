import 'package:flutter/material.dart';
import 'package:acafe_customer/common/providers/theme_provider.dart';
import 'package:acafe_customer/common/widgets/custom_image_widget.dart';
import 'package:acafe_customer/common/widgets/on_hover_widget.dart';
import 'package:acafe_customer/features/category/providers/category_provider.dart';
import 'package:acafe_customer/features/splash/providers/splash_provider.dart';
import 'package:acafe_customer/helper/responsive_helper.dart';
import 'package:acafe_customer/helper/router_helper.dart';
import 'package:acafe_customer/localization/language_constrants.dart';
import 'package:acafe_customer/utill/color_resources.dart';
import 'package:acafe_customer/utill/dimensions.dart';
import 'package:acafe_customer/utill/images.dart';
import 'package:acafe_customer/utill/styles.dart';
import 'package:provider/provider.dart';

class CategoryPageWidget extends StatefulWidget {
  final CategoryProvider categoryProvider;

  const CategoryPageWidget({super.key, required this.categoryProvider});

  @override
  State<CategoryPageWidget> createState() => _CategoryPageWidgetState();
}

class _CategoryPageWidgetState extends State<CategoryPageWidget> {
  int categoryLength = 0;



  @override
  Widget build(BuildContext context) {

    final isDesktop = ResponsiveHelper.isDesktop(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);


    categoryLength  = widget.categoryProvider.categoryList!.length;


    final SplashProvider splashProvider = Provider.of<SplashProvider>(context, listen: false);

    return Column(mainAxisSize: MainAxisSize.min,mainAxisAlignment: MainAxisAlignment.center, children: [

        const SizedBox(height: Dimensions.paddingSizeDefault),
        Center(child: Text(getTranslated('dish_discoveries', context)!, textAlign: TextAlign.center, style: rubikBold.copyWith(
          fontSize: isDesktop ? Dimensions.fontSizeExtraLarge : Dimensions.fontSizeDefault,
          color: themeProvider.darkTheme ? Theme.of(context).primaryColor : ColorResources.homePageSectionTitleColor
        ))),
        SizedBox(height: isDesktop ? Dimensions.paddingSizeLarge : Dimensions.paddingSizeSmall),

      categoryLength < 4 ? Padding(
        padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, spacing: Dimensions.paddingSizeLarge,
          children: widget.categoryProvider.categoryList!.map((element){
            String? name = element.name;
            int index = widget.categoryProvider.categoryList!.indexOf(element);
            return _categoryItem(index: index, isDesktop: isDesktop, context: context,splashProvider:  splashProvider, name: name);
          }).toList(),
        ),
      ) : GridView.builder(
        itemCount: categoryLength > 8 ? 8 : categoryLength,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isDesktop ? 4 : ResponsiveHelper.isTab(context) ? 8 : 4,
          mainAxisExtent: isDesktop ? 150 : 110,
        ),
        padding: EdgeInsets.zero,
        itemBuilder: (context, index) {
          String? name = widget.categoryProvider.categoryList![index].name;
          return _categoryItem(index: index, isDesktop: isDesktop, context: context,splashProvider:  splashProvider, name: name);
        },
      ),
    ]);
  }

  Column _categoryItem({required int index, required bool isDesktop, required BuildContext context, required SplashProvider splashProvider, String? name}) {
    return Column(mainAxisSize: MainAxisSize.min, children: [

          InkWell(
            onTap: () {
              if( index== 7){
                RouterHelper.getAllCategoryRoute();
              }else{
                RouterHelper.getCategoryRoute(widget.categoryProvider.categoryList![index]);
              }
            },
            borderRadius: BorderRadius.circular(50),
            child: isDesktop ? OnHoverWidget(builder: (isHoverActive) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 84, width: 84,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: isHoverActive ? Theme.of(context).primaryColor : Colors.transparent, width: 2),
                  boxShadow: [BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: isHoverActive ? 0.28 : 0.16),
                    blurRadius: isHoverActive ? 22 : 16, offset: const Offset(0, 6),
                  )],
                ),
                child: ClipOval(
                  child: index == 7 ? Container(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                    alignment: Alignment.center,
                    child: Image.asset(Images.cutlery, width: 36, height: 36),
                  ) : CustomImageWidget(
                    height: 78, width: 78, fit: BoxFit.cover,
                    image: splashProvider.baseUrls != null
                        ? '${splashProvider.baseUrls!.categoryImageUrl}/${widget.categoryProvider.categoryList![index].image}' : '',
                  ),
                ),
              );
            }) : Container(
              height: 64, width: 64,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                boxShadow: [BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.16),
                  blurRadius: 16, offset: const Offset(0, 6),
                )],
              ),
              child: ClipOval(
                child: index == 7 ? Container(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                  alignment: Alignment.center,
                  child: Image.asset(Images.cutlery, width: 28, height: 28),
                ) : CustomImageWidget(
                  height: 58, width: 58, fit: BoxFit.cover,
                  image: splashProvider.baseUrls != null
                      ? '${splashProvider.baseUrls!.categoryImageUrl}/${widget.categoryProvider.categoryList![index].image}' : '',
                ),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          index == 7 ? Text(getTranslated("More", context)!, maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: rubikSemiBold.copyWith(
              fontSize: isDesktop ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall,
              color: Theme.of(context).primaryColor,
            ),) : Text(name!, maxLines: 1, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis, style: rubikSemiBold.copyWith(
            fontSize: isDesktop ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall,
          )),
        ]);
  }
}
