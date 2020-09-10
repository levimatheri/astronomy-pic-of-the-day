import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:downloads_path_provider/downloads_path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as path;
import 'package:wallpaper_manager/wallpaper_manager.dart';

import 'helpers/helper.dart';
import 'models/picture.dart';

class PictureScreen extends StatefulWidget {
  final Picture picture;

  PictureScreen({@required this.picture});

  @override
  _PictureScreenState createState() => _PictureScreenState();
}

class _PictureScreenState extends State<PictureScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iOS = IOSInitializationSettings();
    final initSettings = InitializationSettings(android, iOS);

    flutterLocalNotificationsPlugin.initialize(initSettings,
        onSelectNotification: _onSelectNotification);
  }

  String progress = "-";
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Builder(builder: (context) {
          return AppBar(
            title: Text(this.widget.picture.title),
            actions: <Widget>[
              IconButton(
                  icon: Icon(Icons.info),
                  onPressed: () async {
                    await _launchUrl(
                        "https://apod.nasa.gov/apod/ap${this.widget.picture.date.substring(2).replaceAll('-', '')}.html");
                  }),
              this.widget.picture.mediaType == "image" ? PopupMenuButton<Choice>(
                itemBuilder: (BuildContext context) {
                  return choices.map((choice) {
                    return PopupMenuItem<Choice>(
                      value: choice,
                      child: Text(choice.title),
                    );
                  }).toList();
                },
                onSelected: (value) async {
                  switch (value.title) {
                    // DOWNLOAD FILE
                    case 'Download':
                      {
                        final DownloadAlertDialog alertDialog =
                            DownloadAlertDialog(progress: progress);
                        showDialog<void>(
                            context: context,
                            builder: (_) {
                              return alertDialog;
                        });
                        download(
                            path.basename(this.widget.picture.imageUrl),
                            this.widget.picture.imageUrl,
                            alertDialog.onReceiveProgress);
                      }
                      break;
                    // SET HOME SCREEN WALLPAPER
                    case "Home screen":
                      {
                        await setWallpaper(context, WallpaperManager.HOME_SCREEN,
                            "Home screen set successfully!");
                      }
                      break;
                    // SET LOCK SCREEN WALLPAPER
                    case "Lock screen":
                      {
                        await setWallpaper(context, WallpaperManager.LOCK_SCREEN,
                            "Lock screen set successfully!");
                      }
                      break;
                    // SET HOME & LOCK SCREEN WALLPAPER
                    case "Home & lock screen":
                      {
                        await setWallpaper(context, WallpaperManager.BOTH_SCREENS,
                            "Home and lock screens set successfully!");
                      }
                      break;
                  }
                },
              ) : Container()
            ],
          );
        }),
      ),
      body: this.widget.picture.mediaType == "image"
          ? Container(
              decoration: BoxDecoration(
              image: DecorationImage(
                  image: NetworkImage(this.widget.picture.imageUrl),
                  fit: BoxFit.cover),
            ))
          : Container(
              child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          "Format is not supported :(",
                          style: TextStyle(fontSize: 18.0),
                        ),
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      RaisedButton(
                        onPressed: () async {
                          await _launchUrl(this.widget.picture.imageUrl);
                        },
                        child: Text("Open in browser"),
                        color: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(18.0),
                          side: BorderSide(color: Colors.black),
                        ),
                        padding: EdgeInsets.all(20.0),
                      ),
                    ],
                  )
                ],
              ),
            )),
    );
  }

  Future<void> setWallpaper(
      BuildContext context, int location, String successMessage) async {
    String result;
    try {
      var file = await DefaultCacheManager()
          .getSingleFile(this.widget.picture.imageUrl);
      result = await WallpaperManager.setWallpaperFromFile(file.path, location);
      if (result == 'Wallpaper set') {
        Helper.showToast(context, successMessage);
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Error'),
            content: Text('$result'),
          ),
        );
      }
    } on PlatformException {
      result = 'Failed to obtain wallpaper.';
    }
    return result;
  }

