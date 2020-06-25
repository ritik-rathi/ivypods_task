import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:photo_feed_task/ui/uploadPhoto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';

class MainFeed extends StatefulWidget {
  @override
  _MainFeedState createState() => _MainFeedState();
}

class _MainFeedState extends State<MainFeed> {
  final FlareControls flareControls = FlareControls();
  String uid;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserDetails();
  }

  getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      uid = prefs.getString('uid');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your feed'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => UploadPhoto())),
        label: Text('Add Photo'),
        icon: Icon(Icons.edit),
      ),
      body: Container(
        padding: EdgeInsets.all(8),
        child: StreamBuilder(
          stream: Firestore.instance.collection('feed').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.hasError) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.data.documents.length == 0) {
              return Center(
                child: Text('No photos found'),
              );
            } else {
              return ListView.builder(
                  itemCount: snapshot.data.documents.length,
                  itemBuilder: (context, index) {
                    String image =
                        snapshot.data.documents[index]['image'].toString();
                    bool like =
                        snapshot.data.documents[index]['likes'].contains(uid);
                    var docID = snapshot.data.documents[index].documentID;
                    String username =
                        snapshot.data.documents[index]['username'];
                    String userimage =
                        snapshot.data.documents[index]['userimage'];
                    int count = snapshot.data.documents[index]['likes'].length;
                    return post(image, like, docID, username, userimage, count);
                  });
            }
          },
        ),
      ),
    );
  }

  Widget post(String image, bool like, var docID, String username,
      String userimage, int count) {
    return Card(
      color: Colors.teal[50],
      child: Column(
        // mainAxisAlignment: MainAxisAlignment.start,
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(userimage),
                  ),
                  SizedBox(width: 10),
                  Text(username.toUpperCase(),
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w500,
                          fontSize: 18))
                ],
              )),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: GestureDetector(
              onDoubleTap: () {
                flareControls.play("like", mixSeconds: 2);
                print('Animation');
                if (like) {
                  return null;
                } else {
                  Firestore.instance
                      .collection('feed')
                      .document(docID)
                      .updateData({
                    'likes': FieldValue.arrayUnion(['$uid'])
                  });
                }
              },
              child: Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.maxFinite,
                    child: Image.network(
                      image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    width: double.maxFinite,
                    height: 300,
                    child: Center(
                      child: SizedBox(
                        width: 80,
                        height: 80,
                        child: FlareActor(
                          'assets/instagram_like.flr',
                          controller: flareControls,
                          animation: 'idle',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: <Widget>[
              //Spacer(),
              IconButton(
                  icon: like
                      ? Icon(Icons.favorite, color: Colors.red)
                      : Icon(
                          Icons.favorite_border,
                          color: Colors.black,
                        ),
                  onPressed: () {
                    if (like) {
                      Firestore.instance
                          .collection('feed')
                          .document(docID)
                          .updateData({
                        'likes': FieldValue.arrayRemove(['$uid'])
                      });
                    } else {
                      Firestore.instance
                          .collection('feed')
                          .document(docID)
                          .updateData({
                        'likes': FieldValue.arrayUnion(['$uid'])
                      });
                    }
                  }),
              Padding(
                padding: const EdgeInsets.only(right: 15.0),
                child: Text(
                  '$count',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
