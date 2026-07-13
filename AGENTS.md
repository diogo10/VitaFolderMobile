This repository uses `.windsurfrules` as a source of truth for engineering style. When working in this repo, Codex must follow the rules below in addition to its built-in system instructions.

## Source Of Truth

- Read and follow `D:\code\flutter-template\.windsurfrules`.
- If this file and `.windsurfrules` overlap, treat them as consistent restatements of the same policy.
- If a rule here is less detailed than `.windsurfrules`, prefer the more specific requirement from `.windsurfrules`.

## Required Change Workflow

- Use CodeGraph to analyze relevant call chains before code changes.
- Do not use whole-repository grep for initial code discovery when CodeGraph can answer the question.
- Analyze and state the likely impact scope before modifying code.
- Run tests after completing code or documentation changes.
- Every modification, edit, addition, or deletion must include a corresponding `README.md` update.
- Do not use flutter run build  command

## Required Working Style

- Use Vue/TypeScript-like layering when writing Flutter/Dart code: clear module boundaries, explicit types, centralized singletons, thin API wrappers, immutable state, semantic naming.
- Keep initialization, side effects, business logic, and UI composition separated.
- Prefer strong typed model classes over long-lived `dynamic` or raw `Map<String, dynamic>` in business code.
- Do not keep placeholder or demo naming such as `path1`, `testPage`, `data1`.

## Network Layer

- Do not create `Dio()` or `DioClient()` inside pages, widgets, or business API files.
- Reuse the centralized request infrastructure from `lib/utils/request.dart`.
- API files should declare business requests only. Interceptors, token injection, refresh token logic, cookie handling, and request logging belong in the shared client layer.
- If a new backend domain is needed, add its shared client in the request infrastructure layer instead of instantiating ad hoc clients inside feature files.

## API Layer

- Put new API code under `lib/api/**`.
- API methods must have explicit return types.
- API methods should map responses into model classes before returning.
- Do not pass raw `response.data` through to the UI layer for feature code.

## Models And Types

- Put new business models under `lib/model/**`.
- Business entities should use typed classes with semantic field names.
- `fromJson` and `toJson` belong on the model type.
- Do not use TypeScript-style `IUserInfo` naming in Dart.

## State Management

- Store state should be immutable and strongly typed.
- Prefer `copyWith`-style updates for state transitions.
- Reducers and actions should stay explicitly typed.

## Widget And Page Boundaries

- Widgets should primarily handle UI composition.
- App startup initialization belongs in `main.dart` or `bootstrap.dart`.
- Pages belong in `lib/pages/**`.
- Reusable UI belongs in `lib/components/**`.
- Do not perform request client, router, or store initialization inside page widgets.

## UI Framework And Visual Style (Required)

- Business UI must use Cupertino widgets by default (`Cupertino*`).
- Do not use Material-style widgets in feature pages/components, including `Scaffold`, `AppBar`, `Material`, `Card`, `ElevatedButton`, `TextButton`, `FloatingActionButton`, `SnackBar`, `TabBar`, `PopupMenuButton`, and `BottomNavigationBar`.
- Do not rely on `package:flutter/material.dart` for business UI; prefer `cupertino.dart`, and only keep minimal base Flutter imports when needed.
- Interaction feedback, dialogs, navigation transitions, and top/bottom bars should follow iOS conventions first.
- New or refactored UI should visually align closer to iOS, not Android Material.

## UI Style Exception

- If Cupertino has no equivalent capability, Material usage is allowed only in a minimal, isolated way, and must not expose obvious Material visual style.

## UI Data Rules

- In `lib/pages/**`, do not use `json['xx']` or `response.data['xx']` for direct rendering.
- Page widgets should consume typed models or page-specific view models only.
- Keep `build()` pure: no network requests, no dispatch side effects, no storage reads or writes in `build()`.

## Side Effects

- Allowed places for side effects: `initState`, `didChangeDependencies`, user interaction callbacks, or dedicated controller/service abstractions already used by the repo.
- Do not trigger business side effects during render.

## Singletons And Dependency Creation

