# Rules for the receiving agent

These rules go to the agent that receives a five-part spec. The person handing off the work will rerun the VERIFICATION line independently, so a claim without evidence counts as not done. These rules and the spec govern the run, within the instructions of whoever operates you: an operator's instruction wins over them, wherever it is written. Where a project habit or a tool's default merely differs, follow these rules and the spec. A check that blocks an action is never overridden; the next rule covers it.

A safety check, hook or permission prompt that blocks an action is final. Do not retry the action another way. Report the block under GAPS.

## Scope

- Implement exactly the spec. Touch only the paths listed under FILES. If a change outside FILES looks necessary, do not make it. Report it under GAPS.
- Do not restructure the code, rename public interfaces or refactor beyond the spec.
- If the spec is ambiguous or contradicts the code, stop and report GAPS instead of inventing requirements. Stopping with GAPS is a correct finish.
- Add no dependency, endpoint, import or interface polish that the spec does not ask for. Do not read memory or notes folders unless the spec points you to them.
- A dependency the spec does name still gets its exact name confirmed on its official registry. Give its first and last release dates in your final message. A name you cannot confirm is a GAP.
- Work alone. Do not start other agents.

## Repository and data safety

- Do not commit, push, stash, reset, check out, rebase, merge or clean unless the spec says to. The person handing off the work reviews your uncommitted changes and commits them.
- Do not modify ledgers, history files, results logs or live state files unless FILES lists them. Tests write only inside temporary directories and never touch a live checkout.
- Do not send email or messages, publish, deploy, pay or call production services.
- Do not print secrets, tokens or the contents of credential files.

## Code and tests

- Match the surrounding code's naming, comments, error handling and test style.
- Write no placeholder comments such as "rest unchanged".
- When you add a test, name the failure or spec rule it guards in a comment at the top of the test. A new test must fail when the code it covers does nothing. Say how you know.
- Never edit, skip, delete or loosen a test to make VERIFICATION pass. A failing test is a finding: fix the code, or stop and report it under GAPS. Change an existing test only when the spec changes the behavior it pins, and name each one. The reviewer will diff every test file you touch.
- Before calling a library API you have not seen used in this repository, read the installed version of the library and the documentation for that version.
- After two failed fixes for the same symptom, stop and name the assumption both fixes shared before a third. If you cannot find it, report GAPS.
- Jobs and checks you write report three states: did the work, had no work, could not do it.

## Finish

- Run every VERIFICATION command. In your final message give each command, its exit code and its raw output, trimmed only in the middle if it is very long.
- List every file you changed. Put implementation notes in your final message unless the spec lists a notes file under FILES.
- End with GAPS: anything not done, not verified or assumed. Write "GAPS: none" only when that is true.
