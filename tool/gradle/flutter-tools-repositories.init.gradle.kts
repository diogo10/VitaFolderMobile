// Makes Flutter's included Gradle build resolve its Kotlin plugins from Maven
// Central instead of relying on the Gradle Plugin Portal's redirects.
//
// Why this exists:
//   `android/settings.gradle.kts` includes the Flutter SDK's Gradle plugin via
//   `pluginManagement { includeBuild("<flutter>/packages/flutter_tools/gradle") }`.
//   That included build only declares `dependencyResolutionManagement`
//   repositories; it has no `pluginManagement` block, so its plugin requests
//   (the embedded Kotlin DSL plugin and `kotlin("jvm") 2.2.20`) default to the
//   Gradle Plugin Portal alone.
//
//   The portal serves the Kotlin plugin POMs itself but redirects their
//   dependencies (`kotlin-gradle-plugins-bom`, `kotlin-stdlib`, ...) to Maven
//   Central. When that redirect is slow or answers 404 the build fails with:
//
//     Could not find org.jetbrains.kotlin:kotlin-gradle-plugins-bom:2.2.20
//       Searched in: https://plugins.gradle.org/m2/...
//
//   An init script is the only seam available: Flutter invokes the Gradle
//   wrapper directly, so there is no `--init-script` flag to pass, but Gradle
//   applies every script in `$GRADLE_USER_HOME/init.d` to each build in the
//   composite, including the included Flutter tools build.
//
// Install it with `bash tool/install_gradle_init_script.sh` (CI does this in
// every job that builds an Android artifact).
beforeSettings {
    val includedFlutterGradle = rootDir.invariantSeparatorsPath
        .endsWith("packages/flutter_tools/gradle")
    if (includedFlutterGradle) {
        pluginManagement.repositories {
            // Put Maven Central first so the Kotlin plugin marker and its
            // dependencies resolve from the same repository. Keep the plugin
            // portal as a fallback: the embedded `org.gradle.kotlin.kotlin-dsl`
            // plugin is only published there.
            clear()
            google()
            mavenCentral()
            gradlePluginPortal()
        }
    }
}
