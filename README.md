# Tally

A small-business inventory tallying and stock-balancing app. Built to make counting stock faster than spreadsheets, comparing expected and counted stock intuitive, and stock variances auditable and clear.

## Primary Surfaces
- **Phone** (iOS & Android)
- **Tablet / iPad**
- **Progressive Web App (PWA)**

## Project Architecture & Documentation

- **Product Specification:** [`docs/product-spec.md`](docs/product-spec.md)
- **Architecture Overview:** [`docs/architecture.md`](docs/architecture.md)
- **Quality Gates:** [`docs/quality-gates.md`](docs/quality-gates.md)
- **Agent Operating Model:** [`docs/agent-operating-model.md`](docs/agent-operating-model.md)
- **Architecture Decisions:** [`docs/decisions/`](docs/decisions/)

## Agent Kit (`.agents/`)

This repository is configured with an agent customization kit for AI pair programming:
- **Rules (`.agents/rules/`):**
  - `tally-core.md`: Layer boundary enforcement, pure Dart domain, serverless trust boundaries.
  - `tally-ui.md`: Multi-surface adaptability, minimum touch targets ($\ge 48\times48$ dp), calm aesthetic, ad placement guardrails.
  - `tally-security.md`: Zero client secrets, server-side authorization, immutable stock movements.
  - `tally-testing.md`: Quality gate testing pyramid, static analysis, zero linter warnings.
- **Skills (`.agents/skills/`):**
  - `tally-feature`: Step-by-step vertical slice development workflow.
  - `tally-ui`: Multi-surface UI design and responsiveness audit.
  - `tally-domain`: Pure Dart domain modeling, value objects, and variance calculations.
  - `tally-serverless`: Backend adapters, security rules, and offline sync queues.
  - `tally-pwa`: Progressive Web App optimization and configuration.
  - `tally-quality-gate`: Comprehensive checklist to pass Gates 0 through 6.
- **Specialized Subagents (`.agents/agents/`):**
  - `tally-architect`: Architecture and dependency direction reviewer.
  - `tally-ui-critic`: Responsive layout and user experience evaluator.
  - `tally-security-reviewer`: Serverless trust boundary and credential auditor.

## Developer Workflow & CLI Scripts

You can run commands using the `Makefile` or directly via `./scripts/`:

| Action | Make Target | Shell Script |
|---|---|---|
| **Dev (Web / PWA)** | `make dev` | `./scripts/dev.sh` |
| **Dev (macOS)** | `make dev-macos` | `./scripts/dev.sh --macos` |
| **Dev (Android)** | `make dev-android` | `./scripts/dev.sh --android` |
| **Dev (iOS)** | `make dev-ios` | `./scripts/dev.sh --ios` |
| **Build Web (PWA)** | `make build-web` | `./scripts/build.sh web` |
| **Build Android APK** | `make build-apk` | `./scripts/build.sh apk` |
| **Build Android Bundle** | `make build-appbundle` | `./scripts/build.sh appbundle` |
| **Build iOS** | `make build-ios` | `./scripts/build.sh ios` |
| **Run Tests** | `make test` | `./scripts/test.sh` |
| **Test Coverage** | `make test-coverage` | `./scripts/test.sh --coverage` |
| **Quality Gate Audit** | `make gate` | `./scripts/gate.sh` |
| **Format Code** | `make format` | `dart format .` |
| **Static Analysis** | `make analyze` | `dart analyze` |
| **Clean Cache** | `make clean` | `./scripts/clean.sh` |

### Smart Dev Runner & Device Targeting

Running `make dev` (or `./scripts/dev.sh`) follows an automated startup cascade:
1. **Android Emulator**: Uses a connected Android device or boots the available Android AVD (e.g. `Pixel 9 Pro`).
2. **iOS Simulator**: If Android is unavailable, boots the available iOS Simulator.
3. **Google Chrome**: If no mobile emulators are available, falls back to Web on `http://localhost:3000`.

You can target specific devices/simulators by name:
```bash
# Target specific Android or iOS simulator by name (boots if shut down)
./scripts/dev.sh --device="Pixel 9 Pro"
./scripts/dev.sh --device="iPhone 17 Pro"
./scripts/dev.sh -d="iPad Pro 13-inch (M5)"

# Or via Makefile
make dev ARGS='--device="Pixel 9 Pro"'
make dev ARGS='--device="iPhone 17 Pro"'
```

## Quality Gate Checklist

Before committing any feature or increment, run:
```bash
make gate
```
or `./scripts/gate.sh`. This ensures:
1. `dart format --output=none --set-exit-if-changed .` passes cleanly.
2. `dart analyze` reports zero warnings and zero errors.
3. `flutter test` passes all tests.
4. No hardcoded plain-text API secrets or keys are exposed.