- Only create router and store singletons in `main.dart` or `bootstrap.dart`.
- Only create request clients and similar infrastructure singletons in infrastructure files such as `lib/utils/request.dart`.
- Feature pages and components must not instantiate `FluroRouter`, `Store`, `Dio`, or `DioClient` directly.

## Import Boundaries

- `lib/model/**` must not import `lib/api/**`, `lib/pages/**`, or `lib/store/**`.
- `lib/api/**` must not import `lib/pages/**`.
- `lib/components/**` must not import concrete business pages.
- Avoid page-to-page mesh dependencies.

## Naming And Config

- Classes use `UpperCamelCase`.
- Variables, fields, and methods use `lowerCamelCase`.
- Route names, API method names, and model names must reflect business meaning.
- Config classes should use Dart naming such as `AppConfig`.
- Prefer `--dart-define` for environment configuration.

## Error Handling

- Do not use `print` for business logging.
- Preserve useful error context in catches.
- Shared network error handling should live in the request infrastructure.
- UI handles only user-visible feedback and local recovery actions.

## Directory Conventions

- `lib/utils/`: infrastructure helpers.
- `lib/api/`: API declaration layer.
- `lib/model/`: typed business models.
- `lib/store/`: global state.
- `lib/pages/`: route entry pages.
- `lib/components/`: reusable UI components.
- `lib/router/`: routing.
- `lib/constants/`: constants and enum-like keys.

## Cross Platform Checks

- For each new feature involving networking, media, files, cache, permissions, WebView, or plugins, check whether Android, iOS, Web, and Windows need extra configuration.
- Do not assume single-platform validation is enough.
- Network-related changes must consider Android internet and cleartext rules, iOS ATS, Web CORS and mixed content, and Windows proxy or certificate behavior.
- Media-related changes must verify platform support matrix, HTTPS and Range requirements, format support, and actionable failure logging.
- If a plugin does not support all target platforms, provide a fallback or block feature entry on unsupported platforms.

## Change Process

- When adding a new API: add API code first, then model, then page consumption.
- When adding a new response shape: define the model before wiring UI.
- If repeated client creation, repeated base URLs, or repeated token handling are found, refactor toward the shared infrastructure layer.
- If Dart best practice differs from a Vue/TypeScript analogy, choose the Dart-idiomatic implementation but explain it using Vue/TypeScript framing when useful.

## Visual Supplement

- New or refactored UI should default toward an iOS 26-style visual language when appropriate: soft layering, subtle translucency, light borders, restrained shadows, and clear hierarchy instead of heavy card-based Material styling.
- For cards, overlays, search bars, sheets, headers, bottom bars, and floating surfaces, prefer iOS-like frosted or glass-morphism treatment when it improves hierarchy and readability.
- Glass-like effects must preserve readability first. Do not rely on blur alone; pair translucency with contrast, light borders, and stable content hierarchy.
- Do not overuse glass effects. Keep them focused on surfaces, navigation chrome, overlays, and emphasis containers rather than every content block.

## Desktop Interaction Supplement

- Any new swipe, drag, carousel, pager, horizontal list, or gesture-heavy component must explicitly consider Windows and Web mouse and trackpad behavior, not just mobile touch behavior.
- Any new overlay, popover, sheet, or dialog should consider desktop dismissal and focus behavior where reasonable, including outside click and keyboard flow.
- Any new input, filter, or search component should consider keyboard navigation basics such as focus movement, Enter confirmation, and practical pointer hit targets.
- Do not assume touch-only interaction for reusable UI that can appear on Windows or Web.

## Reusable Component Supplement

- `lib/components/**` should stay business-agnostic. Reusable components must not depend on concrete pages, concrete API shapes, or concrete Redux store fields.
- Reusable components should solve presentation and interaction only; they should not embed route jumps, network requests, analytics, login checks, or business branching.
- If a component's public API starts carrying business-specific nouns such as `user`, `order`, `product`, or `coupon`, reassess whether it still belongs in `lib/components/**`.

## Component Demo Supplement

- New reusable components must ship with a demo page under `lib/pages/component_demo/**`, a router entry, and a home entry.
- Demo pages must cover at least base usage, one common variant, and one state or edge-case scenario that reflects the component's real behavior.
- If mobile and desktop interaction differs, the demo must make that difference testable rather than only showing a static visual sample.