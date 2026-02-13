// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Belarusian (`be`).
class AppLocalizationsBe extends AppLocalizations {
  AppLocalizationsBe([String locale = 'be']) : super(locale);

  @override
  String get appTitle => 'Дзённік MyKid';

  @override
  String get appDescription => 'Дзіцячы дзённік і моманты дзіцяці';

  @override
  String get signInSubtitle => 'Увайдзіце, каб сінхранізаваць дзённік';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get signIn => 'Увайсці';

  @override
  String get createAccount => 'Стварыць акаўнт';

  @override
  String get signUpTitle => 'Рэгістрацыя ў Дзённік MyKid';

  @override
  String get signUpSubtitle => 'Увядзіце email і прыдумайце пароль.';

  @override
  String get hintEmail => 'you@example.com';

  @override
  String get enterYourEmail => 'Увядзіце email';

  @override
  String get enterValidEmail => 'Увядзіце карэктны email';

  @override
  String get choosePassword => 'Прыдумайце пароль';

  @override
  String get passwordMinLength => 'Пароль павінен быць не менш 6 сімвалаў';

  @override
  String get confirmPassword => 'Пацвердзіце пароль';

  @override
  String get passwordsDoNotMatch => 'Паролі не супадаюць';

  @override
  String get signUp => 'Зарэгістравацца';

  @override
  String get alreadyHaveAccount => 'Ужо ёсць акаўнт? Увайсці';

  @override
  String get checkEmailConfirm => 'Праверце пошту, каб пацвердзіць акаўнт.';

  @override
  String get signUpDisabled =>
      'Рэгістрацыя адключана. У Supabase: Authentication → Providers → Email уключыце «Allow new users to sign up».';

  @override
  String get startFromScratch => 'Пачаць з нуля';

  @override
  String get startFromScratchConfirm => 'Скінуць і запустиць онбордынг?';

  @override
  String get startFromScratchConfirmMessage =>
      'Усе захаваныя налады Supabase і Immich будуць выдалены. Дадатак зачыніцца. Адкрыйце яго зноў, каб наладзіць з нуля.';

  @override
  String get settings => 'Налады';

  @override
  String get profile => 'Профіль';

  @override
  String get edit => 'Змяніць';

  @override
  String get family => 'Сям\'я';

  @override
  String get manageChildren => 'Дзеці';

  @override
  String get manageChildrenSubtitle =>
      'Імя, дата нараджэння. Фота можна захоўваць у альбом Immich дзіцяці.';

  @override
  String get sync => 'Сінхранізацыя';

  @override
  String get immich => 'Immich';

  @override
  String get immichSubtitle => 'URL сервера і API-ключ';

  @override
  String get account => 'Акаўнт';

  @override
  String get signOut => 'Выйсці';

  @override
  String version(String version) {
    return 'Версія $version';
  }

  @override
  String get save => 'Захаваць';

  @override
  String get immichDescription =>
      'URL сервера Immich і API-ключ (стварыце ключ у Immich: Налады → API Keys). Паспяховая праверка падключэння захоўвае іх.';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverUrlHint => 'https://photos.example.com';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get enterUrlAndKey => 'Увядзіце URL і API-ключ';

  @override
  String get connectedSuccessfully => 'Падключана';

  @override
  String get connectionFailed => 'Памылка падключэння';

  @override
  String get testConnection => 'Праверыць падключэнне';

  @override
  String get testing => 'Праверка…';

  @override
  String get connectedAndSaved => 'Падключана і захавана';

  @override
  String get saved => 'Захавана';

  @override
  String get children => 'Дзеці';

  @override
  String get noChildrenYet => 'Пакуль няма дзяцей';

  @override
  String get addChild => 'Дадаць дзіця';

  @override
  String get deleteChild => 'Выдаліць дзіця?';

  @override
  String deleteChildConfirm(String name) {
    return 'Выдаліць «$name»? Запісы дзённіка не выдаляюцца.';
  }

