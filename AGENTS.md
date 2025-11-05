# Repository Guidelines

## Project Structure & Module Organization
The Flutter client lives in `lib/`, with feature folders such as `lib/admin/`, `lib/components/`, and `lib/screens/` for UI, `lib/services/` for integrations, and `lib/providers/` for state. Platform scaffolding is kept under `android/` and `ios/`, shared assets in `assets/`, documentation in `docs/`, and API schemas (`supabase_schema.sql`, `SCHEMA_GUIDE.md`) at the repository root for quick reference. Generated code and cleanup scripts (`gen.sh`, `melos.yaml`) sit alongside to support build_runner workflows.

## Build, Test & Development Commands
Run `melos run run` for a hot-reload Flutter session, and `melos run build-apk` to assemble a release APK. Use `melos run gen` after updating models or Supabase schemas to regenerate build_runner outputs. `melos run analyze` and `melos run format` enforce analyzer checks and Dart formatting, while `melos run clean` clears stale generated files.

## Coding Style & Naming Conventions
This project relies on `analysis_options.yaml` including `flutter_lints`; trust the analyzer and fix warnings before committing. Format Dart code with `dart format .` (enforced to two-space indentation) and favor `UpperCamelCase` for types, `lowerCamelCase` for members, and `snake_case` for asset filenames. Keep widget files grouped by feature (e.g., `lib/screens/product_list/`) and suffix providers with `Provider`.

## Testing Guidelines
Add widget and unit tests under `test/`, naming files `<feature>_test.dart` (e.g., `product_grid_test.dart`). Run the suite locally with `melos run test` before pushing, and extend coverage when introducing new UI flows or services. Snapshot tests should include golden references under `test/goldens/` and use descriptive names.

## Commit & Pull Request Guidelines
Follow Conventional Commits (`fix:`, `feature:`, `refactor:`) as seen in the existing Git history and keep subject lines under 72 characters. Group related changes per commit, mention ticket IDs or Supabase issue URLs when available, and include screenshots/GIFs for UI changes in pull requests. PR descriptions should state motivation, key implementation notes, and testing results; request reviews from at least one admin-area maintainer.

## Environment & Configuration
Copy `.env` from the secure vault and update Supabase keys before running the app; never commit secrets. When schema changes, update `supabase_schema.sql`, regenerate clients via `melos run gen`, and document migrations in `docs/`. Use `flutter pub get` whenever `pubspec.yaml` changes to refresh dependencies.
