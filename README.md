# Leave a Light on

I started this project because I wanted to learn to build apps with Flutter and Firebase.  
Now I have this app which is almost ready to get launched in Google Playstore.

## Features

Leave a Light on is an app where you can blink the lights of friends or loved ones when you are thinking aboud them. You start by creating an account with your email or sign in with google (Firebase Auth). Then you connect your Philips Hue remote account. The OAuth tokens are stored in Firestore and the callback is a Firebase cloudfunction which creates the tokens. Next you can send links (Firebase dynamic links) to friends and they have to accept the request. You are now able to blink their light.
