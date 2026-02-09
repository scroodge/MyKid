// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Дневник MyKid';

  @override
  String get appDescription => 'Детский дневник и моменты ребёнка';

  @override
  String get signInSubtitle => 'Войдите, чтобы синхронизировать дневник';

  @override
  String get email => 'Email';

  @override
  String get password => 'Пароль';

  @override
  String get signIn => 'Войти';

  @override
  String get createAccount => 'Создать аккаунт';

  @override
  String get signUpTitle => 'Регистрация в MyKid Journal';

  @override
  String get signUpSubtitle => 'Введите email и придумайте пароль.';

  @override
  String get hintEmail => 'you@example.com';

  @override
  String get enterYourEmail => 'Введите email';

  @override
  String get enterValidEmail => 'Введите корректный email';

  @override
  String get choosePassword => 'Придумайте пароль';

  @override
  String get passwordMinLength => 'Пароль должен быть не менее 6 символов';

  @override
  String get confirmPassword => 'Подтвердите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get signUp => 'Зарегистрироваться';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get checkEmailConfirm => 'Проверьте почту, чтобы подтвердить аккаунт.';

  @override
  String get signUpDisabled =>
      'Регистрация отключена. В Supabase: Authentication → Providers → Email включите «Allow new users to sign up».';

  @override
  String get settings => 'Настройки';

  @override
  String get profile => 'Профиль';

  @override
  String get edit => 'Изменить';

  @override
  String get family => 'Семья';

  @override
  String get manageChildren => 'Дети';

  @override
  String get manageChildrenSubtitle =>
      'Имя, дата рождения. Фото можно сохранять в альбом Immich ребёнка.';

  @override
  String get sync => 'Синхронизация';

  @override
  String get immich => 'Immich';

  @override
  String get immichSubtitle => 'URL сервера и API-ключ';

  @override
  String get account => 'Аккаунт';

  @override
  String get signOut => 'Выйти';

  @override
  String version(String version) {
    return 'Версия $version';
  }

  @override
  String get save => 'Сохранить';

  @override
  String get immichDescription =>
      'URL сервера Immich и API-ключ (создайте ключ в Immich: Настройки → API Keys). Успешная проверка подключения сохраняет их.';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get serverUrlHint => 'https://photos.example.com';

  @override
  String get apiKey => 'API-ключ';

  @override
  String get enterUrlAndKey => 'Введите URL и API-ключ';

  @override
  String get connectedSuccessfully => 'Подключено';

  @override
  String get connectionFailed => 'Ошибка подключения';

  @override
  String get testConnection => 'Проверить подключение';

  @override
  String get testing => 'Проверка…';

  @override
  String get connectedAndSaved => 'Подключено и сохранено';

  @override
  String get saved => 'Сохранено';

  @override
  String get children => 'Дети';

  @override
  String get noChildrenYet => 'Пока нет детей';

  @override
  String get addChild => 'Добавить ребёнка';

  @override
  String get deleteChild => 'Удалить ребёнка?';

  @override
  String deleteChildConfirm(String name) {
    return 'Удалить «$name»? Записи дневника не удаляются.';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String bornDate(int day, int month, int year) {
    return 'Родился(ась) $day.$month.$year';
  }

  @override
  String get editChild => 'Редактировать ребёнка';

  @override
  String get tapToAddOrChangePhoto =>
      'Нажмите, чтобы добавить или сменить фото';

  @override
  String get name => 'Имя';

  @override
  String get dateOfBirthOptional => 'Дата рождения (необязательно)';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String get cropPhoto => 'Обрезать фото';

  @override
  String get photoWillBeSaved => 'Фото будет сохранено в профиле';

  @override
  String get photoUpdated => 'Фото обновлено';

  @override
  String get uploadFailedAvatar =>
      'Ошибка загрузки. Создайте bucket «avatars» в Supabase Storage (public).';

  @override
  String get uploadFailedChildAvatar =>
      'Ошибка загрузки. Проверьте политики Storage для аватаров детей.';

  @override
  String get configureImmichFirst => 'Сначала настройте Immich в Настройках';

  @override
  String get fromCamera => 'С камеры';

  @override
  String get fromCameraSubtitle => 'Сфотографировать сейчас, дата — сегодня';

  @override
  String get fromGallery => 'Из галереи';

  @override
  String get fromGallerySubtitle => 'Выбрать фото, дата и место из фото';

  @override
  String get emptyEntry => 'Пустая запись';

  @override
  String get batchImport => 'Массовый импорт';

  @override
  String get batchImportTooltip => 'Массовый импорт';

  @override
  String get timeline => 'Лента';

  @override
  String get addChildPrompt => 'Добавить ребёнка';

  @override
  String get addChildPromptSubtitle => 'Нажмите, чтобы создать профиль';

  @override
  String get selectChildAbove => 'Выберите ребёнка выше';

  @override
  String get noEntries => 'Нет записей';

  @override
  String get addFirstEntry => 'Добавить первую запись';

  @override
  String get noEntriesYet => 'Пока нет записей';

  @override
  String get addEntry => 'Добавить запись';

  @override
  String get retry => 'Повторить';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get noTitle => 'Без названия';

  @override
  String photosCount(int count) {
    return '$count фото';
  }

  @override
  String get newEntry => 'Новая запись';

  @override
  String get entry => 'Запись';

  @override
  String get deleteEntry => 'Удалить запись?';

  @override
  String get alsoRemoveFromAlbum => 'Также удалить фото из альбома ребёнка';

  @override
  String get date => 'Дата';

  @override
  String get child => 'Ребёнок';

  @override
  String get addChildInSettings => 'Добавьте ребёнка в Настройках → Дети';

  @override
  String get placeOptional => 'Место (необязательно)';

  @override
  String get placeHint => 'например, из фото или введите вручную';

  @override
  String get description => 'Описание';

  @override
  String get descriptionHint => 'Что произошло сегодня?';

  @override
  String get photosVideos => 'Фото / видео';

  @override
  String get add => 'Добавить';

  @override
  String get noMediaAttached =>
      'Нет медиа. Добавьте через «Добавить» или массовый импорт.';

  @override
  String get pendingSaveToUpload => 'Ожидает (загрузка при сохранении)';

  @override
  String get couldNotReadImage => 'Не удалось прочитать изображение';

  @override
  String uploadFailedWithError(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get selectAChild => 'Выберите ребёнка';

  @override
  String get pickFilesAndUpload => 'Выбрать файлы и загрузить';

  @override
  String get picking => 'Выбор…';

  @override
  String get uploading => 'Загрузка…';

  @override
  String uploadedCount(int current, int total) {
    return 'Загружено $current из $total';
  }

  @override
  String get batchImportDescription =>
      'Выберите несколько фото или видео с устройства. Они будут загружены в Immich, затем можно создать одну запись со всеми.';

  @override
  String get noValidFiles => 'Нет подходящих файлов';

  @override
  String filesUploadedCount(int count) {
    return 'Загружено файлов: $count';
  }

  @override
  String get createOneEntryWithAll => 'Создать одну запись со всеми';

  @override
  String get yourName => 'Ваше имя';

  @override
  String get profileUpdated => 'Профиль обновлён';

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
  String get useFamilyImmich => 'Использовать Immich семьи';

  @override
  String get useFamilyImmichDescription =>
      'У семьи настроен Immich. Использовать его на этом устройстве? URL и API-ключ будут сохранены локально.';

  @override
  String get saveToFamily => 'Сохранить в семью';

  @override
  String get saveToFamilyDescription =>
      'Сохранить текущие URL и API-ключ Immich для семьи? Остальные участники смогут использовать тот же Immich. Ключ хранится в облаке в зашифрованном виде.';

  @override
  String get useFamilyImmichFailed =>
      'Не удалось загрузить настройки Immich семьи';

  @override
  String get onboardingTitle => 'Настройка';

  @override
  String get onboardingAccountTypeTitle => 'Как хотите начать?';

  @override
  String get onboardingNewAccount => 'Новый аккаунт';

  @override
  String get onboardingNewAccountSubtitle => 'Создайте свой Immich и Supabase';

  @override
  String get onboardingFamily => 'Семья';

  @override
  String get onboardingFamilySubtitle =>
      'Присоединиться по коду приглашения (скоро)';

  @override
  String get onboardingFamilyComingSoon =>
      'Семейная настройка скоро будет доступна. Пока используйте «Новый аккаунт».';

  @override
  String get onboardingImmichTitle => 'Immich';

  @override
  String get onboardingImmichQuestion =>
      'Есть ли у вас URL сервера Immich и API-ключ?';

  @override
  String get onboardingImmichYes => 'Да, есть';

  @override
  String get onboardingImmichNo => 'Нет, создать';

  @override
  String get onboardingCreateImmich => 'Создать Immich на PikaPods';

  @override
  String get onboardingCreateImmichSubtitle =>
      'Откроется в браузере. После настройки вернитесь и введите URL и API-ключ.';

  @override
  String get onboardingSupabaseTitle => 'Supabase';

  @override
  String get onboardingSupabaseDescription =>
      'Создайте проект на supabase.com, выполните миграции, затем скопируйте URL и anon key из Settings → API.';

  @override
  String get onboardingSupabaseUrlHint => 'https://xxxx.supabase.co';

  @override
  String get onboardingAnonKey => 'Anon key';

  @override
  String get onboardingContinue => 'Далее';

  @override
  String get onboardingSkipImmich => 'Пропустить';

  @override
  String get onboardingTestAndContinue => 'Проверить подключение и продолжить';
}
