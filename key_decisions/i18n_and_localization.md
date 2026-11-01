# Key Decisions: Internationalization (i18n) Architecture

## Decision: Native .lproj Dictionaries with Dynamic Bundle Fallback
- **Status**: Accepted
- **Context**: The app must support 5 locales (en, zh-Hans, zh-Hant-TW, zh-Hant-HK, ja), default to the system locale, fall back to English if unsupported, and support runtime language switching without restarting the application.
- **Options Considered**:
  1. *Hardcoded switch-case in Swift*:
     - *Pros*: Simple for small projects.
     - *Cons*: Violates Apple i18n standards, difficult to maintain, lacks string catalog compatibility.
  2. *Standard Apple `.lproj/Localizable.strings` with dynamic custom bundle switching in `I18n.swift`*:
     - *Pros*: Follows macOS localization standards; easily extensible; supports dynamic bundle loading and instant reactive UI re-render without restarting.
- **Decision Outcome**: Adopted option 2. Handled regional nuances (e.g. Taiwan traditional vs. Hong Kong traditional terminology).
- **Consequences**: Standardized translation assets and smooth localized user experience.