//  showToast(BuildContext context, String message) {
//    final scaffold = Scaffold.of(context);
//    scaffold.showSnackBar(SnackBar(
//      content: Text(message),
//    ));
//  }

  // get device default download directory
  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      return await DownloadsPathProvider.downloadsDirectory;
    }

    return await getApplicationDocumentsDirectory();
  }

  Future<bool> _requestPermissions() async {
    // check for permission to access to storage. If not granted, request it
    var permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.storage);

    if (permission != PermissionStatus.granted) {
      await PermissionHandler().requestPermissions([PermissionGroup.storage]);
      permission = await PermissionHandler()
          .checkPermissionStatus(PermissionGroup.storage);
    }

    return permission == PermissionStatus.granted;
  }

  download(
      String pictureName, String pictureUrl, Function onReceiveProgress) async {
    // download
    final dir = await _getDownloadDirectory();
    final isPermissionStatusGranted = await _requestPermissions();

    if (isPermissionStatusGranted) {
      final savePath = path.join(dir.path, pictureName);
      await _startDownload(savePath, pictureUrl, onReceiveProgress);
    } else {}
  }

  _startDownload(
      String savePath, String fileUrl, Function onReceiveProgress) async {
    Map<String, dynamic> result = {
      'isSuccess': false,
      'filePath': null,
      'error': null,
    };

    final Dio _dio = new Dio();

    try {
      // download file from URL and update progress with onReceiveProgress callback
      final response = await _dio.download(fileUrl, savePath,
          onReceiveProgress: onReceiveProgress);

      result['isSuccess'] = response.statusCode == 200;
      result['filePath'] = savePath;
      // result['fileName'] = fileName;

      if (result['isSuccess']) {
        Navigator.pop(context); // close progress dialog
      }
    } catch (ex) {
      result['error'] = ex.toString();
    } finally {
      await _showNotification(result);
    }
  }

  _showNotification(Map<String, dynamic> downloadStatus) async {
    final android = AndroidNotificationDetails(
        'channel id', 'channel name', 'channel description',
        priority: Priority.High, importance: Importance.Max);

    final iOS = IOSNotificationDetails();
    final platform = NotificationDetails(android, iOS);
    final json = jsonEncode(downloadStatus);
    final isSuccess = downloadStatus['isSuccess'];

    await flutterLocalNotificationsPlugin.show(
        0,
        isSuccess ? 'Success' : 'Failure',
        isSuccess
            ? 'Picture has been downloaded successfully!'
            : 'There was an error while downloading the picture.',
        platform,
        payload: json);
  }

  Future<void> _onSelectNotification(String json) async {
    final obj = jsonDecode(json);
    //print(obj["fileName"].toString().split('.').last);
    if (obj['isSuccess']) {
      OpenFile.open(obj['filePath']);
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Error'),
          content: Text('${obj['error']}'),
        ),
      );
    }
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

class DownloadAlertDialog extends StatefulWidget {
  String progress;

  DownloadAlertDialog({@required this.progress});

  final _DownloadAlertDialogState dialogState = _DownloadAlertDialogState();

  @override
  _DownloadAlertDialogState createState() => dialogState;

  void onReceiveProgress(int received, int total) {
    dialogState.onReceiveProgress(received, total);
  }
}

class _DownloadAlertDialogState extends State<DownloadAlertDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Download"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Text('Download progress'),
            Text(
              '${this.widget.progress}',
            )
          ],
        ),
      ),
    );
  }

  // update percentage progress
  void onReceiveProgress(int received, int total) {
    if (total != -1) {
      setState(() {
        this.widget.progress =
            (received / total * 100).toStringAsFixed(0) + "%";
      });
    }
  }
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Download', icon: Icons.file_download),
  const Choice(title: 'Lock screen', icon: Icons.lock_outline),
  const Choice(title: 'Home screen', icon: Icons.home),
  const Choice(title: 'Home & lock screen', icon: Icons.lock),
];
