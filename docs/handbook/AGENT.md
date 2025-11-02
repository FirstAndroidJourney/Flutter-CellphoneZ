# Repository Guidelines

## Project Structure & Module Organization
The Flutter app lives in `lib/`, split by feature: `screens/` for UI pages, `components/` for shared widgets, `services/` for API access, `repository/` for data orchestration, `models/` for DTOs, and `theme/` for global styling. Admin-focused flows sit under `lib/admin/`, while `main.dart` and `entry_point.dart` wire platform bootstrapping. Assets stay in `assets/`. Native shells remain in `android/` and `ios/`, tests belong in `test/`, and Supabase docs sit at the root (`SUPABASE_SETUP.md`, `supabase_schema.sql`).

## Build, Test & Development Commands
Use Melos scripts for repeatable workflows: `melos run prepare-check-lint` installs deps, formats, and lint-checks. Start local development with `melos run run` (wraps `flutter run`). Generate or refresh code with `melos run gen`; watch mode is `melos run watch`. Reset generated artifacts via `melos run clean`. Produce release builds using `melos run build-apk`. Keep CI parity by running `melos run analyze` and `melos run test` before every push.

## Coding Style & Naming Conventions
Adhere to the Flutter lints declared in `analysis_options.yaml`. Use 2-space indentation, prefer single-responsibility widgets, and mark const constructors where viable. File names stay snake_case (`category_list_tile.dart`), class names PascalCase, and private members start with `_`. Run `melos run format` (alias for `dart format .`) before committing to a`void manual formatting drift.

## Testing Guidelines
Place unit and widget tests in `test/`, mirroring the `lib/` structure (`test/screens/home_screen_test.dart`). Name files with the `*_test.dart` suffix. Execute the full suite with `melos run test` or target a file via `flutter test test/path/to_case_test.dart`. Add tests alongside new features to keep UI logic covered; document complex setups with inline comments or fixtures.

## Commit & Pull Request Guidelines
Follow Conventional Commits as seen in history (`feat:`, `fix:`, `chore:`). Write subjects in the imperative and limit them to 72 characters, optionally referencing issues (`feat: add category filter (#42)`). Pull requests should explain the WHY/WHAT, list verification steps, link related tasks, and include screenshots or screen recordings for UI updates.

## Configuration & Security Notes
Copy `.env` from the secure vault or environment manager, then follow `SUPABASE_SETUP.md` to bootstrap local services. Never commit secrets; rely on `flutter_dotenv` or platform-specific secret stores. Use `devtools_options.yaml` for profiling presets and purge debug logging before review.
