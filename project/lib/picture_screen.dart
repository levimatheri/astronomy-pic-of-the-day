import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/picture.dart';

class PictureScreen extends StatefulWidget {
  final Picture picture;

  PictureScreen({@required this.picture});

  @override
  _PictureScreenState createState() => _PictureScreenState();
}

class _PictureScreenState extends State<PictureScreen> {
  // declare field to hold Picture object.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.widget.picture.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.info),
            onPressed: () async {
              await _launchUrl("https://apod.nasa.gov/apod/ap${this.widget.picture.date.substring(2).replaceAll('-', '')}.html");
            }
          ),
          PopupMenuButton<Choice>(
            itemBuilder: (BuildContext context) {
              return choices.map((choice) {
                return PopupMenuItem<Choice>(
                  value: choice,
                  child: Text(choice.title),
                );
              }).toList();
            },
            onSelected: (value) {
              print("Value:${value.title}");
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: this.widget.picture.mediaType == "image"
                ? NetworkImage(this.widget.picture.imageUrl)
                : NetworkImage(
                "https://astronaut.com/wp-content/uploads/2020/02/1200px-NASA_logo.svg-1024x857.png"),
            fit: BoxFit.cover
          ),
        ),

      ),
    );
  }

  _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

class Choice {
  final String title;
  final IconData icon;

  const Choice({this.title, this.icon});
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Download', icon: Icons.file_download),
  const Choice(title: 'Lock screen', icon: Icons.lock_outline),
  const Choice(title: 'Home screen', icon: Icons.home),
  const Choice(title: 'Home & lock screen', icon: Icons.lock),
];
