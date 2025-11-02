# Supabase Storage — Flutter/Dart SDK (Comprehensive Guide)

> This document covers **Supabase Storage** using the **Dart/Flutter SDK** (`supabase_flutter`), preserving the same structure as the Supabase sidebar (Create a bucket → Retrieve public URL). It also includes setup instructions.

---

## 0) Setup (Install & Initialize)

### Install
```bash
flutter pub add supabase_flutter
```

### Initialize
```dart
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
    // Optional: customize storage client retry behavior
    // storageOptions: const StorageClientOptions(retryAttempts: 5),
  );
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;
```

---

## STORAGE

### Create a bucket
Create a new storage bucket.
```dart
final String bucketId = await supabase.storage.createBucket(
  'avatars',
  bucketOptions: const BucketOptions(
    public: false, // set true for public files
    fileSizeLimit: null, // bytes, optional
    allowedMimeTypes: null, // e.g. ['image/png', 'image/jpeg']
  ),
);
```

**Notes**
- `id` must be unique.
- Use `public: true` only for assets meant to be accessed by anyone.
- You need appropriate service role / admin permissions to create buckets.

**Docs**: https://supabase.com/docs/reference/dart/storage-createbucket

---

### Retrieve a bucket
Get bucket metadata by ID.
```dart
final Bucket bucket = await supabase.storage.getBucket('avatars');
print(bucket.id); // 'avatars'
print(bucket.public); // bool
```
**Docs**: https://supabase.com/docs/reference/dart/storage-getbucket

---

### List all buckets
```dart
final List<Bucket> buckets = await supabase.storage.listBuckets();
for (final b in buckets) {
  print('${b.id} (public=${b.public})');
}
```
**Docs**: https://supabase.com/docs/reference/dart/storage-listbuckets

---

### Update a bucket
Update bucket configuration (e.g., make it public).
```dart
await supabase.storage.updateBucket(
  'avatars',
  bucketOptions: const BucketOptions(public: true),
);
```
**Docs**: https://supabase.com/docs/reference/dart/storage-updatebucket

---

### Delete a bucket
Delete the bucket **(irreversible)** — must be empty first.
```dart
await supabase.storage.deleteBucket('old-bucket');
```
**Docs**: https://supabase.com/docs/reference/dart/storage-deletebucket

---

### Empty a bucket
Delete **all objects** inside a bucket.
```dart
await supabase.storage.emptyBucket('temp-assets');
```
**Docs**: https://supabase.com/docs/reference/dart/storage-emptybucket

---

### Upload a file
Upload a file/object into a bucket.
```dart
import 'dart:io';

final file = File('/path/to/avatar.png'); // or bytes (Uint8List)
final String path = await supabase.storage
    .from('avatars')
    .upload(
      'public/user_123/avatar.png',
      file,
      fileOptions: const FileOptions(
        cacheControl: '3600',
        upsert: false,           // set true to overwrite existing
        contentType: 'image/png' // optional
      ),
    );
print('Uploaded path: $path');
```
**Docs**: https://supabase.com/docs/reference/dart/storage-from-upload

---

### Download a file
Download object bytes from a bucket.
```dart
import 'dart:typed_data';

final Uint8List data = await supabase.storage
    .from('avatars')
    .download('public/user_123/avatar.png');

// e.g., display as Image.memory(data) in Flutter
```
**Docs**: https://supabase.com/docs/reference/dart/storage-from-download

---

### List all files in a bucket
List objects in a folder/path.
```dart
final objects = await supabase.storage
    .from('avatars')
    .list(
      path: 'public/user_123', // optional; default is root
      searchOptions: const SearchOptions(
        limit: 100,
        offset: 0,
        sortBy: const SortBy(column: 'name', order: 'asc'),
      ),
    );

for (final o in objects) {
  print('${o.name}  (${o.metadata?.size ?? 0} bytes)');
}
```
**Docs**: https://supabase.com/docs/reference/dart/storage-from-list

---

### Replace an existing file
Upload and overwrite an existing object.
```dart
final file = File('/path/to/new_avatar.png');
await supabase.storage
    .from('avatars')
    .upload(
      'public/user_123/avatar.png',
      file,
      fileOptions: const FileOptions(upsert: true), // overwrite
    );
```
> Alternatively, some SDKs expose a `update`/`replace` helper; in Dart, use `upload` with `upsert: true`.

**Docs**: https://supabase.com/docs/reference/dart/storage-from-upload

---

### Move an existing file
Rename or move an object (old path → new path).
```dart
await supabase.storage
    .from('avatars')
    .move('public/user_123/avatar.png', 'public/user_123/profile/avatar.png');
```
**Docs**: https://supabase.com/docs/reference/dart/storage-from-move

---

### Delete files in a bucket
Remove one or many objects.
```dart
await supabase.storage
    .from('avatars')
    .remove([
      'public/user_123/profile/avatar.png',
      'public/user_123/old_banner.jpg',
    ]);
```
**Docs**: https://supabase.com/docs/reference/dart/storage-from-remove

---

### Create a signed URL
Generate a time‑limited URL for a private file.
```dart
final String signedUrl = await supabase.storage
    .from('avatars')
    .createSignedUrl('private/user_123/report.pdf', 60 /* expires in seconds */);

print(signedUrl);
```
**Docs**: https://supabase.com/docs/reference/dart/storage-from-createsignedurl

> For multiple signed URLs at once, see `createSignedUrls` (batch).

---

### Retrieve public URL
Get a **public** URL (bucket must be public).
```dart
final String url = supabase.storage
    .from('public-assets')
    .getPublicUrl('images/logo.png');

print(url);
```
**Docs**: https://supabase.com/docs/reference/dart/storage-from-getpublicurl

---

## Extras (Nice to have)

### Image transformations (serve resized/cropped images)
```dart
final bytes = await supabase.storage
    .from('public-assets')
    .download(
      'images/cover.jpg',
      transform: const TransformOptions(width: 800, height: 400, resize: ResizeMode.cover),
    );
```
Or transform on a public URL:
```dart
final transformedUrl = supabase.storage
    .from('public-assets')
    .getPublicUrl(
      'images/cover.jpg',
      transform: const TransformOptions(width: 300, height: 300, resize: ResizeMode.contain),
    );
```
**Docs**: https://supabase.com/docs/guides/storage/serving/image-transformations

### Tips & Best Practices
- Prefer **private buckets** + **RLS policies** for sensitive user content.
- For public assets (logos, marketing images), use a **public bucket** + `getPublicUrl`.
- Set `cacheControl` for static assets to improve performance.
- Use `upsert: false` to avoid accidental overwrites unless you really intend to replace files.
- Handle mobile permissions for camera/gallery access and consider compressing large media before upload.
- Consider retries and progress UI for large uploads.

---

*End of document.*
