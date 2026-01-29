# Stripe Key Verification (fix "No such payment_intent")

If you see **"No such payment_intent"** or **"Payment session expired"**, the backend and app are using different Stripe accounts. Follow these steps.

## 1. Use one Stripe account

In [Stripe Dashboard → API keys](https://dashboard.stripe.com/test/apikeys) copy:

- **Secret key** (starts with `sk_test_...`) → backend
- **Publishable key** (starts with `pk_test_...`) → wash_away app

Both must be from the **same** Stripe account (same key pair).

## 2. Backend `.env` (backend/.env)

- Open **backend/.env** (not the project root).
- Set **one line per variable**, no quotes, no spaces around `=`:

```env
STRIPE_SECRET_KEY=sk_test_51RLB5nPdbAWpbZ8zaxaskODi8aLOduup3HImwvuRzcWA3OhtDSzg6Xj10FGOp9f61HHz71Fi7STVtKKwW1DVS7mE00E0tOwOMG
STRIPE_PUBLISHABLE_KEY=pk_test_51RLB5nPdbAWpbZ8zjW263HT7LnFIcz813twUFCpk5T6PR2MqGuoWdR8wmeWuHc19Gmb7zxWXWLL3pKEdqVMCHyVQ00XH7POBCZ
```

- No blank line or space **inside** the key value.
- Save the file.

The server **always** loads `.env` from the **backend** folder (even if you start the app from the project root).

## 3. Wash Away app `.env` (wash_away/.env)

In **wash_away/.env**:

```env
STRIPE_PUBLISHABLE_KEY=pk_test_51RLB5nPdbAWpbZ8zjW263HT7LnFIcz813twUFCpk5T6PR2MqGuoWdR8wmeWuHc19Gmb7zxWXWLL3pKEdqVMCHyVQ00XH7POBCZ
```

Use the **same** publishable key as in the backend (same Stripe account).

## 4. Restart backend and rebuild app

1. **Backend**  
   Stop the Node process, then from the **backend** folder run:
   ```bash
   npm start
   ```
2. **App**  
   So the app picks up the new `.env`:
   ```bash
   cd wash_away
   flutter clean
   flutter run
   ```

## 5. Check that keys match

1. In the app, start a payment (e.g. Credit Card).
2. **Backend console** should show something like:
   ```text
   Stripe initialized successfully
   Secret key: sk_test_51RLB5nPdbAW...
   Account ID: 51RLB5nPdbAWpbZ8z... (app STRIPE_PUBLISHABLE_KEY must be pk_test_51RLB5nPdbAWpbZ8z...)
   ```
3. **App log** should show something like:
   ```text
   App key: pk_test_51RLB5nPdbAW...
   ```

The **account part** after `sk_test_` and `pk_test_` (e.g. `51RLB5nPdbAW...`) must be the **same**. If backend shows a different account ID, the backend is still using an old key: fix **backend/.env** and restart the backend again.
