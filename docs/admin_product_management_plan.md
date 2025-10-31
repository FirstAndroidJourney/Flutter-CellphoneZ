# Admin Product Management (CRUD) Implementation Plan

## Quick Checklist
- Confirm product schema, storage buckets, and existing repository/service contracts.
- Extend backend (models, repository, service) to support admin-grade CRUD and image handling.
- Implement Supabase Storage upload flow and CDN URL persistence for product images.
- Build admin product management UI (list, filters, create/edit form, delete/toggle availability).
- Wire navigation/access control and ensure consistent dependency injection.
- Deliver automated/manual test coverage plus operational safeguards for launch.

## Execution Blueprint (Agent-Oriented)
1. **Phase 0 – Context Sync**
   - Read `docs/supabaseERD.md`, `SCHEMA_GUIDE.md`, and this document to load schema constants and storage expectations.
   - Verify `.env` contains Supabase URL + anon key; ensure `DatabaseClient.initialize` is called before repository usage.
2. **Phase 1 – Model & Repository Upgrades**
   - Modify `lib/models/product.dart`; regenerate Freezed outputs.
   - Update `lib/repository/product_repository.dart` with DTO-aware CRUD, pagination hooks, and toggle helper.
   - Extend `lib/services/product_service.dart` accordingly; wire new dependencies in `lib/services/dependency_injection.dart`.
3. **Phase 2 – Storage Layer**
   - Create `lib/services/storage_service.dart` encapsulating upload/delete/public URL logic for `product-images`.
   - Ensure bucket policies (currently public) align with upload strategy; document fallback handling.
4. **Phase 3 – Admin UI Implementation**
   - Introduce `lib/admin/views/product_management.dart` plus any supporting widgets/components.
   - Connect with routing (`lib/route/route_constants.dart`, `lib/route/router.dart`) and enforce admin-only access.
5. **Phase 4 – Quality Gates**
   - Implement unit/widget tests, run `flutter analyze`, `flutter test`.
   - Execute data-quality audit script for legacy `image_url` remediation and verify CDN links resolve.
6. **Phase 5 – Deployment Prep**
   - Compile manual test script, document image upload workflow, and capture outstanding risks for handover.

---

## 1. Schema & Data Model Alignment
- Map core fields from `products` (`id`, `name`, `price`, `description`, `image_url`, `category_id`, `is_available`) and enforce non-null defaults for `price` (double) and `is_available` (bool) during inserts/updates.
- Honor `products.category_id → categories.id` FK: pre-load categories for admin dropdowns and validate selection before write operations.
- Plan to add dedicated DTOs (e.g., `ProductCreateRequest`, `ProductUpdateRequest`) mirroring schema; ensure `id` is excluded on create to let Supabase assign UUID.
- Ensure `DatabaseSchema.products` constants back every query/filter to maintain consistency per project conventions.
- Capture optional description and image fields; treat empty strings and null consistently to avoid Supabase default `''` collisions.
- Note dependency on `StorageBuckets.productImages`; confirm bucket existence in Supabase console or add provisioning task.

**Agent Actions:**
- Confirm `DatabaseSchema.products` constants reference every column touched; update if new fields required.
- Draft validation helpers (e.g., `ProductInputValidator`) to coerce empty strings to `null` before repository writes.
- Record assumptions about `is_available` defaults in comments/tests to guard against regressions.

**Validation:** Fields and relationships match `docs/supabaseERD.md` (`products` table) and `lib/services/database_schema.dart`. Identified discrepancy: existing `ProductService.createProduct` builds a `Product` with an empty `id`, conflicting with auto-generated UUIDs. Recommended fix is the planned request DTOs plus repository insert that omits `id`.

---

## 2. Backend Enhancements
### 2.1 Models & Serialization
- Add `ProductCreateRequest` and `ProductUpdateRequest` Freezed classes (`lib/models/product.dart`) with `toJson` utilities that strip read-only fields (`id`, derived relations).
- Update the generated code via `build_runner` after model changes; document command (`flutter pub run build_runner build --delete-conflicting-outputs`).

### 2.2 Repository Layer (`lib/repository/product_repository.dart`)
- Introduce CRUD methods using new DTOs: `createProduct(ProductCreateRequest request)` and `updateProduct(String id, ProductUpdateRequest request)` returning strongly typed `Product`.
- Adjust existing read operations to support admin needs: pagination hooks (e.g., `.range`), optional category join (`select('*, ${tables.categories}(${categoriesSchema.name})')`) for display, and search filters with `.ilike` on `name`/`description` via schema constants.
- Ensure delete gracefully handles Supabase errors (e.g., dependent foreign keys) and provides meaningful exceptions for UI.
- Add helper to toggle `is_available` flag; reuse `update` internally.

### 2.3 Service Layer (`lib/services/product_service.dart`)
- Refactor to consume new DTOs and expose admin-friendly methods (`createProduct`, `updateProduct`, `deleteProduct`, `toggleAvailability`, `uploadImageAndPersist`).
- Inject `CategoryRepository` or `CategoryService` to reuse category cache for forms; centralize validation (e.g., confirm category exists before insert).
- Surface domain-specific errors and wrap Supabase exceptions for UI messaging.

