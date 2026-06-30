import 'package:flutter/material.dart';
import 'package:acafe_kiosk/common/models/api_response_model.dart';
import 'package:acafe_kiosk/features/notification/domain/models/notification_model.dart';
import 'package:acafe_kiosk/features/notification/domain/reposotories/notification_repo.dart';
import 'package:acafe_kiosk/helper/api_checker_helper.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepo? notificationRepo;
  NotificationProvider({required this.notificationRepo});

  List<NotificationModel>? _notificationList;
  List<NotificationModel>? get notificationList => _notificationList != null ? _notificationList?.reversed.toList() : _notificationList;

  // Unread badge count surfaced on the app-bar notification bell.
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  void _recountUnread() {
    _unreadCount = _notificationList == null
        ? 0
        : _notificationList!.where((n) => (n.isRead ?? 0) == 0).length;
  }

  Future<void> getNotificationList(BuildContext context) async {
    ApiResponseModel apiResponse = await notificationRepo!.getNotificationList();

    if (apiResponse.response?.statusCode == 200) {
      _notificationList = [];
      apiResponse.response!.data.forEach((notificationModel) => _notificationList!.add(NotificationModel.fromJson(notificationModel)));
      _recountUnread();
      notifyListeners();
    } else {
      ApiCheckerHelper.checkApi(apiResponse);
    }
  }

  /// Called when a live FCM notification arrives so the bell badge updates
  /// without the user refreshing. Increments the unread count immediately and
  /// (best-effort) re-pulls the persisted list so history stays in sync.
  void onRealtimeNotification({BuildContext? context}) {
    _unreadCount++;
    notifyListeners();
    if (context != null) {
      getNotificationList(context);
    }
  }

  /// Marks notifications as read locally and on the server, then clears/decrements
  /// the unread badge. Pass [id] for a single notification, or omit to clear all.
  Future<void> markAsRead({int? id}) async {
    if (_unreadCount == 0 && (id == null)) return;

    if (_notificationList != null) {
      for (final n in _notificationList!) {
        if (id == null || n.id == id) {
          n.isRead = 1;
          n.status = 1;
        }
      }
    }
    _recountUnread();
    notifyListeners();

    await notificationRepo!.markAsRead(id: id);
  }
}
