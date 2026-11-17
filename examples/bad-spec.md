# Example: an incomplete spec (made-up change)

OBJECTIVE: Add a --json flag to the tally command so scripts can read its counts without parsing text. With the flag, tally prints one line of JSON and nothing else. Without the flag, nothing changes.

FILES:
- tally.sh (modify)
- tests/test-json.sh (create)
- README.md (modify, one paragraph documenting the flag)
- Do not touch: tests/test-basic.sh

CONSTRAINTS:
- Plain POSIX sh and standard Unix tools only. No new dependencies.
- Do not edit, skip or loosen any existing test.
- Each new test must fail when the code it covers does nothing.
- Out of scope: other output formats, renaming flags, refactoring.
