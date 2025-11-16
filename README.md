# Campus Navigation (Web / Flutter)

Production build & automated deployment to Vercel are configured.

## Features
- Multi-layer campus map (standard + satellite/3D).
- Entrance-aware routing (walking / multi-mode logic).
- Compass, zoom, 2D/3D toggle.
- Building info bottom sheet (directions / start / share).
- Favorites & recent buildings.
- Navigation HUD during active route.

## Local Build
```cmd
flutter pub get
flutter build web --release --no-wasm-dry-run
```
Artifacts appear in `build/web`.

## GitHub Action Deployment
Workflow: `.github/workflows/deploy.yml`.
Secrets required:
`VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`.

### Trigger a Deployment
Push to `master` or use the GitHub Actions UI (Run workflow -> Deploy Web).

### Automatic Alias
After deployment the workflow attempts to alias `campita.vercel.app` to the new build.

## Manual Vercel Deployment (Fallback)
If needed locally:
1. Install Node.js (LTS).
2. `npm install -g vercel`
3. `vercel login`
4. `vercel deploy build/web --prod --confirm`
5. `vercel alias set <DEPLOY_URL> campita.vercel.app`

## Testing
Widget tests use a lightweight `testMode` to bypass heavy map init.
Run:
```cmd
flutter test
```

## Next Improvements
- Replace deprecated `withOpacity` usages.
- Swap `print` calls for `debugPrint` under `kDebugMode`.
- Add more navigation integration tests.

---
Generated deployment docs.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
