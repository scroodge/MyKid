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
  String get startFromScratch => 'Начать с нуля';

  @override
  String get startFromScratchConfirm => 'Сбросить и запустить онбординг?';

  @override
  String get startFromScratchConfirmMessage =>
      'Все сохранённые настройки Supabase и Immich будут удалены. Приложение закроется. Откройте его снова, чтобы настроить с нуля.';

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
  String get suggestionsTab => 'Предложения';

  @override
  String get scanningPhotos => 'Сканирование фото…';

  @override
  String foundPhotosWithChild(int count, String childName) {
    return 'Найдено $count фото с $childName';
  }

  @override
  String get createEntryFromSuggestion => 'Создать запись';

  @override
  String get noSuggestions => 'Нет предложений';

  @override
  String get scanNow => 'Сканировать';

  @override
  String get stopScan => 'Стоп';

  @override
  String get scanNowHint => 'Нажмите кнопку выше для поиска фото';

  @override
  String get scanLimitHint => 'Сканируется до 500 последних фото';

  @override
  String get addReferencePhotosPrompt =>
      'Добавьте эталонные фото детей для распознавания';

  @override
  String get addReferencePhotosButton => 'Добавить эталонные фото';

  @override
  String get linkChildToImmichPersonHint =>
      'Или привяжите ребёнка к персоне в Immich (Настройки → Дети → Редактировать), чтобы использовать распознавание лиц Immich.';

  @override
  String get linkToImmichPerson => 'Привязать к персоне Immich';

  @override
  String get linkToImmichPersonSubtitle =>
      'Использовать распознавание лиц Immich для предложений';

  @override
  String get selectImmichPerson => 'Выбрать персону';

  @override
  String immichPersonLinked(String name) {
    return 'Привязан к $name';
  }

  @override
  String get unlinkImmichPerson => 'Отвязать';

  @override
  String get replaceReferencePhotos => 'Заменить все';

  @override
  String get replaceReferencePhotosConfirm => 'Заменить эталонные фото?';

  @override
  String get replaceReferencePhotosConfirmMessage =>
      'Все текущие эталонные фото будут удалены. Затем выберите новые.';

  @override
  String get replaceReferencePhotosDone =>
      'Эталонные фото удалены. Выберите новые.';

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
  String get onboardingExistingAccount => 'У меня уже есть аккаунт';

  @override
  String get onboardingExistingAccountSubtitle =>
      'Войти с URL и anon key Supabase';

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

  @override
  String get onboardingTestSupabaseFirst =>
      'Сначала проверьте подключение. Если схема отсутствует — выполните SQL в Supabase Dashboard.';

  @override
  String get onboardingSchemaMissingTitle => 'Требуется настройка базы данных';

  @override
  String get onboardingSchemaMissingDescription =>
      'Проекту Supabase нужна наша схема. Скопируйте SQL, вставьте в Supabase Dashboard → SQL Editor, выполните, затем нажмите «Повторить».';

  @override
  String get onboardingCopySql => 'Скопировать SQL';

  @override
  String get onboardingOpenSupabaseDashboard => 'Открыть SQL Editor в Supabase';

  @override
  String get onboardingSqlCopied => 'SQL скопирован в буфер';

  @override
  String get onboardingSqlCopyFailed => 'Не удалось скопировать SQL';

  @override
  String get onboardingRunMigrationsFirst =>
      'Сначала проверьте подключение и выполните миграции';

  @override
  String get inviteToFamily => 'Пригласить в семью';

  @override
  String get myFamily => 'Моя семья';

  @override
  String get familyMembers => 'Участники семьи';

  @override
  String get householdMemberRoleOwner => 'Владелец';

  @override
  String get householdMemberRoleMember => 'Участник';

  @override
  String get you => 'Вы';

  @override
  String get inviteEmail => 'Email';

  @override
  String get inviteEmailHint => 'Введите email';

  @override
  String get createInvite => 'Создать приглашение';

  @override
  String get inviteCreated => 'Приглашение создано';

  @override
  String get inviteLink => 'Ссылка приглашения';

  @override
  String get inviteCode => 'Код приглашения';

  @override
  String get copyInviteLink => 'Копировать ссылку';

  @override
  String get copyInviteCode => 'Копировать код';

  @override
  String get inviteCopied => 'Скопировано';

  @override
  String get pendingInvites => 'Ожидающие приглашения';

  @override
  String get noInvites => 'Нет ожидающих приглашений';

  @override
  String inviteExpires(String date) {
    return 'Истекает $date';
  }

  @override
  String get cancelInvite => 'Отменить приглашение';

  @override
  String cancelInviteConfirm(String email) {
    return 'Отменить приглашение для $email?';
  }

  @override
  String get acceptInvite => 'Принять приглашение';

  @override
  String get acceptInviteTitle => 'Присоединиться к семье';

  @override
  String get acceptInviteDescription =>
      'Вас пригласили в семью. Примите приглашение, чтобы получить доступ к общим детям и записям дневника.';

  @override
  String get inviteNotFound => 'Приглашение не найдено или истекло';

  @override
  String get inviteCodeTooShort => 'Введите не менее 8 символов';

  @override
  String get inviteOpenLinkHint =>
      'Откройте ссылку-приглашение из письма или сообщения.';

  @override
  String get orEnterCodeManually => 'Или введите код вручную';

  @override
  String get enterInviteCodeHint => 'Введите 8-символьный код';

  @override
  String get searchByCode => 'Найти по коду';

  @override
  String get invitedBy => 'Пригласил(а):';

  @override
  String get signInToAcceptInvite =>
      'Войдите или создайте аккаунт, чтобы принять приглашение.';

  @override
  String get signUpToAccept => 'Зарегистрироваться для принятия';

  @override
  String get cancelInviteFailed => 'Не удалось отменить приглашение';

  @override
  String get expired => 'Истекло';

  @override
  String get searching => 'Поиск…';

  @override
  String get inviteAcceptedDataNotRefreshed =>
      'Приглашение принято, но данные не обновились. Попробуйте перезапустить приложение.';

  @override
  String get inviteAcceptErrorRetry =>
      'Ошибка при принятии приглашения. Попробуйте еще раз или перезапустите приложение.';

  @override
  String get inviteAcceptErrorRestart =>
      'Ошибка при принятии приглашения. Попробуйте перезапустить приложение.';

  @override
  String createHouseholdFailedWithReason(String message, String reason) {
    return '$message: $reason';
  }

  @override
  String get supportEmailCopied => 'Email скопирован в буфер обмена';

  @override
  String get noHouseholdIdReturned => 'ID семьи не возвращён';

  @override
  String get inviteAccepted => 'Вы присоединились к семье';

  @override
  String get alreadyMember => 'Вы уже являетесь членом этой семьи';

  @override
  String get inviteAcceptFailed => 'Не удалось принять приглашение';

  @override
  String get sendInviteEmail => 'Отправить email';

  @override
  String sendInviteEmailDescription(String email) {
    return 'Отправить приглашение на $email';
  }

  @override
  String get inviteEmailSubject => 'Приглашение в семью MyKid';

  @override
  String inviteEmailBody(String link, String code) {
    return 'Вас пригласили в семью в MyKid!\n\nСсылка приглашения: $link\nИли используйте код: $code\n\nОткройте ссылку или введите код в приложении MyKid, чтобы принять приглашение.';
  }

  @override
  String get inviteEmailSent => 'Письмо с приглашением отправлено';

  @override
  String inviteEmailSentTo(String email) {
    return 'Приглашение отправлено на $email';
  }

  @override
  String get inviteEmailFailed =>
      'Не удалось отправить письмо, но приглашение создано';

  @override
  String get createHousehold => 'Создать семью';

  @override
  String get createHouseholdTitle => 'Создать семью';

  @override
  String get createHouseholdDescription =>
      'Создайте семью, чтобы приглашать участников и делиться детьми и записями дневника.';

  @override
  String get householdName => 'Название семьи';

  @override
  String get householdNameHint => 'Необязательно';

  @override
  String get householdCreated => 'Семья создана';

  @override
  String get createHouseholdFailed => 'Не удалось создать семью';

  @override
  String get legal => 'Правовая информация';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfService => 'Условия использования';

  @override
  String get support => 'Поддержка';

  @override
  String get sourceCode => 'Исходный код';

  @override
  String get supportDevelopment => 'Поддержать разработку';

  @override
  String get licenses => 'Лицензии открытого ПО';

  @override
  String get requestAccountDeletionInstructions =>
      'Запросить удаление аккаунта';

  @override
  String get requestAccountDeletionInstructionsSubtitle =>
      'Инструкция и сведения об удалении данных';

  @override
  String get deleteAccount => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirm =>
      'Удалить аккаунт? Все ваши данные будут безвозвратно удалены. Это действие нельзя отменить.';

  @override
  String get deleteAccountConfirmSubtitle =>
      'Вы также можете запросить удаление по email.';

  @override
  String get deleteAccountFailed =>
      'Не удалось удалить аккаунт. Попробуйте снова или обратитесь в поддержку.';

  @override
  String get exportMyData => 'Экспорт моих данных';

  @override
  String get exportMyDataSubtitle => 'Запросить копию данных (GDPR)';

  @override
  String get aiProviders => 'AI Провайдеры';

  @override
  String get aiProvidersSubtitle => 'Настроить AI для анализа фото';

  @override
  String get changeSupabase => 'Изменить Supabase';

  @override
  String get changeSupabaseSubtitle =>
      'Переключиться на другой проект Supabase';

  @override
  String get changeSupabaseConfirm => 'Изменить проект Supabase?';

  @override
  String get changeSupabaseConfirmMessage =>
      'Вы будете выйти из аккаунта. Приложение закроется. Откройте его снова, чтобы ввести новые учётные данные Supabase.';

  @override
  String get aiProviderSettings => 'AI Провайдеры';

  @override
  String get aiProviderSettingsDescription =>
      'Настройте AI провайдеры для автоматической генерации описаний к фотографиям. Введите ваши API ключи и выберите провайдера.';

  @override
  String get selectProvider => 'Выберите провайдера';

  @override
  String get openAi => 'OpenAI (GPT-4 Vision)';

  @override
  String get openAiDescription => 'Высокое качество, платно';

  @override
  String get gemini => 'Google Gemini';

  @override
  String get geminiDescription => 'Хорошее качество, есть бесплатный tier';

  @override
  String get claude => 'Anthropic Claude';

  @override
  String get claudeDescription => 'Высокое качество, платно';

  @override
  String get deepSeek => 'DeepSeek';

  @override
  String get deepSeekDescription => 'Только текст, без анализа фото';

  @override
  String get customAi => 'Custom AI (API Gateway)';

  @override
  String get customAiDescription => 'Свой API Gateway с X-Gateway-Token';

  @override
  String get customAiBaseUrl => 'URL сервера';

  @override
  String get customAiBaseUrlHint => 'http://144.91.127.194';

  @override
  String get apiKeys => 'API Ключи';

  @override
  String get enterApiKey => 'Введите API ключ';

  @override
  String get getApiKey => 'Получить API ключ';

  @override
  String get generateDescription => 'Сгенерировать описание';

  @override
  String get generatingDescription => 'Анализирую фото...';

  @override
  String get descriptionGenerated => 'Описание сгенерировано';

  @override
  String get noPhotoForAnalysis => 'Нет фото для анализа';

  @override
  String get apiKeyNotConfigured =>
      'AI провайдер не настроен. Пожалуйста, настройте его в Настройках.';

  @override
  String analysisFailed(String error) {
    return 'Не удалось проанализировать фото: $error';
  }
}
