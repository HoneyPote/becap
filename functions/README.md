# Firebase Functions – Stripe payments (MVP)

## Config required
Set these before deploying:

```
firebase functions:config:set stripe.secret_key="sk_test_..." \
  stripe.webhook_secret="whsec_..." \
  stripe.success_url="https://your-app.example/success" \
  stripe.cancel_url="https://your-app.example/cancel"
```

- Webhook endpoint: deploy `stripeWebhook` and configure the Stripe dashboard to call it with the webhook secret above.
- Apple Pay / card are handled by Stripe Checkout (Apple Pay works in Safari with your test domain).

## Development
- `npm install`
- `npm run build` (emulator) or `firebase emulators:start --only functions` for local testing.
