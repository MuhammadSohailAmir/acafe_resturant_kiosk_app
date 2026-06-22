class NotificationModel {
  int? id;
  String? title;
  String? description;
  String? image;
  int? status;
  String? type;
  String? orderId;
  int? isRead;
  String? createdAt;
  String? updatedAt;

  NotificationModel(
      {this.id,
        this.title,
        this.description,
        this.image,
        this.status,
        this.type,
        this.orderId,
        this.isRead,
        this.createdAt,
        this.updatedAt});

  NotificationModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    image = json['image'];
    status = json['status'];
    type = json['type'];
    orderId = json['order_id']?.toString();
    // `is_read` comes from per-customer notifications; falls back to `status`
    // (1 = read) for the global notification shape.
    isRead = json['is_read'] ?? json['status'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['image'] = image;
    data['status'] = status;
    data['type'] = type;
    data['order_id'] = orderId;
    data['is_read'] = isRead;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}
