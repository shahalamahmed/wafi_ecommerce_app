# wafi_ecommerce_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Cloudinary setup

Image upload for products, categories, and profile photos requires Cloudinary.

1. Create `.env/cloudinary.json` from `.env/cloudinary.example.json`.
2. Set your real values:

```json
{
  "CLOUDINARY_CLOUD_NAME": "your-cloud-name",
  "CLOUDINARY_UPLOAD_PRESET": "your-unsigned-upload-preset"
}
```

3. Run the app with Dart defines:

```bash
flutter run --dart-define-from-file=.env/cloudinary.json
```

If you use VS Code, `.vscode/launch.json` is already configured to pass this file automatically.
