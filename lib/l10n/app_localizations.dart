import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_be.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('be'),
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'MyKid Journal'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Baby diary & child moments'**
  String get appDescription;

  /// No description provided for @signInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your journal'**
  String get signInSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign up for MyKid Journal'**
  String get signUpTitle;

  /// No description provided for @signUpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and choose a password.'**
  String get signUpSubtitle;

  /// No description provided for @hintEmail.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get hintEmail;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get enterValidEmail;

  /// No description provided for @choosePassword.
  ///
  /// In en, this message translates to:
  /// **'Choose a password'**
  String get choosePassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @checkEmailConfirm.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account.'**
  String get checkEmailConfirm;

  /// No description provided for @signUpDisabled.
  ///
  /// In en, this message translates to:
  /// **'Sign-up is disabled. In Supabase: Authentication → Providers → Email → turn on \"Allow new users to sign up\".'**
  String get signUpDisabled;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get family;

  /// No description provided for @manageChildren.
  ///
  /// In en, this message translates to:
  /// **'Manage children'**
  String get manageChildren;

  /// No description provided for @manageChildrenSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Name, date of birth. Photos can be saved to a child\'s Immich album.'**
  String get manageChildrenSubtitle;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @immich.
  ///
  /// In en, this message translates to:
  /// **'Immich'**
  String get immich;

  /// No description provided for @immichSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Server URL and API key'**
  String get immichSubtitle;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @immichDescription.
  ///
  /// In en, this message translates to:
  /// **'Your Immich server URL and API key (create key in Immich Settings → API Keys). A successful Test connection saves them.'**
  String get immichDescription;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @serverUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://photos.example.com'**
  String get serverUrlHint;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @enterUrlAndKey.
  ///
  /// In en, this message translates to:
  /// **'Enter URL and API key'**
  String get enterUrlAndKey;

  /// No description provided for @connectedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Connected successfully'**
  String get connectedSuccessfully;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get connectionFailed;

  /// No description provided for @testConnection.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get testConnection;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing...'**
  String get testing;

  /// No description provided for @connectedAndSaved.
  ///
  /// In en, this message translates to:
  /// **'Connected and saved'**
  String get connectedAndSaved;

  /// No description provided for @saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @noChildrenYet.
  ///
  /// In en, this message translates to:
  /// **'No children yet'**
  String get noChildrenYet;

  /// No description provided for @addChild.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get addChild;

  /// No description provided for @deleteChild.
  ///
  /// In en, this message translates to:
  /// **'Delete child?'**
  String get deleteChild;

  /// No description provided for @deleteChildConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"? Journal entries will not be deleted.'**
  String deleteChildConfirm(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @bornDate.
  ///
  /// In en, this message translates to:
  /// **'Born {day}.{month}.{year}'**
  String bornDate(int day, int month, int year);

  /// No description provided for @editChild.
  ///
  /// In en, this message translates to:
  /// **'Edit child'**
  String get editChild;

  /// No description provided for @tapToAddOrChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Tap to add or change photo'**
  String get tapToAddOrChangePhoto;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @dateOfBirthOptional.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (optional)'**
  String get dateOfBirthOptional;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @cropPhoto.
  ///
  /// In en, this message translates to:
  /// **'Crop photo'**
  String get cropPhoto;

  /// No description provided for @photoWillBeSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo will be saved with the profile'**
  String get photoWillBeSaved;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Photo updated'**
  String get photoUpdated;

  /// No description provided for @uploadFailedAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Create bucket \"avatars\" in Supabase Storage (public).'**
  String get uploadFailedAvatar;

  /// No description provided for @uploadFailedChildAvatar.
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Check Storage policies for child avatars.'**
  String get uploadFailedChildAvatar;

  /// No description provided for @configureImmichFirst.
  ///
  /// In en, this message translates to:
  /// **'Configure Immich in Settings first'**
  String get configureImmichFirst;

  /// No description provided for @fromCamera.
  ///
  /// In en, this message translates to:
  /// **'From camera'**
  String get fromCamera;

  /// No description provided for @fromCameraSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Take a photo now, date = today'**
  String get fromCameraSubtitle;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get fromGallery;

  /// No description provided for @fromGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a photo, date & place from photo'**
  String get fromGallerySubtitle;

  /// No description provided for @emptyEntry.
  ///
  /// In en, this message translates to:
  /// **'Empty entry'**
  String get emptyEntry;

  /// No description provided for @batchImport.
  ///
  /// In en, this message translates to:
  /// **'Batch import'**
  String get batchImport;

  /// No description provided for @batchImportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Batch import'**
  String get batchImportTooltip;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @addChildPrompt.
  ///
  /// In en, this message translates to:
  /// **'Add child'**
  String get addChildPrompt;

  /// No description provided for @addChildPromptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to create profile'**
  String get addChildPromptSubtitle;

  /// No description provided for @selectChildAbove.
  ///
  /// In en, this message translates to:
  /// **'Select child above'**
  String get selectChildAbove;

  /// No description provided for @noEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries'**
  String get noEntries;

  /// No description provided for @addFirstEntry.
  ///
  /// In en, this message translates to:
  /// **'Add first entry'**
  String get addFirstEntry;

  /// No description provided for @noEntriesYet.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get noEntriesYet;

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntry;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get noTitle;

  /// No description provided for @photosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} photo(s)'**
  String photosCount(int count);

  /// No description provided for @newEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get newEntry;

  /// No description provided for @entry.
  ///
  /// In en, this message translates to:
  /// **'Entry'**
  String get entry;

  /// No description provided for @deleteEntry.
  ///
  /// In en, this message translates to:
  /// **'Delete entry?'**
  String get deleteEntry;

  /// No description provided for @alsoRemoveFromAlbum.
  ///
  /// In en, this message translates to:
  /// **'Also remove photos from child\'s album'**
  String get alsoRemoveFromAlbum;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @child.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get child;

  /// No description provided for @addChildInSettings.
  ///
  /// In en, this message translates to:
  /// **'Add a child in Settings → Manage children'**
  String get addChildInSettings;

  /// No description provided for @placeOptional.
  ///
  /// In en, this message translates to:
  /// **'Place (optional)'**
  String get placeOptional;

  /// No description provided for @placeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. from photo or type here'**
  String get placeHint;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'What happened today?'**
  String get descriptionHint;

  /// No description provided for @photosVideos.
  ///
  /// In en, this message translates to:
  /// **'Photos / videos'**
  String get photosVideos;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @noMediaAttached.
  ///
  /// In en, this message translates to:
  /// **'No media attached. Add via \"Add\" or batch import.'**
  String get noMediaAttached;

  /// No description provided for @pendingSaveToUpload.
  ///
  /// In en, this message translates to:
  /// **'Pending (save to upload)'**
  String get pendingSaveToUpload;

  /// No description provided for @couldNotReadImage.
  ///
  /// In en, this message translates to:
  /// **'Could not read image'**
  String get couldNotReadImage;

  /// No description provided for @uploadFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailedWithError(String error);

  /// No description provided for @selectAChild.
  ///
  /// In en, this message translates to:
  /// **'Select a child'**
  String get selectAChild;

  /// No description provided for @pickFilesAndUpload.
  ///
  /// In en, this message translates to:
  /// **'Pick files and upload'**
  String get pickFilesAndUpload;

  /// No description provided for @picking.
  ///
  /// In en, this message translates to:
  /// **'Picking...'**
  String get picking;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @uploadedCount.
  ///
  /// In en, this message translates to:
  /// **'Uploaded {current} / {total}'**
  String uploadedCount(int current, int total);

  /// No description provided for @batchImportDescription.
  ///
  /// In en, this message translates to:
  /// **'Select multiple photos/videos from your device. They will be uploaded to Immich, then you can create one journal entry with all of them.'**
  String get batchImportDescription;

  /// No description provided for @noValidFiles.
  ///
  /// In en, this message translates to:
  /// **'No valid files selected'**
  String get noValidFiles;

  /// No description provided for @filesUploadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} file(s) uploaded.'**
  String filesUploadedCount(int count);

  /// No description provided for @createOneEntryWithAll.
  ///
  /// In en, this message translates to:
  /// **'Create one journal entry with all'**
  String get createOneEntryWithAll;

  /// No description provided for @yourName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get profileUpdated;

  /// No description provided for @ageYearsMonthsDays.
  ///
  /// In en, this message translates to:
  /// **'{years} y {months} m {days} d'**
  String ageYearsMonthsDays(int years, int months, int days);

  /// No description provided for @ageMonthsDays.
  ///
  /// In en, this message translates to:
  /// **'{months} m {days} d'**
  String ageMonthsDays(int months, int days);

  /// No description provided for @ageDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d'**
  String ageDays(int days);

  /// No description provided for @ageUnknown.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get ageUnknown;

  /// No description provided for @useFamilyImmich.
  ///
  /// In en, this message translates to:
  /// **'Use family\'s Immich'**
  String get useFamilyImmich;

  /// No description provided for @useFamilyImmichDescription.
  ///
  /// In en, this message translates to:
  /// **'Your family has Immich configured. Use it on this device? The server URL and API key will be saved locally.'**
  String get useFamilyImmichDescription;

  /// No description provided for @saveToFamily.
  ///
  /// In en, this message translates to:
  /// **'Save to family'**
  String get saveToFamily;

  /// No description provided for @saveToFamilyDescription.
  ///
  /// In en, this message translates to:
  /// **'Store the current Immich server URL and API key for your family? Other members will be able to use the same Immich. The key is stored encrypted in the cloud.'**
  String get saveToFamilyDescription;

  /// No description provided for @useFamilyImmichFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not load family Immich settings'**
  String get useFamilyImmichFailed;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get onboardingTitle;

  /// No description provided for @onboardingAccountTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'How do you want to start?'**
  String get onboardingAccountTypeTitle;

  /// No description provided for @onboardingNewAccount.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get onboardingNewAccount;

  /// No description provided for @onboardingNewAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your own Immich and Supabase'**
  String get onboardingNewAccountSubtitle;

  /// No description provided for @onboardingFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get onboardingFamily;

  /// No description provided for @onboardingFamilySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join with invite code (coming soon)'**
  String get onboardingFamilySubtitle;

  /// No description provided for @onboardingFamilyComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Family onboarding will be available soon. Use New account for now.'**
  String get onboardingFamilyComingSoon;

  /// No description provided for @onboardingImmichTitle.
  ///
  /// In en, this message translates to:
  /// **'Immich'**
  String get onboardingImmichTitle;

  /// No description provided for @onboardingImmichQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you have an Immich server URL and API key?'**
  String get onboardingImmichQuestion;

  /// No description provided for @onboardingImmichYes.
  ///
  /// In en, this message translates to:
  /// **'Yes, I have them'**
  String get onboardingImmichYes;

  /// No description provided for @onboardingImmichNo.
  ///
  /// In en, this message translates to:
  /// **'No, create one'**
  String get onboardingImmichNo;

  /// No description provided for @onboardingCreateImmich.
  ///
  /// In en, this message translates to:
  /// **'Create Immich on PikaPods'**
  String get onboardingCreateImmich;

  /// No description provided for @onboardingCreateImmichSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens in browser. After setup, return and enter URL and API key.'**
  String get onboardingCreateImmichSubtitle;

  /// No description provided for @onboardingSupabaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Supabase'**
  String get onboardingSupabaseTitle;

  /// No description provided for @onboardingSupabaseDescription.
  ///
  /// In en, this message translates to:
  /// **'Create a project at supabase.com, run migrations, then copy URL and anon key from Settings → API.'**
  String get onboardingSupabaseDescription;

  /// No description provided for @onboardingSupabaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://xxxx.supabase.co'**
  String get onboardingSupabaseUrlHint;

  /// No description provided for @onboardingAnonKey.
  ///
  /// In en, this message translates to:
  /// **'Anon key'**
  String get onboardingAnonKey;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingSkipImmich.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkipImmich;

  /// No description provided for @onboardingTestAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Test connection and continue'**
  String get onboardingTestAndContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['be', 'en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'be':
      return AppLocalizationsBe();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
