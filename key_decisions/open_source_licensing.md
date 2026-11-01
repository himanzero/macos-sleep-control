# Key Decisions: Open Source Licensing

## Decision: Adoption of the MIT License
- **Status**: Accepted
- **Context**: Selecting an appropriate open-source license for `SleepControl` prior to publication on GitHub.
- **Options Considered**:
  1. *MIT License*:
     - *Pros*: Maximum community adoption, minimal restrictions, simple, widely recognized, and standard for macOS developer utilities.
     - *Cons*: Does not prevent proprietary re-distribution.
  2. *GPL v3*:
     - *Pros*: Strong copyleft protection against closed-source commercial forks.
     - *Cons*: Restrictive licensing terms that may reduce adoption or integration by other developers.
  3. *Apache 2.0*:
     - *Pros*: Permissive with explicit patent grant.
     - *Cons*: More verbose without significant added benefit for a lightweight standalone utility.
- **Decision Outcome**: Selected the **MIT License**. It aligns best with the goal of maximizing utility, community stars, and contributions while protecting the author with standard warranty and liability disclaimers.