  @override
  String get cancel => 'Скасаваць';

  @override
  String get delete => 'Выдаліць';

  @override
  String bornDate(int day, int month, int year) {
    return 'Нарадзіўся(лася) $day.$month.$year';
  }

  @override
  String get editChild => 'Рэдагаваць дзіця';

  @override
  String get tapToAddOrChangePhoto => 'Націсніце, каб дадаць або змяніць фота';

  @override
  String get name => 'Імя';

  @override
  String get dateOfBirthOptional => 'Дата нараджэння (неабавязкова)';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерэя';

  @override
  String get cropPhoto => 'Абразаць фота';

  @override
  String get photoWillBeSaved => 'Фота будзе захавана ў профілі';

  @override
  String get photoUpdated => 'Фота абноўлена';

  @override
  String get uploadFailedAvatar =>
      'Памылка загрузкі. Стварыце bucket «avatars» у Supabase Storage (public).';

  @override
  String get uploadFailedChildAvatar =>
      'Памылка загрузкі. Праверце палітыкі Storage для аватараў дзяцей.';

  @override
  String get configureImmichFirst => 'Спачатку наладзьце Immich у Наладах';

  @override
  String get fromCamera => 'З камеры';

  @override
  String get fromCameraSubtitle => 'Сфатаграфаваць зараз, дата — сёння';

  @override
  String get fromGallery => 'З галерэі';

  @override
  String get fromGallerySubtitle => 'Выбраць фота, дата і месца з фота';

  @override
  String get emptyEntry => 'Пусты запіс';

  @override
  String get batchImport => 'Масавы імпорт';

  @override
  String get batchImportTooltip => 'Масавы імпорт';

  @override
  String get timeline => 'Стужка';

  @override
  String get suggestionsTab => 'Прапановы';

  @override
  String get scanningPhotos => 'Сканаванне фота…';

  @override
  String foundPhotosWithChild(int count, String childName) {
    return 'Знойдзена $count фота з $childName';
  }

  @override
  String get createEntryFromSuggestion => 'Стварыць запіс';

  @override
  String get noSuggestions => 'Няма прапаноў';

  @override
  String get scanNow => 'Сканаваць зараз';

  @override
  String get stopScan => 'Спыніць';

  @override
  String get scanNowHint => 'Націсніце кнопку вышэй для пошуку фота';

  @override
  String get scanLimitHint => 'Сканаванне да 500 апошніх фота';

  @override
  String get addReferencePhotosPrompt =>
      'Дадайце эталонныя фота дзяцей для распазнавання';

  @override
  String get addReferencePhotosButton => 'Дадаць эталонныя фота';

  @override
  String get linkChildToImmichPersonHint =>
      'Або прывяжыце дзіця да персоны ў Immich (Налады → Дзеці → Рэдагаваць), каб выкарыстоўваць распазнаванне твараў Immich.';

  @override
  String get linkToImmichPerson => 'Прывязаць да персоны Immich';

  @override
  String get linkToImmichPersonSubtitle =>
      'Выкарыстоўваць распазнаванне твараў Immich для прапаноў';

  @override
  String get selectImmichPerson => 'Выбраць персону';

  @override
  String immichPersonLinked(String name) {
    return 'Прывязаны да $name';
  }

  @override
  String get unlinkImmichPerson => 'Адвязаць';

  @override
  String get replaceReferencePhotos => 'Замяніць усё';

  @override
  String get replaceReferencePhotosConfirm => 'Замяніць эталонныя фота?';

  @override
  String get replaceReferencePhotosConfirmMessage =>
      'Усе бягучыя эталонныя фота будуць выдалены. Затым выберыце новыя фота.';

  @override
  String get replaceReferencePhotosDone =>
      'Эталонныя фота выдалены. Выберыце новыя.';

  @override
  String get addChildPrompt => 'Дадаць дзіця';

