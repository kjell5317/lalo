import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String domain = 'lalo.lighting';

String? initialLink;
bool waiting = false;
User? user;
DocumentReference? userRef;
FirebaseAnalytics? analytics;
