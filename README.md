# Spec-Driven Todo App: Built with Codex

A production-ready Flutter todo application developed entirely using Codex (GitHub's AI coding assistant). This project demonstrates how to leverage AI for end-to-end software development using a spec-driven approach.

## 🎯 Project Overview

This isn't just a todo app – it's a case study in AI-assisted development. Built with Codex following a detailed specification, it includes:

- **Complete Flutter App**: Full CRUD operations (Create, Read, Update, Delete)
- **Persistent Storage**: Local data persistence with shared_preferences
- **Enterprise-Grade Testing**: Unit tests, widget tests, and integration tests
- **Automated Validation**: One-command script that runs all tests and generates reports
- **Visual Artifacts**: Automated screenshots and video capture during test execution

## ✨ Key Features

- ✅ Add, edit, delete, and complete todos
- ✅ Persist todos locally across app restarts
- ✅ Clean, responsive UI with Flutter Material Design
- ✅ Comprehensive test coverage (unit, widget, integration)
- ✅ Automated test reports with coverage metrics
- ✅ Screenshot and video capture of test execution

## 🚀 The Spec-Driven Approach

Everything started with a detailed specification created in collaboration with Codex:

1. **Meta Prompting Phase**: Ask Codex for a comprehensive spec
2. **Refinement**: Iterate on the spec until perfect
3. **Implementation**: Use the spec to guide code generation
4. **Testing**: Generate tests based on spec requirements
5. **Automation**: Build validation scripts from spec blueprints

The spec served as the single source of truth throughout development.

## 🏗️ Project Structure

```
lib/
  ├── main.dart              # App entry point
  ├── app.dart               # App configuration
  ├── models/
  │   └── todo_item.dart     # Todo data model
  ├── screens/
  │   └── todo_screen.dart   # Main UI screen
  ├── services/
  │   └── todo_storage_service.dart  # Data persistence
  └── widgets/
      └── todo_list_item.dart        # Todo list item widget

test/
  ├── unit/                  # Unit tests
  ├── widget_test.dart       # Widget tests
  
integration_test/            # Integration tests with screenshots

scripts/
  ├── run_tests.sh           # Master validation script
  └── tasks/                 # Individual test tasks
```

## 🧪 Running Tests

### All Tests (Recommended)
```bash
./scripts/run_tests.sh
```
This runs an 8-phase validation:
1. Prepare dependencies
2. Run unit tests
3. Run widget tests
4. Ensure Android emulator
5. Run integration tests
6. Generate coverage reports
7. Capture screenshots
8. Capture video

### Individual Tests
```bash
# Unit tests
flutter test test/unit

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/coverage_flow_test.dart
```

## 📊 Test Results & Reports

After running `./scripts/run_tests.sh`, find reports in:
- Coverage reports: `reports/master_validation/[timestamp]/coverage/`
- Screenshots: `reports/master_validation/[timestamp]/screenshots/`
- Video: `reports/master_validation/[timestamp]/video/`
- Summary: `reports/master_validation/[timestamp]/summary_report.md`

## 🛠️ Requirements

- Flutter 3.9.2+
- Dart SDK 3.9.2+
- Android SDK (for emulator testing)
- Gradle

## 📦 Dependencies

- `flutter`: Core framework
- `shared_preferences`: Local data persistence
- `flutter_test`: Testing framework
- `integration_test`: Integration testing

## 🎓 Learning Experience

This project demonstrates:

- **Spec-Driven Development**: Using specifications as the source of truth
- **AI-Assisted Coding**: Leveraging Codex for end-to-end development
- **Comprehensive Testing**: Unit, widget, and integration tests
- **Automation**: Bash scripts for test orchestration and reporting
- **Best Practices**: Clean architecture, proper separation of concerns

## 💡 What We Learned

✅ **Speed**: Days of work reduced to hours with AI assistance  
✅ **Consistency**: AI follows patterns flawlessly  
✅ **Quality**: Comprehensive testing catches issues early  
✅ **Scalability**: Easy to extend with new features  
✅ **Control**: Spec-driven approach keeps humans in charge  

## 📖 Read the Full Article

For a detailed breakdown of the spec-driven approach and AI-assisted development experience, check out the [LinkedIn post](#).

## 🚀 Getting Started

1. Clone the repository
2. Run `flutter pub get` to fetch dependencies
3. Start an Android emulator or connect a device
4. Run `./scripts/run_tests.sh` for full validation
5. Or run `flutter run` to launch the app

## 📝 License

This project is provided as an educational example.

---

**Built with ❤️ using Codex and a spec-driven approach.**