  @override
  String get addChildPromptSubtitle => 'Націсніце, каб стварыць профіль';

  @override
  String get selectChildAbove => 'Выберыце дзіця вышэй';

  @override
  String get noEntries => 'Няма запісаў';

  @override
  String get addFirstEntry => 'Дадаць першы запіс';

  @override
  String get noEntriesYet => 'Пакуль няма запісаў';

  @override
  String get addEntry => 'Дадаць запіс';

  @override
  String get retry => 'Паўтарыць';

  @override
  String get today => 'Сёння';

  @override
  String get yesterday => 'Учора';

  @override
  String get noTitle => 'Без назвы';

  @override
  String photosCount(int count) {
    return '$count фота';
  }

  @override
  String get newEntry => 'Новы запіс';

  @override
  String get entry => 'Запіс';

  @override
  String get deleteEntry => 'Выдаліць запіс?';

  @override
  String get alsoRemoveFromAlbum => 'Таксама выдаліць фота з альбома дзіцяці';

  @override
  String get date => 'Дата';

  @override
  String get child => 'Дзіця';

  @override
  String get addChildInSettings => 'Дадайце дзіця ў Наладах → Дзеці';

  @override
  String get placeOptional => 'Месца (неабавязкова)';

  @override
  String get placeHint => 'напрыклад, з фота або ўвядзіце ўручную';

  @override
  String get description => 'Апісанне';

  @override
  String get descriptionHint => 'Што здарылася сёння?';

  @override
  String get photosVideos => 'Фота / відэа';

  @override
  String get add => 'Дадаць';

  @override
  String get noMediaAttached =>
      'Няма медыя. Дадайце праз «Дадаць» або масавы імпорт.';

  @override
  String get pendingSaveToUpload => 'Чакае (загрузка пры захаванні)';

  @override
  String get couldNotReadImage => 'Не ўдалося прачытаць выяву';

  @override
  String uploadFailedWithError(String error) {
    return 'Памылка загрузкі: $error';
  }

  @override
  String get selectAChild => 'Выберыце дзіця';

  @override
  String get pickFilesAndUpload => 'Выбраць файлы і загрузіць';

  @override
  String get picking => 'Выбар…';

  @override
  String get uploading => 'Загрузка…';

  @override
  String uploadedCount(int current, int total) {
    return 'Загружана $current з $total';
  }

  @override
  String get batchImportDescription =>
      'Выберыце некалькі фота або відэа з прылады. Яны будуць загружаны ў Immich, затым можна стварыць адзін запіс са усімі.';

  @override
  String get noValidFiles => 'Няма падыходзячых файлаў';

  @override
  String filesUploadedCount(int count) {
    return 'Загружана файлаў: $count';
  }

  @override
  String get createOneEntryWithAll => 'Стварыць адзін запіс са усімі';

  @override
  String get yourName => 'Ваша імя';

  @override
  String get profileUpdated => 'Профіль абноўлены';

  @override
  String ageYearsMonthsDays(int years, int months, int days) {
    return '$years г. $months мес. $days дн.';
  }

  @override
  String ageMonthsDays(int months, int days) {
    return '$months мес. $days дн.';
  }

  @override
  String ageDays(int days) {
    return '$days дн.';
  }

  @override
  String get ageUnknown => '—';

  @override
  String get useFamilyImmich => 'Выкарыстоўваць Immich сям\'і';

  @override
  String get useFamilyImmichDescription =>
      'У сям\'і наладжаны Immich. Выкарыстоўваць на гэтай прыладзе? URL і API-ключ будуць захаваны лакальна.';

  @override
  String get saveToFamily => 'Захаваць для сям\'і';

  @override
  String get saveToFamilyDescription =>
      'Захаваць бягучыя URL і API-ключ Immich для сям\'і? Іншыя ўдзельнікі змогуць выкарыстоўваць той жа Immich. Ключ захоўваецца ў воблаку ў зашыфраваным выглядзе.';

