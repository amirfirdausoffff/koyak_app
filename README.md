<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="96" alt="Koyak icon" />
</p>

<h1 align="center">Koyak</h1>

<p align="center">
  <b>Kewangan Steady, Mental Tak Koyak.</b><br/>
  A minimalist cashflow &amp; debt tracker built for Malaysia. Offline-first, and every amount is in RM.
</p>

<p align="center">
  <img src="docs/screenshots/splash.png" width="240" alt="Splash screen" />
  &nbsp;
  <img src="docs/screenshots/dashboard.png" width="240" alt="Dashboard" />
  &nbsp;
  <img src="docs/screenshots/settings.png" width="240" alt="Google Drive backup settings" />
</p>

---

## What it does

Koyak answers one question every day: **how much can I spend today without going broke (koyak)?**

- **Baki Duit Semasa**: your live balance, shown big on the dashboard.
- **Daily limit**: *"Hari ni kau cuma boleh belanja RM XX.XX supaya tak KOYAK"*.
- **Debt tracker (Hutang)**: a checklist of monthly commitments tagged **Halal / Bank** or **Risiko / Peribadi**, with due dates that repeat every month.
- **Quick expense log (Belanja)**: type an amount, tap a category, done in under 3 seconds. Categories are Makan, Minyak, Bil, Barang Dapur, Beli-belah and Lain-lain.
- **Analytics (Duit Habis Ke Mana?)**: how the month's money splits into debt, spending and what's left, plus a bar chart of spending per category.
- **Monthly history (Sejarah Bulanan)**: every finished month is kept. Tap one to see its full breakdown.
- **Optional Google Drive backup**: a daily auto-backup and a restore on a new phone, stored in the hidden app-data folder of the user's own Drive (free, no server).

## How the money works

| | |
|---|---|
| **Baki Duit Semasa** | Baki bulan lepas + Gaji − Hutang − Belanja |
| **Had belanja harian** | Baki ÷ days left in the month (today included) |

- **Everything runs by calendar month, and nothing is deleted.** On the 1st, the dashboard starts a new month by itself, and the old month moves to history.
- **Carry forward.** Whatever is left at the end of a month rolls into the next one. A salary paid on the 25th therefore keeps working next month. An overspent month carries its negative balance too.
- **Hutang counts every commitment for the month, paid or not**, because that money is already spoken for. Each debt starts every month unpaid, and payments are recorded per month.
- Removing a debt ends it from the current month onwards, so past months still show it.

## Tech stack

- **Flutter 3.44 / Dart 3.12**, Material 3, dark-only UI with the bundled Plus Jakarta Sans font
- **MVVM** with `provider`
- **Local storage**: `shared_preferences` (JSON), fully offline
- **Charts**: `fl_chart`
- **Backup**: `google_sign_in` 7, `googleapis` (Drive v3, `drive.appdata` scope) and `workmanager` for the daily background task
- **Native Android splash & adaptive icon**, generated from the brand font

## Architecture

```
lib/
├── main.dart                 # bootstrap: locale, storage, background scheduler
├── app.dart                  # providers + MaterialApp
├── app_dependencies.dart     # composition root
├── background/               # WorkManager entry point (daily backup)
├── core/                     # theme, colours, RM/date formatters, config, errors
├── models/                   # Income, Debt, Expense, CashflowSummary, YearMonth, backups…
├── services/                 # PreferenceService, Google account, Drive backup, scheduler
├── repositories/             # Repository<T> + LocalRepository<T>, BackupRepository
├── viewmodels/               # Income / Debt / Expense / Cashflow / History / Backup + CashflowLedger
└── views/                    # dashboard, debt, expense, analytics, history, settings, shared widgets
```

- The view models depend only on the `Repository<T>` interface, so the tests swap in in-memory fakes.
- `CashflowLedger` holds the month-by-month maths, including carry forward. Both the dashboard and the history screens use it.
- Clocks are injectable, which lets the tests move time across month boundaries.

## Getting started

```bash
flutter pub get
flutter run                 # debug on a connected device / emulator
flutter test                # unit + widget tests
flutter build apk --release # build/app/outputs/flutter-apk/app-release.apk
```

<details>
<summary><b>Google Drive backup setup (optional)</b></summary>

Without this setup the app still works fully offline, and the backup screen reports that Google Sign-In is not configured.

1. In a Google Cloud project, enable the **Google Drive API**.
2. On the OAuth consent screen, add the scope `.../auth/drive.appdata`. While the app is in *Testing*, add yourself as a test user.
3. Create OAuth client IDs:
   - **Android**: package `com.koyak.koyak`, plus the SHA-1 of each signing key.
   - **Web application**: this ID is the `serverClientId` that Android's account picker needs.
   - **iOS** (optional): bundle `com.koyak.koyak`. Its reversed client ID also goes in as a URL scheme in `ios/Runner/Info.plist`.
4. Copy the example config, fill in the IDs (the file is gitignored), then run with it:

   ```bash
   cp google_oauth.example.json google_oauth.json
   flutter run --dart-define-from-file=google_oauth.json
   ```

**Behaviour**
- Backup files are named `koyak_DDMMYY.json`. A second backup on the same day overwrites that day's file, and only the newest 5 are kept.
- Choosing an account on a fresh install restores that account's latest backup automatically. If the phone already has data, the app asks first.
- The daily backup is a WorkManager task that first runs at the coming midnight, needs a network connection, and runs *around* 12 AM. The OS decides the exact time.

</details>

## Brand assets

The launcher icon is a **torn K**: a Plus Jakarta Sans ExtraBold K in `#34D399` on `#12131C`, cut by a slanted gap. The adaptive, monochrome (themed) and legacy icons and the native splash are all generated from the bundled font:

```bash
python3 tool/generate_brand_assets.py   # needs fontTools + Pillow
```

## Status

- Tested on the Android emulator (Pixel 7, API 35). iOS is configured but not built or tested yet.
- Google Drive backup is implemented and unit-tested. It needs the OAuth setup above before it can run end-to-end.
