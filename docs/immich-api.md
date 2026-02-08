# Immich API — пути и авторизация

Данные проверены для **Immich server 2.5.5**. При обновлении Immich пути могут измениться.

## Базовый URL

- Без слэша в конце: `http://host:port` (например `http://192.168.100.118:2283`).
- Все API под префиксом: `/api/`.

## Авторизация

- Заголовок: `x-api-key: <API_KEY>`.
- Опционально для GET (если клиент не передаёт заголовки): query-параметр `key=<API_KEY>`.

---

## Превью и миниатюры

**Эндпоинт:** `GET /api/assets/:id/thumbnail`

**Query-параметры:**

| Параметр | Значение      | Описание                          |
|----------|---------------|-----------------------------------|
| `format` | `JPEG`, `WEBP`| Формат изображения (по умолчанию JPEG). |
| `size`   | `thumbnail`, `preview`, `fullsize` | Размер. Без параметра — маленький thumbnail. |

**Примеры:**

- Маленькая миниатюра:  
  `GET /api/assets/{assetId}/thumbnail?format=JPEG`
- Крупное превью:  
  `GET /api/assets/{assetId}/thumbnail?format=JPEG&size=preview`
- Большой размер:  
  `GET /api/assets/{assetId}/thumbnail?format=JPEG&size=fullsize`

**Использование в приложении:** список/сетка фото — `size=preview`; при необходимости можно пробовать `size=fullsize` (на сервере может отдаваться оригинал или редирект).

---

## Оригинал файла (скачивание)

**Эндпоинт:** `GET /api/assets/:id/original`

**Параметры:** только path. Авторизация — заголовок `x-api-key` (или `key` в query, если нужен доступ по одной ссылке).

**Пример:**

```
GET /api/assets/075685cb-d4f0-4090-956c-bd8774ecf28f/original
Header: x-api-key: <API_KEY>
```

**Ответ:** HTTP 200, тело — бинарный файл (JPEG и т.д.).

**Использование в приложении:** просмотр фото в полном размере, кнопка «Поделиться» — загрузка через этот endpoint, затем шаринг файла.

---

## Что не работает (404 в 2.5.5)

Эти пути в текущей версии **не используются** и возвращают 404:

- `GET /api/assets/:id/download`
- `GET /api/asset/:id/download` (единственное число)
- `GET /api/asset/:id?size=fullsize`

В v2 API за скачивание оригинала отвечает только `/api/assets/:id/original`.

---

## Остальные используемые эндпоинты (MyKid)

Кратко для справки:

| Действие        | Метод | Путь                          |
|-----------------|-------|-------------------------------|
| Загрузка ассета | POST  | `/api/assets`                 |
| Поиск ассетов   | POST  | `/api/assets/search`         |
| Создание альбома| POST  | `/api/albums`                 |
| Добавить в альбом | PUT | `/api/albums/:albumId/assets` |
| Удалить из альбома | DELETE | `/api/albums/:albumId/assets` |
| Проверка сервера| GET   | `/api/server/version`         |

---

## Проверка через curl

Из корня проекта (с заполненным `.env`):

```bash
bash scripts/test-immich-download.sh
```

В `.env` должны быть заданы: `IMMICH_SERVER_URL`, `IMMICH_API_KEY`, при необходимости `ASSET_ID`.

Ручная проверка оригинала:

```bash
curl -s -o out.jpg -w "%{http_code}" \
  -H "x-api-key: YOUR_API_KEY" \
  "http://HOST:PORT/api/assets/ASSET_ID/original"
# 200 — успех; тело — файл изображения
```

---

*Документ обновлён: 2025-02-08, Immich 2.5.5.*