  @override
  String get useFamilyImmichFailed =>
      'Не ўдалося загрузіць налады Immich сям\'і';

  @override
  String get onboardingTitle => 'Налада';

  @override
  String get onboardingAccountTypeTitle => 'Як хочаце пачаць?';

  @override
  String get onboardingNewAccount => 'Новы акаўнт';

  @override
  String get onboardingNewAccountSubtitle => 'Стварыце свой Immich і Supabase';

  @override
  String get onboardingHostingQuestion => 'Будзеце наладжваць свой хостинг?';

  @override
  String get onboardingHostingQuestionSubtitle =>
      'Выберыце, наладжваць ці свае серверы ці выкарыстоўваць наш managed backend';

  @override
  String get onboardingHostingYes => 'Так, буду наладжваць';

  @override
  String get onboardingHostingYesSubtitle => 'Я сам наладжу Immich і Supabase';

  @override
  String get onboardingHostingNo => 'Не, выкарыстоўваць managed backend';

  @override
  String get onboardingHostingNoSubtitle =>
      'Выкарыстоўваць наш платны managed сэрвіс';

  @override
  String get onboardingExistingAccount => 'У мяне ўжо ёсць акаўнт';

  @override
  String get onboardingExistingAccountSubtitle =>
      'Увайсці з URL і anon key Supabase';

  @override
  String get onboardingFamily => 'Сям\'я';

  @override
  String get onboardingFamilySubtitle => 'Далучыцца па коду запрашэння (скора)';

  @override
  String get onboardingFamilyComingSoon =>
      'Сямейная налада скора будзе даступная. Пакуль выкарыстоўвайце «Новы акаўнт».';

  @override
  String get onboardingImmichTitle => 'Immich';

  @override
  String get onboardingImmichQuestion =>
      'Ці ёсць у вас URL сервера Immich і API-ключ?';

  @override
  String get onboardingImmichYes => 'Так, ёсць';

  @override
  String get onboardingImmichNo => 'Не, стварыць';

  @override
  String get onboardingCreateImmich => 'Стварыць Immich на PikaPods';

  @override
  String get onboardingCreateImmichSubtitle =>
      'Адкрыецца ў браўзеры. Пасля налады вярніцеся і ўвядзіце URL і API-ключ.';

  @override
  String get onboardingSupabaseTitle => 'Supabase';

  @override
  String get onboardingSupabaseQuestion =>
      'Ці ёсць у вас свой праект Supabase?';

  @override
  String get onboardingSupabaseManaged => 'Выкарыстоўваць managed backend';

  @override
  String get onboardingSupabaseManagedSubtitle => 'Мы ўсё наладзім за вас';

  @override
  String get onboardingSupabaseSelfHosted => 'Выкарыстоўваць свой Supabase';

  @override
  String get onboardingSupabaseSelfHostedSubtitle =>
      'Я прадастаўлю URL і anon key';

  @override
  String get onboardingSupabaseDescription =>
      'Стварыце праект на supabase.com, выканайце міграцыі, затым скапіруйце URL і anon key з Settings → API.';

  @override
  String get onboardingSupabaseUrlHint => 'https://xxxx.supabase.co';

  @override
  String get onboardingAnonKey => 'Anon key';

  @override
  String get onboardingContinue => 'Далей';

  @override
  String get onboardingSkipImmich => 'Прапусціць';

  @override
  String get onboardingSkipSupabase => 'Выкарыстоўваць managed backend';

  @override
  String get onboardingTestAndContinue => 'Праверыць падключэнне і працягнуць';

  @override
  String get onboardingTestSupabaseFirst =>
      'Спачатку праверце падключэнне. Калі схемы няма — выканайце SQL у Supabase Dashboard.';

  @override
  String get onboardingSchemaMissingTitle => 'Патрабуецца налада базы даных';

