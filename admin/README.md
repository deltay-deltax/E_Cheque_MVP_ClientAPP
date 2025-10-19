# Bank Users Admin (Static)

This is a minimal static admin to create/update `bankUsers/{uid}` documents via a Cloud Function.

## Setup

1. Deploy the HTTPS function `createOrUpdateBankUser` in `functions/index.js`.
   - Ensure environment variable `ADMIN_SECRET` is set.
2. Copy `config.example.js` to `config.js` and set:
   - `FUNCTION_URL`: The deployed function URL
   - `ADMIN_KEY`: The same value as `ADMIN_SECRET`

## Use

- Open `admin/index.html` in a browser.
- Fill the form and click "Save bank user".

The function validates and writes to Firestore using Admin SDK.
