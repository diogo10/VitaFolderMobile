# VitaFolderMobile

Home of the VitaFolder mobile application. A family management plaftform. 


## How to Contribute

### Prerequisites

- Install [FVM (Flutter Version Management)](https://fvm.app/documentation/getting-started/installation)
- Run `fvm install` to install the correct Flutter version

### Development Commands

```bash
# Install dependencies
fvm flutter pub get

# Analyze code
fvm flutter analyze

# Run tests
fvm flutter test

# Run tests with coverage
fvm flutter test --coverage

# Generate code (after changing models)
fvm dart run build_runner build --delete-conflicting-outputs

# Watch for changes and regenerate code
fvm dart run build_runner watch --delete-conflicting-outputs
```

### Code Style

- Follow the conventions in `AGENTS.md`
- Use `fvm flutter` instead of `flutter` commands
- Never fallback to default values when parsing fails — always return `null`
- Use generated `l10n` translations for displayed text

### Pull Request Process

1. Create a feature branch from `main`
2. Make your changes
3. Run `fvm flutter analyze` and `fvm flutter test` to ensure code quality
4. Submit a pull request with a clear description

## References

https://supabase.com/docs/guides/getting-started/quickstarts/flutter