  @override
  String get onboardingSchemaMissingDescription =>
      'Праекту Supabase патрэбна наша схема. Скапіруйце SQL, устаўце ў Supabase Dashboard → SQL Editor, выканайце, затым націсніце «Паўтарыць».';

  @override
  String get onboardingCopySql => 'Скапіяваць SQL';

  @override
  String get onboardingOpenSupabaseDashboard => 'Адкрыць SQL Editor у Supabase';

  @override
  String get onboardingSqlCopied => 'SQL скапіяваны ў буфер';

  @override
  String get onboardingSqlCopyFailed => 'Не ўдалося скапіяваць SQL';

  @override
  String get onboardingRunMigrationsFirst =>
      'Спачатку праверце падключэнне і выканайце міграцыі';

  @override
  String get inviteToFamily => 'Запрасіць у сям\'ю';

  @override
  String get myFamily => 'Мая сям\'я';

  @override
  String get familyMembers => 'Удзельнікі сям\'і';

  @override
  String get householdMemberRoleOwner => 'Уладальнік';

  @override
  String get householdMemberRoleMember => 'Удзельнік';

  @override
  String get you => 'Вы';

  @override
  String get inviteEmail => 'Email';

  @override
  String get inviteEmailHint => 'Увядзіце email';

  @override
  String get createInvite => 'Стварыць запрашэнне';

  @override
  String get inviteCreated => 'Запрашэнне створана';

  @override
  String get inviteLink => 'Спасылка запрашэння';

  @override
  String get inviteCode => 'Код запрашэння';

  @override
  String get copyInviteLink => 'Скапіяваць спасылку';

  @override
  String get copyInviteCode => 'Скапіяваць код';

  @override
  String get inviteCopied => 'Скапіявана';

  @override
  String get pendingInvites => 'Чакаючыя запрашэнні';

  @override
  String get noInvites => 'Няма чакаючых запрашэнняў';

  @override
  String inviteExpires(String date) {
    return 'Сканчаецца $date';
  }

  @override
  String get cancelInvite => 'Скасаваць запрашэнне';

  @override
  String cancelInviteConfirm(String email) {
    return 'Скасаваць запрашэнне для $email?';
  }

  @override
  String get acceptInvite => 'Прыняць запрашэнне';

  @override
  String get acceptInviteTitle => 'Далучыцца да сям\'і';

  @override
  String get acceptInviteDescription =>
      'Вас запрасілі ў сям\'ю. Прыміце запрашэнне, каб атрымаць доступ да агульных дзяцей і запісаў дзённіка.';

  @override
  String get inviteNotFound => 'Запрашэнне не знойдзена або скончылася';

  @override
  String get inviteCodeTooShort => 'Увядзіце не менш за 8 сімвалаў';

  @override
  String get inviteOpenLinkHint =>
      'Open the invite link you received in your email or message.';

  @override
  String get orEnterCodeManually => 'Or enter code manually';

  @override
  String get enterInviteCodeHint => 'Enter 8-character code';

  @override
  String get searchByCode => 'Search by code';

  @override
  String get invitedBy => 'Invited by:';

  @override
  String get signInToAcceptInvite =>
      'You need to sign in or create an account to accept this invitation.';

  @override
  String get signUpToAccept => 'Sign up to accept';

  @override
  String get cancelInviteFailed => 'Failed to cancel invite';

  @override
  String get expired => 'Expired';

  @override
  String get searching => 'Searching...';

  @override
  String get inviteAcceptedDataNotRefreshed =>
      'Invite accepted, but data didn\'t refresh. Try restarting the app.';

  @override
  String get inviteAcceptErrorRetry =>
      'Error accepting invite. Please try again or restart the app.';

  @override
  String get inviteAcceptErrorRestart =>
      'Error accepting invite. Please restart the app.';

  @override
  String createHouseholdFailedWithReason(String message, String reason) {
    return '$message: $reason';
  }

