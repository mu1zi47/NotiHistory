# Feedback form

The native app sends an HTTPS POST to https://notihistory.vercel.app/api/send-message only after the user validates the form and explicitly chooses Send in the confirmation sheet. Cancellation and opening the form do not make network requests.

The JSON payload contains exactly `name`, `telegramUser` (optional), `topic`, `message`, and the fixed marker `source: "app"`. No notification history, archive, logs, device identifiers, or app settings are attached. Standard network metadata such as the client IP is necessarily visible to hosting infrastructure.

The existing Next.js route in the separate NotiHistoryWeb project validates these fields and forwards them to Telegram. It uses server-only environment variables `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`. Configure these in the website Vercel project, Settings → Environment Variables → Production, and redeploy. Never add the bot token to the Android app or use a NEXT_PUBLIC_ prefix. The recipient must first start the bot.

Offline and error responses leave the typed text in the open form. No automatic retry or background upload is performed. The existing API returns 503 if Telegram credentials are missing; Android displays a localized message suggesting email or Telegram contact.

Verification: an empty POST to the deployed route returned HTTP 400 with field validation errors. This verifies the deployed endpoint, but deliberately does not send a test message or establish whether the production bot credentials are configured. Widget tests verify consent, cancellation, exact fields, error retention, retry, disabled duplicate submission, dark theme, small screens and keyboard layout.


The form expands inline below the contact row, preserving its draft while collapsed. The chevron rotates on expansion. Topic selection uses the shared content-sized HistorySheet and a single rounded option block with selected icons. Validation errors use animated tinted panels. The internet/data confirmation remains a separate sheet before each send.


## App source marker

Android now includes `source: "app"` so the website route can distinguish native feedback from website forms. The website handler currently ignores this field and still uses its website headline. In a later website change, use `data.source === "app"` to choose `📩 Новое сообщение из приложения NotiHistory` and `📱 Источник: Android-приложение` instead of the website headline/source. Missing source should continue to mean website. This marker is not authentication. No website code or deployment was changed for this Android update.