### 2.4 Dependency Injection & Logging
- Register any new services (e.g., `StorageService`, `ProductAdminFacade`) in `lib/services/dependency_injection.dart`; ensure eager initialization respects `.env` semantics.
- Leverage `AppLogger` for structured logs around CRUD operations, aligning with existing category admin logging style.

**Agent Actions:**
- Implement DTOs and Freezed updates, then run `flutter pub run build_runner build --delete-conflicting-outputs`.
- Replace existing service/repository method signatures to consume DTOs while preserving current consumer APIs (or update call sites).
- Add unit tests validating repository responses and error wrapping using mock Supabase clients.
- Update dependency registration and verify GetIt resolves new services during app bootstrap.

**Validation:** Query plans and schema usage align with `SCHEMA_GUIDE.md` guidance (no hardcoded strings, use `DatabaseSchema`). Repository/service changes respect FK constraints and data defaults from `docs/supabaseERD.md`. Discrepancy flagged in Section 1 addressed here by replacing direct `Product` inserts.

---

## 3. Supabase Storage Workflow
- Create `StorageService` (e.g., `lib/services/storage_service.dart`) wrapping `Supabase.instance.client.storage` for upload/delete/getPublicUrl using `StorageBuckets().productImages`.
- Implement upload pipeline: pick image (local path/bytes), call `upload(path, File/bytes, FileOptions(upsert: true))`, then persist returned public URL in `products.image_url` through repository update.
- Define deterministic object naming (e.g., `admin/{productId or timestamp}_${sanitizedName}.jpg`) to avoid collisions and enable future clean-up.
- Handle progress feedback and error states; surface storage exceptions (quota, MIME type) to UI for corrective action.
- Plan deletion/replace flow: when changing images, optionally remove previous object if no longer referenced to limit storage bloat.
- Document environment prerequisites: Supabase bucket must allow authenticated admin role to upload; confirm or request policy update.

**Agent Actions:**
- Build `StorageService` with methods `uploadProductImage`, `removeProductImage`, `getPublicUrl`; accept both file paths and bytes to support mobile pickers.
- Define naming helper (e.g., `StoragePathBuilder.productImage(Product product, String extension)`).
- Integrate upload pathway into `ProductService` so CRUD operations can call storage first, then persist returned URL.
- Write unit tests using mocked storage client to assert correct bucket/path usage.

**Validation:** Process mirrors `docs/supabaseStorageFlutterDocs.md` patterns (upload → getPublicUrl), and bucket name follows `StorageBuckets.productImages` in `lib/services/database_schema.dart`. No schema conflicts detected; bucket existence pending confirmation (recommend verifying in Supabase dashboard).

---

## 4. Admin UI/UX Implementation
### 4.1 Screen Structure (`lib/admin/views/product_management.dart`)
- Build a `StatefulWidget` (consistent with `CategoryManagement`) that loads products via `ProductService`, displays list with search, category filter, availability chips, and action buttons (edit/delete/toggle).
- Integrate pull-to-refresh and loading/error empty states mirroring existing admin UI patterns.

### 4.2 List Presentation
- Use `ListView` or `DataTable`-style widget with columns: Thumbnail, Name, Category, Price, Availability, Actions.
- Fetch category labels (preloaded map) for readability; fall back to ID if missing.
- Support sorting by name/price and filtering by availability; store state locally.

### 4.3 Product Form Dialog
- Implement modal form widget (`components/admin/product_form_dialog.dart`) reused for create/edit.
- Fields: `TextFormField` for name (required), price (numeric validator, min >0), multiline description (optional), `DropdownButtonFormField` for category, switch for `is_available`, image picker preview with upload trigger.
- Validate before submission; disable submit while upload or backend request is in-flight.

### 4.4 Image Handling UX
- Provide buttons for "Upload Image" (from gallery/file picker) and "Remove Image".
- Show upload progress indicator; once complete, set `imageUrl` in local form state before calling repository.
- Ensure CDN URL persisted via service; allow editing to keep existing image unless replaced.

### 4.5 Destructive Actions & Feedback
- Confirm dialogs for delete and availability toggles; include mention of cascading impact (e.g., removing product from storefront).
- Use `ScaffoldMessenger` snackbars for success/failure feedback, aligning with category admin flow.

**Agent Actions:**
- Scaffold `ProductManagementScreen` with state management (setState or riverpod/bloc if introduced later) to load data via `ProductService`.
- Create `ProductFormDialog` widget housing form controllers, validation, and image picker integration using gallery-only dependency.
- Connect action buttons (edit/delete/toggle) to service methods with loading indicators and snackbar feedback.
- Implement caching map for category names to minimize redundant calls; refresh on demand.
- Provide placeholder widget for products lacking `image_url` as per Section 8.

**Validation:** UI captures all columns from `products` table and writes URLs produced by Supabase Storage per docs. Categorization leverages `DatabaseSchema` constants, maintaining compliance with `SCHEMA_GUIDE.md`. No new discrepancies; ensure image upload button enforces CDN workflow noted in the special instructions.

