enum OrderStatus {
  newOrder,
  preparing,
  itemToCollect,
  onHold,
  canceled,
}

extension OrderStatusExt on OrderStatus {
  String get apiValue {
    switch (this) {
      case OrderStatus.newOrder: return 'new';
      case OrderStatus.itemToCollect: return 'item_to_collect';
      case OrderStatus.onHold: return 'on_hold';
      default: return name;
    }
  }
}