// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MyKid Journal';

  @override
  String get appDescription => 'Baby diary & child moments';

  @override
  String get signInSubtitle => 'Sign in to sync your journal';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get signUpTitle => 'Sign up for MyKid Journal';

  @override
  String get signUpSubtitle => 'Enter your email and choose a password.';

  @override
  String get hintEmail => 'you@example.com';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterValidEmail => 'Enter a valid email';

  @override
  String get choosePassword => 'Choose a password';

  @override
  String get passwordMinLength => 'Password must be at least 6 characters';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get signUp => 'Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get checkEmailConfirm => 'Check your email to confirm your account.';

  @override
  String get signUpDisabled =>
      'Sign-up is disabled. In Supabase: Authentication → Providers → Email → turn on \"Allow new users to sign up\".';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get edit => 'Edit';

  @override
  String get family => 'Family';

  @override
  String get manageChildren => 'Manage children';

  @override
  String get manageChildrenSubtitle =>
      'Name, date of birth. Photos can be saved to a child\'s Immich album.';

  @override
  String get sync => 'Sync';

  @override
  String get immich => 'Immich';

  @override
  String get immichSubtitle => 'Server URL and API key';

  @override
  String get account => 'Account';

  @override
  String get signOut => 'Sign out';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get save => 'Save';

  @override
  String get immichDescription =>
      'Your Immich server URL and API key (create key in Immich Settings → API Keys). A successful Test connection saves them.';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get serverUrlHint => 'https://photos.example.com';

  @override
  String get apiKey => 'API Key';

  @override
  String get enterUrlAndKey => 'Enter URL and API key';

  @override
  String get connectedSuccessfully => 'Connected successfully';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get testConnection => 'Test connection';

  @override
  String get testing => 'Testing...';

  @override
  String get connectedAndSaved => 'Connected and saved';

  @override
  String get saved => 'Saved';

  @override
  String get children => 'Children';

  @override
  String get noChildrenYet => 'No children yet';

  @override
  String get addChild => 'Add child';

  @override
  String get deleteChild => 'Delete child?';

  @override
  String deleteChildConfirm(String name) {
    return 'Remove \"$name\"? Journal entries will not be deleted.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String bornDate(int day, int month, int year) {
    return 'Born $day.$month.$year';
  }

  @override
  String get editChild => 'Edit child';

  @override
  String get tapToAddOrChangePhoto => 'Tap to add or change photo';

  @override
  String get name => 'Name';

  @override
  String get dateOfBirthOptional => 'Date of birth (optional)';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get cropPhoto => 'Crop photo';

  @override
  String get photoWillBeSaved => 'Photo will be saved with the profile';

  @override
  String get photoUpdated => 'Photo updated';

  @override
  String get uploadFailedAvatar =>
      'Upload failed. Create bucket \"avatars\" in Supabase Storage (public).';

  @override
  String get uploadFailedChildAvatar =>
      'Upload failed. Check Storage policies for child avatars.';

  @override
  String get configureImmichFirst => 'Configure Immich in Settings first';

  @override
  String get fromCamera => 'From camera';

  @override
  String get fromCameraSubtitle => 'Take a photo now, date = today';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get fromGallerySubtitle => 'Pick a photo, date & place from photo';

  @override
  String get emptyEntry => 'Empty entry';

  @override
  String get batchImport => 'Batch import';

  @override
  String get batchImportTooltip => 'Batch import';

  @override
  String get timeline => 'Timeline';

  @override
  String get addChildPrompt => 'Add child';

  @override
  String get addChildPromptSubtitle => 'Tap to create profile';

  @override
  String get selectChildAbove => 'Select child above';

  @override
  String get noEntries => 'No entries';

  @override
  String get addFirstEntry => 'Add first entry';

  @override
  String get noEntriesYet => 'No entries yet';

  @override
  String get addEntry => 'Add entry';

  @override
  String get retry => 'Retry';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get noTitle => 'No title';

  @override
  String photosCount(int count) {
    return '$count photo(s)';
  }

  @override
  String get newEntry => 'New entry';

  @override
  String get entry => 'Entry';

  @override
  String get deleteEntry => 'Delete entry?';

  @override
  String get alsoRemoveFromAlbum => 'Also remove photos from child\'s album';

  @override
  String get date => 'Date';

  @override
  String get child => 'Child';

  @override
  String get addChildInSettings => 'Add a child in Settings → Manage children';

  @override
  String get placeOptional => 'Place (optional)';

  @override
  String get placeHint => 'e.g. from photo or type here';

  @override
  String get description => 'Description';

  @override
  String get descriptionHint => 'What happened today?';

  @override
  String get photosVideos => 'Photos / videos';

  @override
  String get add => 'Add';

  @override
  String get noMediaAttached =>
      'No media attached. Add via \"Add\" or batch import.';

  @override
  String get pendingSaveToUpload => 'Pending (save to upload)';

  @override
  String get couldNotReadImage => 'Could not read image';

  @override
  String uploadFailedWithError(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get selectAChild => 'Select a child';

  @override
  String get pickFilesAndUpload => 'Pick files and upload';

  @override
  String get picking => 'Picking...';

  @override
  String get uploading => 'Uploading...';

  @override
  String uploadedCount(int current, int total) {
    return 'Uploaded $current / $total';
  }

  @override
  String get batchImportDescription =>
      'Select multiple photos/videos from your device. They will be uploaded to Immich, then you can create one journal entry with all of them.';

  @override
  String get noValidFiles => 'No valid files selected';

  @override
  String filesUploadedCount(int count) {
    return '$count file(s) uploaded.';
  }

  @override
  String get createOneEntryWithAll => 'Create one journal entry with all';

  @override
  String get yourName => 'Your name';

  @override
  String get profileUpdated => 'Profile updated';

  @override
  String ageYearsMonthsDays(int years, int months, int days) {
    return '$years y $months m $days d';
  }

  @override
  String ageMonthsDays(int months, int days) {
    return '$months m $days d';
  }

  @override
  String ageDays(int days) {
    return '$days d';
  }

  @override
  String get ageUnknown => '—';

  @override
  String get useFamilyImmich => 'Use family\'s Immich';

  @override
  String get useFamilyImmichDescription =>
      'Your family has Immich configured. Use it on this device? The server URL and API key will be saved locally.';

  @override
  String get saveToFamily => 'Save to family';

  @override
  String get saveToFamilyDescription =>
      'Store the current Immich server URL and API key for your family? Other members will be able to use the same Immich. The key is stored encrypted in the cloud.';

  @override
  String get useFamilyImmichFailed => 'Could not load family Immich settings';

  @override
  String get onboardingTitle => 'Setup';

  @override
  String get onboardingAccountTypeTitle => 'How do you want to start?';

  @override
  String get onboardingNewAccount => 'New account';

  @override
  String get onboardingNewAccountSubtitle =>
      'Create your own Immich and Supabase';

  @override
  String get onboardingFamily => 'Family';

  @override
  String get onboardingFamilySubtitle => 'Join with invite code (coming soon)';

  @override
  String get onboardingFamilyComingSoon =>
      'Family onboarding will be available soon. Use New account for now.';

  @override
  String get onboardingImmichTitle => 'Immich';

  @override
  String get onboardingImmichQuestion =>
      'Do you have an Immich server URL and API key?';

  @override
  String get onboardingImmichYes => 'Yes, I have them';

  @override
  String get onboardingImmichNo => 'No, create one';

  @override
  String get onboardingCreateImmich => 'Create Immich on PikaPods';

  @override
  String get onboardingCreateImmichSubtitle =>
      'Opens in browser. After setup, return and enter URL and API key.';

  @override
  String get onboardingSupabaseTitle => 'Supabase';

  @override
  String get onboardingSupabaseDescription =>
      'Create a project at supabase.com, run migrations, then copy URL and anon key from Settings → API.';

  @override
  String get onboardingSupabaseUrlHint => 'https://xxxx.supabase.co';

  @override
  String get onboardingAnonKey => 'Anon key';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingSkipImmich => 'Skip for now';

  @override
  String get onboardingTestAndContinue => 'Test connection and continue';

  @override
  String get inviteToFamily => 'Invite to family';

  @override
  String get inviteEmail => 'Email';

  @override
  String get inviteEmailHint => 'Enter email address';

  @override
  String get createInvite => 'Create invite';

  @override
  String get inviteCreated => 'Invite created';

  @override
  String get inviteLink => 'Invite link';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get copyInviteLink => 'Copy link';

  @override
  String get copyInviteCode => 'Copy code';

  @override
  String get inviteCopied => 'Copied to clipboard';

  @override
  String get pendingInvites => 'Pending invites';

  @override
  String get noInvites => 'No pending invites';

  @override
  String inviteExpires(String date) {
    return 'Expires $date';
  }

  @override
  String get cancelInvite => 'Cancel invite';

  @override
  String cancelInviteConfirm(String email) {
    return 'Cancel invitation to $email?';
  }

  @override
  String get acceptInvite => 'Accept invite';

  @override
  String get acceptInviteTitle => 'Join family';

  @override
  String get acceptInviteDescription =>
      'You\'ve been invited to join a family. Accept to access shared children and journal entries.';

  @override
  String get inviteNotFound => 'Invite not found or expired';

  @override
  String get inviteCodeTooShort => 'Enter at least 8 characters';

  @override
  String get inviteAccepted => 'You\'ve joined the family';

  @override
  String get alreadyMember => 'You\'re already a member of this family';

  @override
  String get inviteAcceptFailed => 'Failed to accept invite';

  @override
  String get sendInviteEmail => 'Send email';

  @override
  String sendInviteEmailDescription(String email) {
    return 'Send invitation email to $email';
  }

  @override
  String get inviteEmailSubject => 'Invitation to join MyKid family';

  @override
  String inviteEmailBody(String link, String code) {
    return 'You\'ve been invited to join a family in MyKid!\n\nInvite link: $link\nOr use invite code: $code\n\nOpen the link or enter the code in the MyKid app to accept the invitation.';
  }

  @override
  String get inviteEmailSent => 'Invitation email sent';

  @override
  String inviteEmailSentTo(String email) {
    return 'Invitation sent to $email';
  }

  @override
  String get inviteEmailFailed =>
      'Failed to send email, but invite was created';

  @override
  String get createHousehold => 'Create family';

  @override
  String get createHouseholdTitle => 'Create your family';

  @override
  String get createHouseholdDescription =>
      'Create a family to invite members and share children and journal entries.';

  @override
  String get householdName => 'Family name';

  @override
  String get householdNameHint => 'Optional';

  @override
  String get householdCreated => 'Family created';

  @override
  String get createHouseholdFailed => 'Failed to create family';

  @override
  String get legal => 'Legal';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Use';

  @override
  String get support => 'Support';

  @override
  String get licenses => 'Open Source Licenses';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Delete your account? All your data will be permanently removed. This cannot be undone.';

  @override
  String get deleteAccountConfirmSubtitle =>
      'You can also request deletion by email.';

  @override
  String get deleteAccountFailed =>
      'Failed to delete account. Please try again or contact support.';

  @override
  String get exportMyData => 'Export my data';

  @override
  String get exportMyDataSubtitle => 'Request a copy of your data (GDPR)';
}
