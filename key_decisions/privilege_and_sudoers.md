# Key Decisions: Privilege Management & Sudoers Security

## Decision: Scoped Passwordless Sudo Rule with `visudo` Validation
- **Status**: Accepted
- **Context**: Running `/usr/bin/pmset -a disablesleep 1|0` requires root (`sudo`) privileges on macOS. If password authentication is required every time the user plugs in the charger, the user experience becomes disruptive.
- **Options Considered**:
  1. *Prompt for admin password / Touch ID on every toggle via `osascript`*:
     - *Pros*: No persistent sudoers modification.
     - *Cons*: Highly disruptive for automated power events (e.g. plugging in charger triggers an authorization dialog).
  2. *Broad NOPASSWD in sudoers for all commands*:
     - *Pros*: Easy.
     - *Cons*: Critical security vulnerability.
  3. *Granular scoped rule restricted only to `/usr/bin/pmset` with `visudo -cf` syntax verification*:
     - *Pros*: Grants minimal privilege strictly needed for sleep control; zero password prompts during automated power events; `visudo -cf` check guarantees syntax safety before moving file to `/etc/sudoers.d/mac_sleep_control`.
- **Decision Outcome**: Implemented option 3. Also added an in-app revocation button to remove `/etc/sudoers.d/mac_sleep_control` whenever desired.
- **Consequences**: Fast, silent switching when plugging/unplugging with clear security boundaries.
