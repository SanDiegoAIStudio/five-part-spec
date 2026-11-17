# Example: a complete spec (made-up change)

OBJECTIVE: Add a --json flag to the tally command so scripts can read its counts without parsing text. With the flag, tally prints one line of JSON and nothing else. Without the flag, nothing changes.

FILES:
- tally.sh (modify)
- tests/test-json.sh (create)
- README.md (modify, one paragraph documenting the flag)
- Do not touch: tests/test-basic.sh

INTERFACES:
- tally --json FILE prints {"lines":N,"words":N,"bytes":N} on one line and exits 0.
- tally FILE without the flag prints exactly what it prints today.
- An unreadable FILE prints an error to stderr, prints nothing to stdout and exits 2.
- An unknown option prints a usage line to stderr and exits 2.

CONSTRAINTS:
- Plain POSIX sh and standard Unix tools only. No new dependencies.
- Do not edit, skip or loosen any existing test.
- Each new test must fail when the code it covers does nothing.
- Out of scope: other output formats, renaming flags, refactoring.

VERIFICATION: sh tests/test-basic.sh && sh tests/test-json.sh
