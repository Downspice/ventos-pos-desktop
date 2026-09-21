# Ventos POS (Flutter desktop)

Desktop point-of-sale client with a two-step sign-in:

1. **Device unlock** — manager/admin email and password (`login` mutation).
2. **Staff sign-in** — pick an employee, then enter their **account password** or **POS PIN**.

Staff permissions apply for checkout and other POS operations (via `activatePosEmployee` on the server session).

After staff sign-in, the **Point of sale** page matches the web app: empty state + **Create order**, near-fullscreen **New order** modal (catalog + cart), nested **Take payment** dialog, list/masonry product views, and shared totals/customer picker patterns.

## UI (Align UI parity)

Use **`package:ventos_pos/widgets/ventos/ventos.dart`** for shared components (`VentosTextField`, `VentosButton`, `VentosSelect`, cards, dialogs, sheets). Styling tokens live in `lib/theme/ventos_colors.dart` and `ventos_input_decorations.dart` — change those to update inputs and buttons app-wide.

## Run

```bash
cd clients/pos_desktop
flutter pub get
flutter run -d macos   # or windows / linux
```

Point at your API (default `http://127.0.0.1:4000/graphql`):

```bash
flutter run -d macos --dart-define=VENTOS_API_URL=http://127.0.0.1:4000/graphql
```

## Staff PIN

In **Control Hub → Employees**, edit an employee and set a **POS PIN** (via GraphQL `updateEmployee` with `posPin` in `EmployeeInput`). Staff without a linked user account need a PIN to sign in on the register.

## Backend

Start the API before using the desktop app (default port **4000**):

```bash
cd backend && npm run dev
```

Requires Ventos backend with `posEmployeeRoster`, `posSession`, `activatePosEmployee`, and `deactivatePosEmployee` GraphQL operations.

### macOS: network or Keychain errors

- **Connection refused** — start the API: `cd backend && npm run dev`.
- **Operation not permitted / connection failed** — sandbox needs `com.apple.security.network.client` in `macos/Runner/*.entitlements`.
Session tokens are stored with **shared_preferences** (no macOS Keychain), so local debug builds work without an Apple development signing certificate.

After entitlement changes, run `flutter clean && flutter run -d macos`.

If the backend runs on another machine or port, pass the URL:

```bash
flutter run -d macos --dart-define=VENTOS_API_URL=http://127.0.0.1:4000/graphql
```