  @override
  String get supportEmailCopied => 'Email copied to clipboard';

  @override
  String get noHouseholdIdReturned => 'No household ID returned';

  @override
  String get inviteAccepted => 'Вы далучыліся да сям\'і';

  @override
  String get alreadyMember => 'Вы ўжо з\'яўляецеся членам гэтай сям\'і';

  @override
  String get inviteAcceptFailed => 'Не ўдалося прыняць запрашэнне';

  @override
  String get sendInviteEmail => 'Адправіць email';

  @override
  String sendInviteEmailDescription(String email) {
    return 'Адправіць запрашэнне на $email';
  }

  @override
  String get inviteEmailSubject => 'Запрашэнне ў сям\'ю MyKid';

  @override
  String inviteEmailBody(String link, String code) {
    return 'Вас запрасілі ў сям\'ю ў MyKid!\n\nСпасылка запрашэння: $link\nАбо выкарыстайце код: $code\n\nАдкрыйце спасылку або ўвядзіце код у дадатку MyKid, каб прыняць запрашэнне.';
  }

  @override
  String get inviteEmailSent => 'Ліст з запрашэннем адпраўлены';

  @override
  String inviteEmailSentTo(String email) {
    return 'Запрашэнне адпраўлена на $email';
  }

  @override
  String get inviteEmailFailed =>
      'Не ўдалося адправіць ліст, але запрашэнне створана';

  @override
  String get createHousehold => 'Стварыць сям\'ю';

  @override
  String get createHouseholdTitle => 'Стварыць сям\'ю';

  @override
  String get createHouseholdDescription =>
      'Стварыце сям\'ю, каб запрашаць удзельнікаў і дзяліцца дзецьмі і запісамі дзённіка.';

  @override
  String get householdName => 'Назва сям\'і';

  @override
  String get householdNameHint => 'Неабавязкова';

  @override
  String get householdCreated => 'Сям\'я створана';

  @override
  String get createHouseholdFailed => 'Не ўдалося стварыць сям\'ю';

  @override
  String get legal => 'Правая інфармацыя';

  @override
  String get privacyPolicy => 'Палітыка канфідэнцыйнасці';

  @override
  String get termsOfService => 'Умовы выкарыстання';

  @override
  String get support => 'Падтрымка';

  @override
  String get sourceCode => 'Зыходны код';

  @override
  String get supportDevelopment => 'Падтрымаць распрацоўку';

  @override
  String get licenses => 'Ліцэнзіі адкрытага ПЗ';

  @override
  String get requestAccountDeletionInstructions => 'Request account deletion';

  @override
  String get requestAccountDeletionInstructionsSubtitle =>
      'Instructions and data deletion details';

  @override
  String get deleteAccount => 'Выдаліць акаўнт';

  @override
  String get deleteAccountConfirm =>
      'Выдаліць акаўнт? Усе вашы даныя будуць беззваротна выдалены. Гэта дзеянне нельга адмяніць.';

  @override
  String get deleteAccountConfirmSubtitle =>
      'Вы таксама можаце запытаць выдаленне па email.';

  @override
  String get deleteAccountFailed =>
      'Не ўдалося выдаліць акаўнт. Паспрабуйце зноў або звярніцеся ў падтрымку.';

  @override
  String get exportMyData => 'Экспарт маіх даных';

  @override
  String get exportMyDataSubtitle => 'Запытаць копію даных (GDPR)';

  @override
  String get aiProviders => 'AI Правайдэры';

  @override
  String get aiProvidersSubtitle => 'Наладзіць AI для аналізу фота';

  @override
  String get subscription => 'Падпіска';

  @override
  String get subscriptionSubtitle => 'Immich і AI без наладак';

  @override
  String get planBasic => 'Базовы';

  @override
  String get planBasicPrice => '\$6/мес';

  @override
  String get planPremium => 'Прэміум';

  @override
  String get planPremiumPrice => '\$13/мес';

