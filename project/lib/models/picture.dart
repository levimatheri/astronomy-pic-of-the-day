import 'dart:async';
import 'dart:convert';

import 'package:global_configuration/global_configuration.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Picture {
  final String title;
  final String imageUrl;
  final String date;
  final String description;
  final String mediaType;

  Picture(
      {this.title, this.imageUrl, this.date, this.description, this.mediaType});

  factory Picture.fromJson(Map<String, dynamic> json) {
    return Picture(
      date: json["date"],
      title: json["title"],
      imageUrl: json["url"],
      description: json["explanation"],
      mediaType: json["media_type"],
    );
  }
}

Future<List<Picture>> getPictures() async {
  var pictures = new List<Picture>();
  final DateTime now = DateTime.now();

  var config = new GlobalConfiguration();
  for (var days = 0; days < config.get("days.before.count"); days++) {
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    final DateTime dateQuery = now.subtract(new Duration(days: days));
    final String dateQueryString = formatter.format(dateQuery);

    final response = await http.get(
        "${config.get("nasa.api.url")}?api_key=${config.get("nasa.api.key")}&hd=true&date=$dateQueryString");

    //print('response: ${response.body}');
    if (response.statusCode == 200) {
      pictures.add(Picture.fromJson(json.decode(response.body)));
    } else {
      throw Exception('Failed to load picture');
    }
  }

  return pictures;
}
