import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:photo_feed_task/ui/feed.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  bool firstUser = false;
  SharedPreferences prefs;

  setRoute() async {
    prefs = await SharedPreferences.getInstance();
    String userId = prefs.getString('uid');
    if (userId != null) {
      navigate(context);
    }
    print("working");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setRoute();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();

  Future<FirebaseUser> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;
    if (authResult.additionalUserInfo.isNewUser) {
      setState(() {
        firstUser = true;
      });
    }
    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    return user;
  }

  Future login() async {
    FirebaseUser user;
    user = await signInWithGoogle();
    if (user != null) {
      prefs.setString('uid', user.uid);
      prefs.setString('name', user.displayName);
      prefs.setString('picture', user.photoUrl);
      if (firstUser) {
        Firestore.instance.collection('users').document(user.uid).setData({
          'name': user.displayName,
          'email': user.email,
          'uid': user.uid,
          'user_image': user.photoUrl,
        }).then((onValue) {
          navigate(context);
          Fluttertoast.showToast(
              msg: 'User created, logging in!',
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.white,
              textColor: Colors.black);
          // TODO : Show toast here
        }).catchError((e) {
          print('Fatal error ------ $e');
          Fluttertoast.showToast(
              msg: 'Oops! Try again.',
              gravity: ToastGravity.CENTER,
              backgroundColor: Colors.white,
              textColor: Colors.black);
          // TODO : Show toast here
        });
      } else {
        navigate(context);
        Fluttertoast.showToast(
            msg: 'Logging in!',
            gravity: ToastGravity.CENTER,
            backgroundColor: Colors.white,
            textColor: Colors.black);
        // TODO : Show toast here
      }
    } else {
      Fluttertoast.showToast(
          msg: 'Oops! Try again.',
          gravity: ToastGravity.CENTER,
          backgroundColor: Colors.white,
          textColor: Colors.black);
      // TODO : Show toast here
      print("null user");
    }
  }

  void navigate(BuildContext context) {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => MainFeed()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[200],
      body: Center(
        child: Card(
          child: Padding(
              padding: EdgeInsets.all(8),
              child: GestureDetector(
                  onTap: () => login(), child: Text('Sign in with Google'))),
        ),
      ),
    );
  }
}
