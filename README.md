# five-part-spec

A template for the spec you write before handing coding work to another agent, the rules the receiving agent follows, and a small shell script that refuses a spec with a missing part. It is for anyone who hands work to a coding agent, or to another person, and wants the handoff to be checkable.

## Quick start

1. Copy `SPEC.template.md` to a new file, for example `my-spec.md`.
2. Fill in the five parts, and delete the guidance below the line of equals signs.
3. Run the check: `sh check-spec.sh my-spec.md`. It prints `OK: all five parts present` and exits 0, or names the missing parts and exits 6.
4. Give the receiving agent your spec and `AGENT-RULES.md`.

Run the tests with `sh tests/test.sh`. They run the check under every one of sh, bash, zsh and dash that exists on your machine and print which ones ran. `sh tests/mutate.sh` breaks the script on purpose, one change at a time, and confirms that the tests notice each break. Run as root, as in many containers, the test for an unreadable file is skipped, and `sh tests/mutate.sh` then reports the one break that test covers as survived. Nothing needs installing: the script uses POSIX sh and standard Unix tools.

`sh check-spec.sh --verify-line my-spec.md` prints the text after the first `VERIFICATION:` label, so a script can run the line itself. Run the plain check first, and treat empty output as no line to run: for a spec with no `VERIFICATION:` label, including one whose only mention is a `## Verification` heading, `--verify-line` prints an empty line and exits 0. Bad arguments, an unknown option or an unreadable file exit with 5.

## Example

In the blocks below, the `exit status` line is added to show the exit code; the script does not print it. The `ERROR` and `Template` lines go to standard error.

The complete example passes:

```
$ sh check-spec.sh examples/good-spec.md
OK: all five parts present
exit status: 0
```

The same spec with INTERFACES and VERIFICATION removed is refused:

```
$ sh check-spec.sh examples/bad-spec.md
ERROR: five-part spec incomplete - missing: INTERFACES VERIFICATION
Template: SPEC.template.md
exit status: 6
```

The verification line of the good example:

```
$ sh check-spec.sh --verify-line examples/good-spec.md
sh tests/test-basic.sh && sh tests/test-json.sh
exit status: 0
```

Both examples describe a made-up change, adding a `--json` flag to a small command line tool called tally. The tool does not exist in this repository, and neither do the two test files that the good example's verification line names.

## The five parts

OBJECTIVE is one paragraph that says what to build or change and why, in terms of a result someone can observe. If the receiving agent cannot tell when it is done, the objective is too vague.

FILES lists every file that may be touched, each marked create or modify, plus the paths that must stay as they are. It is the boundary of the work. Anything outside it is a gap to report, not a change to make.

INTERFACES holds the exact shapes the code must match: signatures, flags, output formats, fields, and the error cases callers rely on. This is where a handoff is most often too loose.

CONSTRAINTS says what is out of scope, which conventions and dependencies are allowed, and what may happen to existing tests. It stops the work from growing.

VERIFICATION is one command that exits 0 when the work is right and non-zero when it is not. The person handing off the work reruns it, so it has to run from a clean checkout.

## The receiving agent's rules

`AGENT-RULES.md` is the short contract for the agent that receives the spec. In summary: work only in the files named, do not widen the scope, run the verification line and report its real result, report gaps instead of guessing, change no existing test to make a check pass, and make no commits unless the spec asks for them. Read the file for the full list.

## Limits

The check finds the five labels and nothing more. It does not judge whether a part is any good: a spec whose INTERFACES part says only `TBD` passes. A label has to start its line, so a key written mid-sentence or indented with spaces does not count. A heading with three or more #, such as `### Objective`, does not count either. Neither does a label written as a list item (`- OBJECTIVE:`), in bold (`**OBJECTIVE:**`) or misspelled (`FILE:` for `FILES:`). The template passes before you fill it in, because its five labels are already there. A verification line that passes is only as good as the tests it runs, which is why the template ends with a checklist for the person who reads the result: read the diff, rerun the verification yourself, break one check by hand and watch its test fail, and check each claim.

## Where this came from

The check is lifted from a runner the author uses to hand coding work to agents. That runner refuses a spec with a missing part before any agent starts. The matching rules, the exit code 6 and the error message are the same as in the runner. The `OK` line is an addition for this repository, and the script's argument handling was written to stand alone.

## License

MIT. See `LICENSE`.

## Built at San Diego AI Studio

This template comes out of San Diego AI Studio, the builders' community in San Diego. More projects from the community are listed at https://sandiegoaistudio.com/projects
