# Backend Setup Guide for LingoX Translation API

## Overview

LingoX uses the **Google Cloud Translation API** for text translation. To keep your API credentials secure, you should **never embed API keys directly in the Flutter app**. Instead, use one of the following approaches:

---

## Option 1: API Key (Development Only)

For local development and testing, you can use a Google Cloud API key. There
are two ways to provide it:

### Step 1: Get a Google Cloud Translation API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Cloud Translation API**:
   - Open the [API library page](https://console.cloud.google.com/apis/library/translate.googleapis.com)
   - Click **Enable**
4. Create an API key:
   - Navigate to **APIs & Services > Credentials**
   - Click **Create Credentials > API Key**
   - Copy the generated key
5. (Recommended) Restrict the API key:
   - Click **Edit API key**
   - Under **Application restrictions**, choose your platform
   - Under **API restrictions**, restrict to **Cloud Translation API**
6. Enable billing for the project. The free tier includes
   **500,000 characters/month** (see the Google Cloud Translation pricing page).

### Step 2 (easiest): Enter the key inside the app

The app has a built-in key screen:

1. Open **Settings > API Configuration**
2. Paste the key into the **Google Cloud Translation** field
3. Tap **Save & Test**

The key is stored locally with `SharedPreferences` and is used immediately. No
rebuild is required. The test performs a real translation ("Hello" → Spanish),
so a successful snackbar means the API, billing, and key restrictions are all
configured correctly.

### Step 2 (alternative): Pass the key at build time

```bash
# For Linux debug build
flutter run -d linux --dart-define=GOOGLE_TRANSLATE_API_KEY=YOUR_API_KEY_HERE

# For Android emulator
flutter run -d android --dart-define=GOOGLE_TRANSLATE_API_KEY=YOUR_API_KEY_HERE

# For release build
flutter build apk --release --dart-define=GOOGLE_TRANSLATE_API_KEY=YOUR_API_KEY_HERE
```

A key saved from **Settings > API Configuration** takes precedence over the
build-time key.


---

## Option 2: Backend Proxy (Production Recommended)

For production, deploy a backend proxy that holds your API key and forwards requests. This prevents key exposure in the app binary.

### Firebase Cloud Functions Example

```javascript
// functions/index.js
const functions = require('firebase-functions');
const { v2 } = require('@google-cloud/translate');

const translate = new v2.Translate({
  key: functions.config().google.translate_key,
});

exports.translateText = functions.https.onRequest(async (req, res) => {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { text, target, source } = req.body;

  if (!text || !target) {
    return res.status(400).json({ error: 'Text and target language are required' });
  }

  try {
    let [translation] = await translate.translate(text, target);
    if (source) {
      // Source language specified
    }
    res.json({ translatedText: translation });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

### Node.js Express Example

```javascript
// server.js
const express = require('express');
const { v2 } = require('@google-cloud/translate');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const translate = new v2.Translate({
  key: process.env.GOOGLE_TRANSLATE_API_KEY,
});

app.post('/translate', async (req, res) => {
  const { text, target, source } = req.body;

  if (!text || !target) {
    return res.status(400).json({ error: 'Text and target language are required' });
  }

  try {
    let [translation] = await translate.translate(text, target);
    res.json({ translatedText: translation });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3000, () => console.log('Server running on port 3000'));
```

### Update Flutter to Use Backend Proxy

In `lib/core/network/api_config.dart`, change:

```dart
static const String baseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'https://YOUR_BACKEND_URL.com/translate',
);
```

Then update `GoogleTranslateService` to send POST requests to your backend instead of direct GET requests to Google.

---

## Google Cloud API Limits

| Parameter | Limit |
|-----------|-------|
| Characters per request | 5,000 |
| Requests per 100 seconds | 60,000 |
| Free tier | 500,000 characters/month |

---

## Supported Languages

Google Cloud Translation API supports **100+ languages**. The app fetches the supported languages list from the API at runtime. Key language codes:

| Code | Language | Code | Language |
|------|----------|------|----------|
| en | English | es | Spanish |
| fr | French | de | German |
| ja | Japanese | ko | Korean |
| zh | Chinese | ar | Arabic |
| hi | Hindi | pt | Portuguese |
| ru | Russian | it | Italian |

---

## Environment Variables Summary

| Variable | Description | Example |
|----------|-------------|---------|
| `GOOGLE_TRANSLATE_API_KEY` | Your Google Cloud API key | `AIzaSy...` |
| `BACKEND_URL` | Backend proxy URL (production) | `https://api.lingox.com/translate` |

---

## Troubleshooting

### "API key is not configured"
- Open **Settings > API Configuration** and tap **Save & Test**, or
- Make sure you're passing the API key via `--dart-define=GOOGLE_TRANSLATE_API_KEY=...`

### "API key is not valid" / "API_KEY_INVALID"
- Re-copy the key from **APIs & Services > Credentials**
- Confirm the **Cloud Translation API** is enabled for the same project
- If the key is restricted, allow the Cloud Translation API and your app/platform

### "Quota exceeded"
- Check your Google Cloud billing and quota settings
- The free tier allows 500,000 characters/month

### "Language not supported"
- Verify the language code is valid
- Check the supported languages list at [Google Cloud docs](https://cloud.google.com/translate/docs/languages)

### "No internet connection"
- Ensure the device has internet access
- On Linux, check network connectivity

---

## Security Checklist

- [ ] Never commit API keys to version control
- [ ] Use `--dart-define` for passing keys at build time
- [ ] In production, use a backend proxy
- [ ] Restrict API key to Cloud Translation API only
- [ ] Enable billing alerts to monitor usage
- [ ] Implement rate limiting on your backend proxy
