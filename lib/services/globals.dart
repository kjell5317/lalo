import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Uri? initialLink;
bool waiting = false;
User? user;
DocumentReference? userRef;
