#!/usr/bin/env bash
# Installs the Gradle init script that keeps Flutter's included Gradle build
# resolving Kotlin plugins from Maven Central (see the script itself for why).
#
# Flutter invokes the Gradle wrapper without an --init-script flag, so the
# supported seam is $GRADLE_USER_HOME/init.d. CI runs this before every Android
# build; run it locally when a build fails with
# "Could not find org.jetbrains.kotlin:kotlin-gradle-plugins-bom".
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GRADLE_HOME="${GRADLE_USER_HOME:-$HOME/.gradle}"
DEST="$GRADLE_HOME/init.d"
NAME="50-flutter-tools-repositories.init.gradle.kts"

mkdir -p "$DEST"
cp "$ROOT/tool/gradle/flutter-tools-repositories.init.gradle.kts" "$DEST/$NAME"
echo "Installed Gradle init script: $DEST/$NAME"
