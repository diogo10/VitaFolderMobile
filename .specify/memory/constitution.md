# VitaFolderMobile Constitution

## Core Principles

### I. Flutter Versioning
The project MUST use Flutter version 3.41.6 managed exclusively via Flutter Version Management (FVM).
**Rationale:** Ensures environment consistency across local and CI builds.

### II. State Management
All business logic and UI state MUST be handled using `flutter_bloc` Cubits.
**Rationale:** Provides a predictable, unidirectional data flow and testable logic.

### III. Backend Infrastructure
The application MUST use Supabase as the sole backend service provider.
**Rationale:** Standardizes database, authentication, and storage interfaces.

### IV. Dependency Injection
All services, repositories, and BLoCs MUST be registered and retrieved using `GetIt`.
**Rationale:** Decouples object creation from usage and facilitates easy mocking for tests.

### V. Routing
Navigation MUST be implemented using the `go_router` package.
**Rationale:** Provides declarative, deep-linkable routing consistent with modern Flutter standards.

### VI. Clean Architecture
The codebase MUST follow a Clean Architecture pattern, strictly separating the Domain, Data, and Presentation layers.
**Rationale:** Minimizes side effects and allows for independent evolution of the UI and data sources.

## Constraints

*   **Testing Coverage:** Every feature MUST include both unit tests (logic) and integration tests (user flows).
*   **Code Style:** All code MUST follow the official Dart linting rules (`flutter_lints`).
*   **Error Handling:** All external service calls MUST be wrapped in Try/Catch blocks within the Data layer, returning Either types or custom Exceptions to the Domain layer.
*   **Layer Isolation:** The Domain layer MUST NOT import packages or files from the Data or Presentation layers.

## Development Workflow

*   **FVM Usage:** All CLI commands MUST be prefixed with `fvm` (e.g., `fvm flutter run`).
*   **Dependency Registration:** Singletons and Factories MUST be initialized in a centralized `injection_container.dart` file.
*   **Logic Location:** UI components MUST remain logic-less; all state changes MUST be triggered via Cubit functions.
*   **Feature Modularization:** New features MUST be grouped by domain folder, containing their own specific layers (presentation, domain, data).

## Governance & Amendments

*   **Testing Enforcement:** Pull Requests MUST NOT be merged if they fail existing tests or decrease total code coverage.
*   **Constitutional Amendments:** Changes to core principles (e.g., Flutter version upgrades or library swaps) MUST be proposed via a 'RFC' (Request for Comments) Pull Request and require approval from at least two lead maintainers.
*   **Policy Review:** This document SHOULD be reviewed at the start of every major release cycle to ensure the technology stack remains optimal.

**Version**: 1.0.0 | **Ratified**: 2026-09-28 | **Last Amended**: 2026-09-28
