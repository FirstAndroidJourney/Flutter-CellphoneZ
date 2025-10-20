#!/bin/bash

dart run melos bootstrap
# bootstrap mean install all dependencies for all packages in the monorepo
# same as running `flutter pub get` in each package

dart run melos run gen
dart run melos run watch
dart run melos run build-apk
