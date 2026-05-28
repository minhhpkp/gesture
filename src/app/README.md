# Gesture app

## How to run

1. Create an `env.json` file with fields as listed in [example.env.json](example.env.json)
2. Run:

```bash
flutter run --dart-define-from-file=env.json
```

To run web app:

```bash
flutter run -d chrome --web-port=8080 --dart-define-from-file=env.json
```