# Five-part spec template

Copy this file, replace the text under each label with your own, and delete everything below the line of equals signs. Then run `sh check-spec.sh your-spec.md`. A spec that is missing a part is refused with exit code 6.

OBJECTIVE: Write one paragraph that says what to build or change and why. Name the result someone can observe when the work is done.

FILES:
- List every file the receiving agent may touch, one per line, each marked (create) or (modify).
- Add a line that names the paths it must not touch.

INTERFACES:
- Write down the exact shapes the code must match: function signatures, command line flags, output formats, data fields.
- List the error cases that callers rely on, with the exit code or message for each.

CONSTRAINTS:
- Say what is out of scope, so the receiving agent does not widen the work.
- Say which conventions, tools and dependencies are allowed, and that no others may be added.
- Say what the receiving agent may do to existing tests (the safe default is nothing).

VERIFICATION: Write the one command that proves the work is done, for example the test command. It must exit 0 on success and non-zero on failure.

===============================================================================

# Guidance (not part of your spec)

## The same spec, filled in

```
OBJECTIVE: Add a --json flag to the tally command so scripts can read its counts without parsing text. With the flag, tally prints one line of JSON and nothing else.

FILES:
- tally.sh (modify)
- tests/test-json.sh (create)
- Do not touch: tests/test-basic.sh

INTERFACES:
- tally --json FILE prints {"lines":N,"words":N,"bytes":N} on one line and exits 0.
- tally FILE without the flag prints exactly what it prints today.
- An unreadable FILE prints an error to stderr, prints nothing to stdout and exits 2.

CONSTRAINTS:
- Plain POSIX sh and standard Unix tools only, no new dependencies.
- Do not edit, skip or loosen any existing test.
- Out of scope: other output formats, renaming flags, refactoring.

VERIFICATION: sh tests/test-basic.sh && sh tests/test-json.sh
```

## Accepted label forms

The check counts a part when a line starts with its label in any of these forms, in any letter case: `OBJECTIVE:`, `## Objective:`, `# OBJECTIVE:`, or a heading `## Objective` alone on its line. A label in the middle of a sentence, or a label indented with spaces, does not count. A heading with three or more #, such as `### Objective`, does not count either.

## Checklist when the work comes back

1. Read the diff, not the report. Confirm that only the files named under FILES changed.
2. Rerun the verification line yourself. Do not accept a pasted result in its place.
3. Break one check by hand, for example change a comparison in the code, and watch the matching test fail. A test that stays green proves nothing.
4. Check each claim in the report against the code or the output it points to.
