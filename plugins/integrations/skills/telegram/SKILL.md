---
name: telegram
description: Recipe for integrating a Telegram bot into a web app, using webhooks and direct HTTP calls to the Telegram Bot API
---

# Telegram Bot Integration

Recipe for integrating a Telegram bot into a web app, using webhooks and direct HTTP calls to the Telegram Bot API (no wrapper library needed).

## 1. Create the Bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`, follow the prompts
3. Save the **bot token** you receive (format: `1234567890:AAH...`)

## 2. Generate a Webhook Secret

```bash
openssl rand -hex 32
```

Save this as your webhook secret.

## 3. Set Environment Variables

```
TELEGRAM_BOT_TOKEN=<your-bot-token>
TELEGRAM_WEBHOOK_SECRET=<your-generated-secret>
```

## 4. Implement the Webhook Endpoint

Expose a `POST /webhook/telegram` endpoint. The handler should:

1. **Validate** the `x-telegram-bot-api-secret-token` header against your secret
2. **Extract** the message text from `body.message.text` (also check `body.edited_message`)
3. **Process** the text (e.g. store it in a database)
4. **Optionally delete** the message from Telegram after processing:

```
POST https://api.telegram.org/bot<TOKEN>/deleteMessage
Content-Type: application/json

{"chat_id": <chat-id>, "message_id": <message-id>}
```

Return `200 OK` to Telegram on every request (otherwise Telegram retries).

## 5. Register the Webhook with Telegram

```bash
curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://<your-domain>/webhook/telegram",
    "secret_token": "<your-webhook-secret>"
  }'
```

Telegram requires HTTPS. For local development, use a tunnel (e.g. ngrok).

## 6. Verify

```bash
curl "https://api.telegram.org/bot<TOKEN>/getWebhookInfo"
```

Should show your URL and `pending_update_count`.

## Notes

- The webhook secret is sent by Telegram as the `x-telegram-bot-api-secret-token` header on every request, so you can authenticate without needing other auth middleware on that route.
- No Telegram SDK is required. Plain HTTP calls to `https://api.telegram.org/bot<TOKEN>/<method>` are sufficient.
- Handle `/start` gracefully (it's sent when a user first interacts with the bot).

## Appendix: Deleting Messages at the Source

After processing an incoming message, you can delete it from the Telegram chat so that the bot conversation stays clean. The incoming webhook payload contains everything you need:

```json
{
  "message": {
    "message_id": 42,
    "chat": { "id": 123456789 },
    "text": "some note"
  }
}
```

After storing/processing the message, call:

```
POST https://api.telegram.org/bot<TOKEN>/deleteMessage
Content-Type: application/json

{"chat_id": 123456789, "message_id": 42}
```

This turns the bot into a "fire and forget" inbox — you send a message, it gets captured by your app, and disappears from the chat.
