import 'package:flutter/material.dart';
import 'package:project/models/picture.dart';
import 'package:project/picture_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Astronomy Picture of the Day',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(title: 'Recent Pictures'),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<List<Picture>> pictures;

  // @override
  // void initState() {
  //   super.initState();
  //   pictures = getPictures();
  //   print('pictures: $pictures');
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<List<Picture>>(
          future: getPictures(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Padding(
                padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 0.0),
                child: ListView.builder(
                    itemCount: snapshot.data.length,
                    itemExtent: 130,
                    itemBuilder: (context, index) {
                      Picture picture = snapshot.data[index];
                      return Card(
                          elevation: 5,
                          child: InkWell(
                            child: Container(
                              height: 100.0,
                              child: Row(
                                children: <Widget>[
                                  Container(
                                    height: 100.0,
                                    width: 100.0,
                                    decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                        image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: picture.mediaType == "image"
                                                ? NetworkImage(picture.imageUrl)
                                                : NetworkImage(
                                                "https://astronaut.com/wp-content/uploads/2020/02/1200px-NASA_logo.svg-1024x857.png"))),
                                  ),
                                  Container(
                                    height: 100,
                                    child: Padding(
                                      padding: EdgeInsets.fromLTRB(10, 2, 0, 0),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(picture.title,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          Padding(
                                            padding:
                                            EdgeInsets.fromLTRB(0, 3, 0, 3),
                                            child: Container(
                                              width: 30,
                                              decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color: Colors.teal)),
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                            EdgeInsets.fromLTRB(0, 5, 0, 2),
                                            child: Container(
                                              //width: 260,
                                              child: Text(picture.date),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PictureScreen(picture: picture,),
                                )
                              );
                            },
                          ),
                      );
                    }),
              );
            } else {
              return Container(
                child: CircularProgressIndicator(),
              );
            }
          }),
    );
  }
}