  @override
  String get startTrial7Days => '7 дзён бясплатна';

  @override
  String get subscriptionSuccess => 'Трыял актываваны';

  @override
  String get subscriptionCancel => 'Падпіска скасавана';

  @override
  String get premiumRequiredForAi => 'Для AI патрэбна падпіска Прэміум';

  @override
  String get sessionExpiredSignInAgain =>
      'Сесія скончылася. Выйдзіце і увайдзіце зноў.';

  @override
  String get sessionExpiredCheckProject =>
      'Сесія недазейная. Выйдзіце і увайдзіце зноў. Калі застанецца — у Наладах укажыце той жа праект Supabase, дзе разгорнуты Edge Functions.';

  @override
  String get changeSupabase => 'Змяніць Supabase';

  @override
  String get changeSupabaseSubtitle => 'Пераключыцца на іншы праект Supabase';

  @override
  String get changeSupabaseConfirm => 'Змяніць праект Supabase?';

  @override
  String get changeSupabaseConfirmMessage =>
      'Вы будзеце выйсці з акаўнта. Дадатак зачыніцца. Адкрыйце яго зноў, каб ўвесці новыя ўліковыя даныя Supabase.';

  @override
  String get aiProviderSettings => 'AI Правайдэры';

  @override
  String get aiProviderSettingsDescription =>
      'Наладзьце AI правайдэры для аўтаматычнай генерацыі апісанняў да фотаздымкаў. Увядзіце вашы API ключы і выберыце правайдэра.';

  @override
  String get selectProvider => 'Выберыце правайдэра';

  @override
  String get openAi => 'OpenAI (GPT-4 Vision)';

  @override
  String get openAiDescription => 'Высокая якасць, платна';

  @override
  String get gemini => 'Google Gemini';

  @override
  String get geminiDescription => 'Добрая якасць, ёсць бясплатны tier';

  @override
  String get claude => 'Anthropic Claude';

  @override
  String get claudeDescription => 'Высокая якасць, платна';

  @override
  String get deepSeek => 'DeepSeek';

  @override
  String get deepSeekDescription => 'Толькі тэкст, без аналізу фота';

  @override
  String get customAi => 'Custom AI (API Gateway)';

  @override
  String get customAiDescription => 'Уласны API Gateway з X-Gateway-Token';

  @override
  String get customAiBaseUrl => 'URL сервера';

  @override
  String get customAiBaseUrlHint => 'http://144.91.127.194';

  @override
  String get aiGatewayToken => 'AI Gateway Токен';

  @override
  String get aiGatewayTokenSubtitle => 'Статыстыка выкарыстання AI';

  @override
  String get createGatewayToken => 'Стварыць токен';

  @override
  String get createGatewayTokenHint =>
      'Захавайце гэты токен. Ён больш не будзе паказаны.';

  @override
  String get aiGatewayUsage => 'Выкарыстанне';

  @override
  String get aiGatewayUsageSubtitle => 'Токены выкаристана для AI запытаў';

  @override
  String aiGatewayUsageStats(String input, String output, String total) {
    return 'Уваход: $input | Выхад: $output | Усяго: $total';
  }

  @override
  String get apiKeys => 'API Ключы';

  @override
  String get enterApiKey => 'Увядзіце API ключ';

  @override
  String get getApiKey => 'Атрымаць API ключ';

  @override
  String get generateDescription => 'Згенераваць апісанне';

  @override
  String get generatingDescription => 'Аналізую фота...';

  @override
  String get descriptionGenerated => 'Апісанне згенеравана';

  @override
  String get noPhotoForAnalysis => 'Няма фота для аналізу';

  @override
  String get apiKeyNotConfigured =>
      'AI правайдэр не наладжаны. Калі ласка, наладзьце яго ў Наладах.';

  @override
  String analysisFailed(String error) {
    return 'Не ўдалося прааналізаваць фота: $error';
  }
}
