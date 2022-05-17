import 'package:flutterfire_ui/i10n.dart';

class LabelOverrides extends DefaultLocalizations {
  const LabelOverrides();

  // Label
  @override
  String get emailInputLabel => 'E-Mail';
  @override
  String get passwordInputLabel => 'Passwort';
  @override
  String get confirmPasswordInputLabel => 'Passwort bestätigen';

  // Registrieren
  @override
  String get registerText => 'Registrieren';
  @override
  String get registerActionText => 'Registrieren';
  @override
  String get registerHintText => 'Du hast noch keinen Account?';

  // Passwort vergessen
  @override
  String get forgotPasswordViewTitle => 'Passwort vergessen';
  @override
  String get forgotPasswordHintText =>
      'Gib deine E-Mail Adresse ein und wir senden dir einen Link zum Zurücksetzen des Passwortes zu';

  // Error
  @override
  String get confirmPasswordDoesNotMatchErrorText => 'Das Passwort ist falsch';
  @override
  String get userNotFoundErrorText => 'Account existiert nicht';
  @override
  String get emailIsRequiredErrorText => 'E-Mail ist erforderlich';
  @override
  String get emailTakenErrorText => 'E-Mail Adresse existiert bereits';
  @override
  String get isNotAValidEmailErrorText => 'Dies ist keine E-Mail Adresse';
  @override
  String get passwordIsRequiredErrorText => 'Passwort ist erforderlich';
  @override
  String get wrongOrNoPasswordErrorText => 'Passwort ist falsch';
  @override
  String get confirmPasswordIsRequiredErrorText =>
      'Das Passwort ist erforderlich';
  @override
  String get unknownError => 'Ein unbekannter Fehler ist aufgetreten';

  // Anmelden
  @override
  String get signInText => 'Anmelden';
  @override
  String get signInActionText => 'Anmelden';
  @override
  String get signInHintText => 'Du hast schon einen Account?';

  // Buttons
  @override
  String get resetPasswordButtonLabel => 'Passwort zurücksetzen';
  @override
  String get goBackButtonLabel => 'Zurück';
  @override
  String get forgotPasswordButtonLabel => 'Passwort vergessen?';
  @override
  String get signInWithGoogleButtonText => 'Anmelden mit Google';

  // Delete
  @override
  String get verifyItsYouText => 'Bestätige deine Identität';
  @override
  String get deleteAccount => 'Account löschen';

  // Methoden
  @override
  String get enableMoreSignInMethods => 'Mehr Anmeldemethoden aktivieren';
  @override
  String get signInMethods => 'Aktive Anmeldemethoden';

  // Profil
  @override
  String get profile => 'Account';
}
