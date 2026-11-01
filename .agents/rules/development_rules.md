# Project Development Rules for SleepControl

These rules must be strictly followed for all development tasks in this repository.

1. **i18n Multi-Language Standards**:
   - All user-facing strings must use `.lproj/Localizable.strings` and `L("key")`/`LF("key", ...)`.
   - Never hardcode user-visible strings in code. Maintain 5 locales: `en`, `zh-Hans`, `zh-Hant-TW`, `zh-Hant-HK`, `ja`. Default fallback is `en`.

2. **English Language Standard for Code, Comments, Docs & Git**:
   - All code, internal design docs, code comments, and git commit messages must be in English.

3. **Development Logs (`dev_logs/`)**:
   - Document key development steps and architectural updates under `dev_logs/YYYY-MM-DD_<topic>.md`.

4. **Key Decisions Summary (`key_decisions/`)**:
   - Maintain module-by-module architectural decisions and rationale under `key_decisions/<module>.md`.

5. **Automatic Cleanup of Temporary & Process Files**:
   - Always delete intermediate, scratch, and temporary files upon completing coding or asset generation tasks. Keep `Resources/`, `docs/`, and project directories strictly clean.

6. **Strict Git Commit Workflow (NEVER Auto-Commit)**:
   - **Never run `git commit` automatically.**
   - When a development task finishes, ask the user if they want to commit.
   - When the user asks to commit, recommend a clear English commit comment first.
   - Only after the user confirms/accepts the commit comment, execute `git commit`.
