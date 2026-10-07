# Topsheet

Generate clean, print-ready practical/assignment topsheets in seconds —
pick a department and subject, fill in student and teacher details, and
export a ready-to-share PDF. No accounts, no ads, no data collection.

## Features

- Fast, guided form for course, student, and teacher details
- Remembers previous entries for quicker repeat submissions
- Clean, print-ready PDF output
- Library view of everything you've generated, organized by month
- Open, edit, share, or delete any topsheet you've made
- Works fully offline — nothing you enter ever leaves your device

## Tech stack

- [Flutter](https://flutter.dev) / Dart
- [pdf](https://pub.dev/packages/pdf) + [printing](https://pub.dev/packages/printing) for PDF generation and sharing
- [sqflite](https://pub.dev/packages/sqflite) + `shared_preferences` for local storage
- CI/CD via GitHub Actions (signed release builds, GitHub Releases, and Play Store publishing)

## Building from source

```bash
flutter pub get
flutter run
```

To build a release APK or App Bundle:

```bash
flutter build apk --release
flutter build appbundle --release
```

## Privacy

Topsheet doesn't require an account, doesn't collect or sell your data, and
shows no ads. Read the full
[Privacy Policy](https://blog.thekami.tech/posts/topsheet-privacy-policy/).

## Contributing

Topsheet is free and open source under the MIT License. Issues and pull
requests are welcome.

## Community & Support

- 💬 [Discord](https://www.thekami.tech/discord/) — join the Thekami community
- 📸 [Instagram](https://www.instagram.com/thekami_official)
- 💼 [LinkedIn](https://www.linkedin.com/company/thekamiofficial)
- 📘 [Facebook](https://www.facebook.com/thekamidev/)
- 🐙 [GitHub](https://github.com/thekami-dev)
- ❤️ [Support this project](https://www.supportkori.com/thekami)

## License

MIT © [Thekami](https://www.thekami.tech)

---

<p align="center">
  Made by <a href="https://www.thekami.tech"><img src="https://www.thekami.tech/logo.png" alt="Thekami" height="20"></a>
</p>
