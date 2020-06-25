import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadPhoto extends StatefulWidget {
  @override
  _UploadPhotoState createState() => _UploadPhotoState();
}

class _UploadPhotoState extends State<UploadPhoto> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserDetails();
  }

  File _image;
  final picker = ImagePicker();
  String _uploadImageUrl;
  String username, userimage;

  getUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      username = prefs.getString('name');
      userimage = prefs.getString('picture');
    });
  }

  Future cameraImage() async {
    final camImage =
        await picker.getImage(source: ImageSource.camera, imageQuality: 25);

    setState(() {
      _image = File(camImage.path);
    });
    //uploadImg();
  }

  Future galleryImage() async {
    var galImage =
        await picker.getImage(source: ImageSource.gallery, imageQuality: 25);

    setState(() {
      _image = File(galImage.path);
    });
    //uploadImg();
  }

  Future<String> _uploadImageToFB() async {
    print(_image.path);
    String refinedImageUrl = _image.path.replaceAll('/', '');
    refinedImageUrl = refinedImageUrl.replaceAll('.', '');
    print(refinedImageUrl);
    StorageReference storageReference =
        FirebaseStorage.instance.ref().child(refinedImageUrl);
    StorageUploadTask uploadTask = storageReference.putFile(_image);
    _uploadImageUrl = await (await uploadTask.onComplete).ref.getDownloadURL();
    print("this the url before uploading");
    return _uploadImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload photo'),
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.done),
              onPressed: () async {
                if (_image == null) {
                  return showDialog(
                      context: context,
                      builder: (context) => Center(
                            child: Card(
                              color: Colors.white,
                              child: Container(
                                height: 50,
                                width: 200,
                                child: Center(child: Text('Nothing to upload')),
                              ),
                            ),
                          ));
                }
                _uploadImageToFB().then((url) {
                  Firestore.instance.collection('feed').document().setData({
                    'image': url,
                    'username': username,
                    'userimage': userimage,
                    'likes': []
                  }).whenComplete(() {
                    setState(() {
                      _image = null;
                    });
                  });
                });
              })
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(10),
        child: _image == null
            ? Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Card(
                      child: GestureDetector(
                        onTap: () => cameraImage(),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.camera_alt),
                            ),
                            Text('Take image from camera')
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(5),
                    child: Card(
                      child: GestureDetector(
                        onTap: () => galleryImage(),
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.photo),
                            ),
                            Text('Choose image from gallery')
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              )
            : Center(
                child: Container(
                  height: 300,
                  width: 300,
                  child: Image.file(
                    _image,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
      ),
    );
  }
}
