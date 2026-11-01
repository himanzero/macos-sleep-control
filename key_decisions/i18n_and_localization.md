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

---

## Decision: Dynamic Semantic Activity Log Representation
- **Status**: Accepted
- **Context**: Activity log items previously rendered in the Recent Activity & Automation Log card stored pre-rendered localized strings at the time of insertion, which permanently baked the active language (typically Chinese) into the log history. Switching languages left older entries untranslated.
- **Options Considered**:
  1. *Re-create log strings using regex or substring replacements*:
     - *Pros*: Doesn't modify data structure.
     - *Cons*: Extremely fragile, error-prone across 5 languages, breaks when parameter formatting varies.
  2. *Parameterized `ActivityLogItem` with dynamic resolver (`ActivityLogParameter`)*:
     - *Pros*: Preserves the raw event semantics, parameters (power snapshots, sleep states, error descriptions), and timestamps. Dynamic computed getters `title` and `detail` automatically evaluate using the active interface language upon SwiftUI re-render without app restart or data loss.
- **Decision Outcome**: Adopted option 2. Maintained backward-compatible initializers while supporting rich parameter resolution and 30-day / 30-item capacity pruning.
- **Consequences**: Activity logs seamlessly adapt across all 5 supported locales upon hot language switching.

