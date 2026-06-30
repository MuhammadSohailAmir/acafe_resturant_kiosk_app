import 'package:acafe_kiosk/data/datasource/local/cache_response.dart';
import 'package:acafe_kiosk/main.dart';

class DbHelper{
  static insertOrUpdate({required String id, required CacheResponseCompanion data}) async {
    final response = await database.getCacheResponseById(id);

    if(response?.endPoint != null){
      await database.updateCacheResponse(id, data);
    }else{
      await database.insertCacheResponse(data);
    }
  }


}