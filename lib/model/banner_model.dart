class BannerModel {
  String? image;
  bool? enable;
  String? id;
  int? positionDriver;
  int? positionCustomer;

  BannerModel({
    this.image,
    this.enable,
    this.id,
    this.positionDriver,
    this.positionCustomer,
  });

  BannerModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    enable = json['enable'];
    id = json['id'];
    positionDriver = _toInt(json['position_driver']);
    positionCustomer = _toInt(json['position_customer']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['image'] = image;
    data['enable'] = enable;
    data['id'] = id;
    data['position_driver'] = positionDriver;
    data['position_customer'] = positionCustomer;
    return data;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }
}

class OtherBannerModel {
  String? image;

  OtherBannerModel({
    this.image,
  });

  OtherBannerModel.fromJson(Map<String, dynamic> json) {
    image = json['image'];
  }
}
