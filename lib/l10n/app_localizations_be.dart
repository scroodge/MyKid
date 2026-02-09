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
  String get onboardingTestAndContinue => 'Праверыць падключэнне і працягнуць';

  @override
  String get inviteToFamily => 'Запрасіць у сям\'ю';

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
  String get inviteAccepted => 'Вы далучыліся да сям\'і';

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
  String get licenses => 'Ліцэнзіі адкрытага ПЗ';

  @override
  String get deleteAccount => 'Выдаліць акаўнт';

  @override
  String get deleteAccountConfirm =>
      'Выдаліць акаўнт? Усе вашы даныя будуць беззваротна выдалены. Гэта дзеянне нельга адмяніць.';

  @override
  String get deleteAccountConfirmSubtitle =>
      'Вы таксама можаце запытаць выдаленне па email.';

  @override
  String get exportMyData => 'Экспарт маіх даных';

  @override
  String get exportMyDataSubtitle => 'Запытаць копію даных (GDPR)';
}
