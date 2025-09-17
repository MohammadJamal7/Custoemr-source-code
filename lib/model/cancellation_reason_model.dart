import 'package:customer/model/language_name.dart';

class CancellationReasonModel {

  String? id;
  List<LanguageName>? name;

  CancellationReasonModel({ this.id, this.name});

  CancellationReasonModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    if (json['name'] != null) {
      name = <LanguageName>[];
      json['name'].forEach((v) {
        name!.add(LanguageName.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['id'] = id;
    if (name != null) {
      data['name'] = name!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
