---
name: app_development_guide
description: >-
  Project development guide and standards for SleepControl. Enforces i18n localization standards,
  English-only development and documentation, automated recording of dev logs (dev_logs/) and key
  decisions (key_decisions/), automatic cleanup of scratch/temporary files upon task completion,
  and strict git commit approval workflows (never auto-commit).
---

# App Development Guide (`SleepControl`)

This skill defines the mandatory engineering practices, documentation rules, localization standards, file cleanup hygiene, and git workflows for the `SleepControl` project.

---

## 1. UI Multi-Language & i18n Standards
- All user-facing strings must adhere to Apple's standard `.lproj/Localizable.strings` internationalization (i18n) specifications.
- Hardcoded user-facing strings in UI components (SwiftUI views, menu bar items, dialogs, alerts) are strictly prohibited. Always use `L("key")` or `LF("key", args...)`.
- Every new user-facing key must be added across all supported locales:
  - `en.lproj/Localizable.strings` (English — primary fallback)
  - `zh-Hans.lproj/Localizable.strings` (Simplified Chinese)
  - `zh-Hant-TW.lproj/Localizable.strings` (Traditional Chinese - Taiwan)
  - `zh-Hant-HK.lproj/Localizable.strings` (Traditional Chinese - Hong Kong)
  - `ja.lproj/Localizable.strings` (Japanese)
- Fallback mechanism: If a user's system language is not supported or a key is missing, it must safely fall back to English (`en`).

---

## 2. English-Only Engineering Standards
- **Code Development**: Variable names, function names, class/struct definitions, and internal APIs must be in English.
- **Internal Documentation**: Architecture plans, implementation plans, and internal engineering design notes must be written in English.
- **Source Code Comments**: All comments in `.swift`, `.sh`, and configuration files must be written in English.
- **Git Commit Messages**: All commit subjects, bodies, and issue references must be written in English.
- *(Note: Communication with the user in chat follows the user's communication language preferences, but all repository artifacts, docs, code, and commits must remain strictly English).*

---

## 3. Automated Dev Logs (`dev_logs/`)
- Record every key development decision, architectural change, dependency update, or major feature addition in the project's `dev_logs/` directory.
- File naming convention: `dev_logs/YYYY-MM-DD_<topic>.md` (e.g., `dev_logs/2026-11-01_initial_architecture_and_i18n.md`).
- Content structure:
  1. **Timestamp & Author / Agent**
  2. **Context & Motivation**
  3. **Technical Decisions Made**
  4. **Files Created or Modified**
  5. **Verification & Testing Results**

---

## 4. Key Decisions Summary (`key_decisions/`)
- Maintain a structured, module-by-module summary of key technical decisions in the `key_decisions/` directory.
- Organize summaries by module or architectural domain:
  - `key_decisions/power_management_and_iokit.md`: Hardware-level power detection, zero-polling design.
  - `key_decisions/privilege_and_sudoers.md`: One-click passwordless execution, security boundaries, and `visudo` validation.
  - `key_decisions/ui_and_macos_aesthetic.md`: MenuBarExtra + standalone window dual-form design, frosted glass and Bento grid layout.
  - `key_decisions/i18n_and_localization.md`: BCP-47 fallback hierarchy and runtime hot-switching.
- Each entry must document:
  - **Decision Title & Status** (Accepted / Superseded)
  - **Alternatives Considered & Why Rejected**
  - **Consequences & Trade-offs**

---

## 5. Automatic Cleanup of Process & Temporary Files
- **Zero Temporary File Residue**: The agent must always clean up any scratch, intermediate, or process-generated temporary files upon completing coding or asset generation tasks.
- **Scope of Cleanup**:
  - Temporary conversion/test scripts (e.g. `/tmp/test_*.swift`, scratch converters).
  - Outdated, superseded, or intermediate assets in `Resources/` or `docs/assets/` (e.g. obsolete cuts, unreferenced resolution variants, temporary previews).
  - Build residue outside `.build/` that does not belong in version control.
- **Verification Rule**: Before finishing the turn or presenting status to the user, run `git status` or inspect directories to ensure no unneeded artifacts or process clutter remain.

---

## 6. Strict Git Commit Workflow (NEVER Auto-Commit)
- **Zero Auto-Commit Policy**: The agent must **NEVER** execute `git commit` automatically under any circumstance.
- **Two-Step Approval Protocol**:
  1. **Step 1 - Ask for Decision**: Upon completing a feature, bugfix, or refactor, present the summary of changes to the user and explicitly ask whether they wish to commit.
  2. **Step 2 - Propose Commit Message**: When the user requests a commit, formulate and recommend clear, semantic English commit message options (e.g., following Conventional Commits like `feat: ...`, `fix: ...`, `chore: ...`).
  3. **Step 3 - Execute After User Confirmation**: Only after the user explicitly accepts or refines the proposed commit message should the agent stage files and run `git commit`.
