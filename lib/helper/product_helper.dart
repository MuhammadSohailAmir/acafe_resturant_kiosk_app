import 'package:acafe_kiosk/common/models/product_model.dart';
import 'package:acafe_kiosk/features/kiosk/screens/kiosk_product_customize_sheet.dart';
import 'package:acafe_kiosk/helper/date_converter_helper.dart';
import 'package:acafe_kiosk/main.dart';

class ProductHelper{
  static bool isProductAvailable({required Product product})=>
      product.availableTimeStarts != null && product.availableTimeEnds != null
          ? DateConverterHelper.isAvailable(product.availableTimeStarts!, product.availableTimeEnds!) : false;

   static void addToCart({required int cartIndex, required Product product}) {
     if (Get.context != null) {
       openKioskCustomize(Get.context!, product, cartIndex: cartIndex);
     }
  }

  static ({List<Variation>? variatins, double? price}) getBranchProductVariationWithPrice(Product? product){

    List<Variation>? variationList;
    double? price;

    if(product?.branchProduct != null && (product?.branchProduct?.isAvailable ?? false)) {
      variationList = product?.branchProduct?.variations;
      price = product?.branchProduct?.price;

    }else{
      variationList = product?.variations;
      price = product?.price;
    }

    return (variatins: variationList, price: price);
  }


}