# Architectural Decision Records

Accepted decisions formalizing the conventions in `AGENTS.md` and
`.agents/references/`. New code and reviews must follow them; to change
one, open a PR that updates the ADR and the affected code together.

## Index

| ADR | Title | Status |
| --- | --- | --- |
| [0001](0001-routing-go-router.md) | Routing: go_router with centralized route table | Accepted |
| [0002](0002-dependency-injection-getit.md) | Dependency injection: GetIt with `instanceName` | Accepted |
| [0003](0003-error-handling-either-failure.md) | Error handling: `Either<Failure, T>` at repository boundary | Accepted |
| [0004](0004-data-modeling-entity-from-null.md) | Data modeling: `entity.from()` returns `null` on invalid input | Accepted |
| [0005](0005-localization-l10n-only.md) | Localization: l10n-only strings in UI | Accepted |
| [0006](0006-feature-packages-modularization.md) | Feature packages: explicit APIs, enforced layer boundaries | Accepted |

Related standards (not ADRs, same authority):

- `../playbook/mobile-playbook.md` — Cubit sealed-state pattern,
  Supabase/Cubit boundary, async + `unawaited` conventions.
- `../code-review-checklist.md` — actionable review checklist derived
  from these ADRs and the playbook.

## Process

1. Copy the highest-numbered ADR as a template; use the next number.
2. Sections: Status, Context, Decision, Consequences, References,
   Code-review checklist.
3. Status values: `Proposed` → `Accepted` (or `Superseded by ADR-00NN`).
4. Keep ADRs immutable once accepted: correct typos in place, but
   record any decision change as a new ADR that supersedes the old one.
