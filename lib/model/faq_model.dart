import 'package:customer/model/language_description.dart';
import 'package:customer/model/language_title.dart';

class FaqModel {
  List<LanguageDescription>? description;
  bool? enable;
  String? id;
  List<LanguageTitle>? title;
  bool? isShow;

  FaqModel({this.description, this.enable, this.id, this.title, this.isShow});

  FaqModel.fromJson(Map<String, dynamic> json) {
    enable = json['enable'];
    id = json['id'];
    if (json['title'] != null) {
      title = <LanguageTitle>[];
      json['title'].forEach((v) {
        title!.add(LanguageTitle.fromJson(v));
      });
    }

    if (json['description'] != null) {
      description = <LanguageDescription>[];
      json['description'].forEach((v) {
        description!.add(LanguageDescription.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (description != null) {
      data['description'] = description!.map((v) => v.toJson()).toList();
    }
    data['enable'] = enable;
    data['id'] = id;
    if (title != null) {
      data['title'] = title!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
