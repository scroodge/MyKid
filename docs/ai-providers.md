# AI providers — автогенерация описаний к фото

В записи дневника (режим редактирования) можно нажать **«Сгенерировать описание»**: приложение отправит фото (или текст о содержимом) выбранному AI-провайдеру и подставит короткое тёплое описание на русском.

## Провайдеры

| Провайдер | Анализ фото | Как работает |
|-----------|-------------|-------------|
| **OpenAI** (GPT-4o) | Да | Фото в base64 отправляется в Vision API. |
| **Gemini** (1.5 Flash) | Да | Фото в base64 в `generateContent`. |
| **Claude** (3.5 Sonnet) | Да | Фото в base64 в Messages API. |
| **DeepSeek** (chat) | Через устройство | На телефоне: [ML Kit](https://developers.google.com/ml-kit/vision/image-labeling) получает метки по фото → в DeepSeek отправляется только текст («по фото определили: метка1, метка2… — напиши описание»). Официальный API DeepSeek изображения не принимает. На web кнопка «Сгенерировать» с DeepSeek не даст описания по фото (метки на устройстве недоступны). |

Ключи и выбор провайдера хранятся только на устройстве (flutter_secure_storage). В облако отправляются только запросы к выбранному API (из приложения напрямую).

## Настройка

**Настройки → AI-провайдеры** (маршрут `/settings-ai-providers`):

1. Ввести API-ключ нужного провайдера (один или несколько).
2. Выбрать провайдер по умолчанию для «Сгенерировать описание».
3. При необходимости нажать «Проверить подключение».

Где взять ключи:

- **OpenAI:** [platform.openai.com/api-keys](https://platform.openai.com/api-keys)
- **Gemini:** [aistudio.google.com](https://aistudio.google.com) → Get API key
- **Claude:** [console.anthropic.com](https://console.anthropic.com) → API keys
- **DeepSeek:** [platform.deepseek.com](https://platform.deepseek.com) — ключ формата `sk-...`

## Скрипт проверки DeepSeek (текст)

Из корня проекта (в `.env` опционально: `DEEPSEEK_API_KEY=sk-...`):

```bash
./scripts/test-deepseek-vision.sh
```

Скрипт проверяет: vision-эндпоинт (404), chat с картинкой (400), текстовый запрос (ожидается 200). Для генерации описаний по фото в приложении используется только текстовый сценарий с метками ML Kit.

## Модули в коде

- `lib/core/ai_provider_storage.dart` — хранение ключей и выбранного провайдера.
- `lib/core/ai_vision_service.dart` — вызов Vision API (OpenAI/Gemini/Claude) или сценарий DeepSeek (метки + текст).
- `lib/core/on_device_image_labels.dart` — единая точка входа для получения меток по фото (на Android/iOS — ML Kit, на web — заглушка).
- `lib/features/settings/ai_provider_settings_screen.dart` — экран настроек AI-провайдеров.
