#!/bin/sh
# tests/test.sh: runs check-spec.sh under every shell found among sh, bash,
# /bin/bash, zsh and dash, and prints one line per case.
#
#   sh tests/test.sh
#   CHECK_SPEC=/path/to/other-copy.sh sh tests/test.sh
#
# Exit 0 when every case passes, 1 when any case fails.
# Each case guards one rule of check-spec.sh; tests/mutate.sh breaks the
# script on purpose and expects this file to notice.

here=$(cd "$(dirname "$0")" && pwd) || exit 1
CHECK="${CHECK_SPEC:-$here/../check-spec.sh}"
EX="$here/../examples"

case "$CHECK" in
  /*) ;;
  *) CHECK="$PWD/$CHECK" ;;
esac

if [ ! -f "$CHECK" ]; then
  echo "ERROR: no check script at $CHECK" >&2
  exit 1
fi

T=$(mktemp -d "${TMPDIR:-/tmp}/five-part-test.XXXXXX") || exit 1
cleanup() {
  if [ -n "$T" ] && [ -d "$T" ]; then
    rm -rf "$T"
  fi
}
trap cleanup EXIT
trap 'exit 1' INT TERM

KEYS="OBJECTIVE FILES INTERFACES CONSTRAINTS VERIFICATION"
pass=0
fail=0
skipped=0
ran=""

title() {
  case "$1" in
    OBJECTIVE) echo Objective ;;
    FILES) echo Files ;;
    INTERFACES) echo Interfaces ;;
    CONSTRAINTS) echo Constraints ;;
    VERIFICATION) echo Verification ;;
  esac
}

lower() {
  printf '%s' "$1" | tr 'A-Z' 'a-z'
}

# mkspec FILE FORM [OMIT]: write a spec with all five keys in FORM, minus OMIT.
mkspec() {
  out="$1"; form="$2"; omit="${3:-}"
  : >"$out"
  for mk in $KEYS; do
    [ "$mk" = "$omit" ] && continue
    case "$form" in
      upper) printf '%s: text for %s\n\n' "$mk" "$mk" >>"$out" ;;
      lower) printf '%s: text\n\n' "$(lower "$mk")" >>"$out" ;;
      hash2title) printf '## %s: text\n\n' "$(title "$mk")" >>"$out" ;;
      hash1upper) printf '# %s: text\n\n' "$mk" >>"$out" ;;
      alone) printf '## %s\ntext\n\n' "$(title "$mk")" >>"$out" ;;
      alone1) printf '# %s\ntext\n\n' "$mk" >>"$out" ;;
      spacecolon) printf '%s : text\n\n' "$mk" >>"$out" ;;
    esac
  done
}

# run SHELL ARGS...: sets rc, and leaves stdout and stderr in $T/out and $T/err.
run() {
  sh_bin="$1"; shift
  "$sh_bin" "$CHECK" "$@" >"$T/out" 2>"$T/err"
  rc=$?
}

report() {
  # report LABEL NAME OK DETAIL
  if [ "$3" = yes ]; then
    pass=$((pass + 1))
    echo "PASS [$1] $2"
  else
    fail=$((fail + 1))
    echo "FAIL [$1] $2 ($4)"
  fi
}

same() {
  # same FILE EXPECTED_TEXT: exact comparison, expected text gets one newline
  printf '%s\n' "$2" >"$T/expected"
  cmp -s "$1" "$T/expected"
}

# expect LABEL NAME RC OUT ERR ARGS...
# OUT and ERR are exact expected texts; NONE means empty; USAGE means the
# stderr must start with "usage:".
expect() {
  label="$1"; name="$2"; want_rc="$3"; want_out="$4"; want_err="$5"; shift 5
  run "$SHELL_BIN" "$@"
  ok=yes; why=""
  [ "$rc" = "$want_rc" ] || { ok=no; why="exit $rc, wanted $want_rc"; }
  if [ "$want_out" = NONE ]; then
    [ ! -s "$T/out" ] || { ok=no; why="$why; stdout not empty"; }
  else
    same "$T/out" "$want_out" || { ok=no; why="$why; stdout differs"; }
  fi
  case "$want_err" in
    NONE) [ ! -s "$T/err" ] || { ok=no; why="$why; stderr not empty"; } ;;
    USAGE)
      [ "$(head -c 6 "$T/err")" = "usage:" ] || { ok=no; why="$why; stderr lacks usage line"; } ;;
    *) same "$T/err" "$want_err" || { ok=no; why="$why; stderr differs"; } ;;
  esac
  report "$label" "$name" "$ok" "$why"
}

incomplete() {
  # incomplete MISSING-LIST: the two stderr lines for an incomplete spec
  printf 'ERROR: five-part spec incomplete - missing: %s\nTemplate: SPEC.template.md' "$1"
}

run_all_cases() {
  label="$1"

  expect "$label" "good example passes with the OK line" 0 \
    "OK: all five parts present" NONE "$EX/good-spec.md"

  expect "$label" "bad example exits 6 and names INTERFACES and VERIFICATION" 6 \
    NONE "$(incomplete 'INTERFACES VERIFICATION')" "$EX/bad-spec.md"

  for form in upper lower hash2title hash1upper alone alone1 spacecolon; do
    mkspec "$T/form.md" "$form"
    expect "$label" "header form '$form' is accepted" 0 \
      "OK: all five parts present" NONE "$T/form.md"
  done

  for k in $KEYS; do
    mkspec "$T/one.md" upper "$k"
    expect "$label" "missing $k alone is reported alone" 6 NONE "$(incomplete "$k")" "$T/one.md"
  done

  mkspec "$T/two.md" upper FILES
  grep -v '^CONSTRAINTS' "$T/two.md" >"$T/two2.md"
  expect "$label" "two missing keys are listed in checking order" 6 NONE \
    "$(incomplete 'FILES CONSTRAINTS')" "$T/two2.md"

  : >"$T/empty.md"
  expect "$label" "an empty file reports all five keys in order" 6 NONE \
    "$(incomplete 'OBJECTIVE FILES INTERFACES CONSTRAINTS VERIFICATION')" "$T/empty.md"

  mkspec "$T/mid.md" upper CONSTRAINTS
  printf 'See the CONSTRAINTS: section of the other spec.\n' >>"$T/mid.md"
  expect "$label" "a key written mid-sentence does not count" 6 NONE \
    "$(incomplete 'CONSTRAINTS')" "$T/mid.md"

  mkspec "$T/ind.md" upper OBJECTIVE
  printf '  OBJECTIVE: indented with two spaces\n' >>"$T/ind.md"
  expect "$label" "a header indented with spaces does not count" 6 NONE \
    "$(incomplete 'OBJECTIVE')" "$T/ind.md"

  mkspec "$T/ind2.md" upper FILES
  printf '  ## Files\n' >>"$T/ind2.md"
  expect "$label" "a heading indented with spaces does not count" 6 NONE \
    "$(incomplete 'FILES')" "$T/ind2.md"

  mkspec "$T/tail.md" upper INTERFACES
  printf '## Interfaces and more words\n' >>"$T/tail.md"
  expect "$label" "a colon-free heading with extra words does not count" 6 NONE \
    "$(incomplete 'INTERFACES')" "$T/tail.md"

  mkspec "$T/trail.md" upper VERIFICATION
  printf '## Verification   \n' >>"$T/trail.md"
  expect "$label" "a colon-free heading with trailing spaces counts" 0 \
    "OK: all five parts present" NONE "$T/trail.md"

  mkspec "$T/h3.md" upper OBJECTIVE
  printf '### Objective: three hashes\n' >>"$T/h3.md"
  expect "$label" "a label behind three hashes does not count" 6 NONE \
    "$(incomplete 'OBJECTIVE')" "$T/h3.md"

  mkspec "$T/h3b.md" upper OBJECTIVE
  printf '### Objective\n' >>"$T/h3b.md"
  expect "$label" "a heading with three hashes alone on its line does not count" 6 NONE \
    "$(incomplete 'OBJECTIVE')" "$T/h3b.md"

  rm -f "$T/unreadable.md"
  cp "$EX/good-spec.md" "$T/unreadable.md"
  chmod 000 "$T/unreadable.md"
  if [ -r "$T/unreadable.md" ]; then
    skipped=$((skipped + 1))
    echo "SKIP [$label] an unreadable file exits 5 (the file is still readable after chmod 000, as when running as root)"
  else
    expect "$label" "an unreadable file exits 5 with a usage line" 5 NONE USAGE "$T/unreadable.md"
  fi

  expect "$label" "--verify-line prints the command of the good example" 0 \
    "sh tests/test-basic.sh && sh tests/test-json.sh" NONE --verify-line "$EX/good-spec.md"

  expect "$label" "--verify-line prints an empty line for a spec without one" 0 \
    "" NONE --verify-line "$EX/bad-spec.md"

  mkspec "$T/vl1.md" upper VERIFICATION
  printf '## Verification:   make test  \n' >>"$T/vl1.md"
  expect "$label" "--verify-line strips a heading label in any letter case" 0 \
    "make test  " NONE --verify-line "$T/vl1.md"

  mkspec "$T/vl2.md" upper VERIFICATION
  printf 'verification :echo one\nVERIFICATION: echo two\n' >>"$T/vl2.md"
  expect "$label" "--verify-line prints only the first matching line" 0 \
    "echo one" NONE --verify-line "$T/vl2.md"

  mkspec "$T/vl3.md" alone
  expect "$label" "--verify-line ignores a colon-free heading" 0 \
    "" NONE --verify-line "$T/vl3.md"

  expect "$label" "no argument exits 5 with a usage line" 5 NONE USAGE
  expect "$label" "an unknown option exits 5" 5 NONE USAGE --bogus
  expect "$label" "an unknown option before a file exits 5" 5 NONE USAGE --bogus "$EX/good-spec.md"
  expect "$label" "a missing file exits 5" 5 NONE USAGE "$T/does-not-exist.md"
  expect "$label" "a directory instead of a file exits 5" 5 NONE USAGE "$T"
  expect "$label" "--verify-line without a file exits 5" 5 NONE USAGE --verify-line
  expect "$label" "--verify-line with a missing file exits 5" 5 NONE USAGE --verify-line "$T/does-not-exist.md"
  cp "$EX/good-spec.md" "$T/-dash.md"
  cd "$T" || exit 1
  expect "$label" "a file whose name starts with a dash is read as an option, exit 5" 5 NONE USAGE -dash.md
  cd "$here" || exit 1

  expect "$label" "two plain arguments exit 5" 5 NONE USAGE "$EX/good-spec.md" "$EX/bad-spec.md"
}

# Find the shells that exist, once per resolved path.
seen=""
for cand in sh bash /bin/bash zsh dash; do
  path=$(command -v "$cand" 2>/dev/null) || continue
  case " $seen " in *" $path "*) continue ;; esac
  seen="$seen $path"
  SHELL_BIN="$path"
  run_all_cases "$cand"
  ran="$ran $cand($path)"
done

echo "shells ran:$ran"
for cand in dash zsh bash; do
  command -v "$cand" >/dev/null 2>&1 || echo "shell not on this machine: $cand"
done
echo "passed: $pass  failed: $fail  skipped: $skipped"
[ "$fail" -eq 0 ] || exit 1
exit 0