---

## 5. Navigation & Access Control
- Add route constant (e.g., `productManagementScreenRoute`) in `lib/route/route_constants.dart` and wiring in `lib/route/router.dart`.
- Surface entry point (e.g., admin dashboard menu or hidden route) guarded by admin permissions; reuse existing auth state to ensure only authorized users reach screen.
- If admin role data stored in Supabase user profiles, add check before pushing route; otherwise, plan follow-up to implement role-based gating.
- Document how to reach screen during manual testing (e.g., deep link or debug menu).

**Agent Actions:**
- Add `productManagementScreenRoute` constant and register route in `router.dart`.
- Create navigation trigger (e.g., button in existing admin hub). Gate by checking admin flag/role when available.
- Document manual navigation instructions in project README admin section for QA references.

**Validation:** Routing additions respect existing router structure and do not conflict with schema definitions. Access control relies on app-level logic; database RLS remains untouched but should be reviewed separately if admin role constraints are configured (recommend confirm in Supabase console).

---

## 6. Testing & Quality Assurance
- **Unit Tests:** Mock Supabase client to validate repository methods (insert/update/delete), including image URL persistence and error handling. Cover DTO serialization edge cases (e.g., price parsing).
- **Widget Tests:** Verify form validation logic, state transitions on success/failure, and that toggling availability updates the UI list.
- **Integration/Manual Tests:** Run through create/edit/delete flows against staging Supabase project, ensuring `products` table updates correctly and CDN URL resolves.
- **Regression Checks:** Confirm storefront screens consuming products remain stable (e.g., list endpoints still filter `is_available` correctly).
- **Observability:** Add logging (AppLogger) around storage uploads and CRUD responses; plan to monitor Supabase dashboard for errors post-release.

**Agent Actions:**
- Add unit tests under `test/repository/` and `test/services/` covering success/failure paths.
- Implement widget tests for form validation states (`test/widgets/product_form_dialog_test.dart`).
- Script manual QA checklist referencing staging credentials and Supabase console data verification.
- Configure logger tags for CRUD/storage actions to aid monitoring post-deploy.

**Validation:** Test focus aligns with schema constraints (`price` as double, `is_available` non-null) and storage workflow from provided docs. No conflicts noted; recommend creating a staging bucket to avoid polluting production data during QA.

---

## 7. Task Breakdown & Sequencing
- **Backend Foundation**
  - Update `lib/models/product.dart` with new DTOs; regenerate Freezed files.
  - Refactor `lib/repository/product_repository.dart` CRUD to consume DTOs and expose admin helpers.
  - Extend `lib/services/product_service.dart` with admin orchestration and validation.
  - Introduce `lib/services/storage_service.dart`; register in DI.
- **UI & Routing**
  - Create `lib/admin/views/product_management.dart` following checklist in Section 4.
  - Add reusable form dialog widget under `lib/components/admin/` (or sibling folder) for create/edit.
  - Wire new route constants and entry points; optionally update admin navigation menu or debug entry.
- **Supporting Infrastructure**
  - Ensure image picker dependency (e.g., `image_picker` or `file_picker`) added to `pubspec.yaml`; handle platform configuration.
  - Document Supabase bucket verification step and any required policy updates.
  - Add tests (unit/widget) under `test/` mirroring scenarios defined in Section 6.
- **QA & Handover**
  - Run lint/build (`flutter analyze`, `flutter test`) to validate changes.
  - Prepare staging checklist: create sample products, verify CDN URLs, inspect category linkage.

**Agent Actions:**
- Track each bullet above as discrete tasks in project management tool (e.g., Jira/Trello) with acceptance criteria referencing this doc.
- Use checklists to ensure dependencies (e.g., Freezed codegen) are not skipped.
- Capture blockers/decisions in commit messages or docs for future agents.

**Validation:** Task list mirrors schema usage directives (`SCHEMA_GUIDE.md`) and storage requirements. Pending confirmation: Supabase policies for product writes by admin accounts—if absent, schedule follow-up to adjust RLS to allow authenticated admin role to perform CRUD.

---

## 8. Data Quality Follow-Up
- Implement a one-off audit script (Supabase SQL or Dart utility) to identify products with blank/invalid `image_url` values and export a remediation list.
- Provide a migration path: bulk upload sanitized images to `product-images` storage, then batch update each product record with the new CDN URL.
- Add UI fallback logic (placeholder image + warning badge) so products with unfetchable URLs remain manageable until corrected.

**Agent Actions:**
- Write SQL or Dart script (e.g., `tool/audit_product_images.dart`) to flag entries where `image_url` is empty or returns non-200 responses.
- Store remediation checklist in `docs/data_quality/product_images_audit.md` with timestamps and responsible owner.
- Update admin UI to surface fallback indicator and optional inline action to retry upload.

**Validation:** These actions align with `docs/supabaseERD.md` by keeping `image_url` populated with valid CDN links and prevent schema changes; storage usage matches the documented bucket strategy.
