#!/bin/sh
# tests/mutate.sh: breaks check-spec.sh on purpose, one change at a time, and
# runs tests/test.sh against each broken copy. A mutation is "killed" when the
# tests fail on it and "survived" when they still pass. A mutation whose sed
# changed nothing is reported as an error, so it can never count as a kill.
#
#   sh tests/mutate.sh
#
# Exit 0 only when every mutation was killed and none was an error.

here=$(cd "$(dirname "$0")" && pwd) || exit 1
ORIG="$here/../check-spec.sh"

if [ ! -f "$ORIG" ]; then
  echo "ERROR: no check script at $ORIG" >&2
  exit 1
fi

T=$(mktemp -d "${TMPDIR:-/tmp}/five-part-mutate.XXXXXX") || exit 1
cleanup() {
  if [ -n "$T" ] && [ -d "$T" ]; then
    rm -rf "$T"
  fi
}
trap cleanup EXIT
trap 'exit 1' INT TERM

echo "baseline: tests on the unmodified script"
if ! sh "$here/test.sh" >"$T/baseline.log" 2>&1; then
  tail -n 5 "$T/baseline.log"
  echo "ERROR: the tests fail on the unmodified script, so no mutation result means anything" >&2
  exit 1
fi
tail -n 2 "$T/baseline.log"

killed=0
survived=0
errors=0

# mutate NAME SED_EXPRESSION
mutate() {
  name="$1"; expr="$2"
  copy="$T/mutant.sh"
  sed -E "$expr" "$ORIG" >"$copy"
  if cmp -s "$ORIG" "$copy"; then
    echo "error    $name (the sed changed nothing)"
    errors=$((errors + 1))
    return
  fi
  if CHECK_SPEC="$copy" sh "$here/test.sh" >"$T/mutant.log" 2>&1; then
    echo "survived $name"
    survived=$((survived + 1))
  else
    echo "killed   $name"
    killed=$((killed + 1))
  fi
}

for key in OBJECTIVE FILES INTERFACES CONSTRAINTS VERIFICATION; do
  mutate "drop $key from the key list" \
    "/^  for key in /s/ $key( |;)/\\1/"
done
mutate "drop case-insensitivity" \
  's/grep -qiE/grep -qE/g'
mutate "drop the colon-free heading form" \
  's#^([[:space:]]*&& ! grep -qiE ).*$#\1"zzz-never-matches" "$f"; then#'
mutate "drop the end anchor of the colon-free heading form" \
  's/(\$\{key\}\[\[:space:\]\]\*)\$" "\$f"/\1" "$f"/'
mutate "allow leading spaces before the KEY: form" \
  's/grep -qiE "\^\(##\?/grep -qiE "^[[:space:]]*(##?/'
mutate "allow leading spaces before the heading form" \
  's/grep -qiE "\^##\?/grep -qiE "^[[:space:]]*##?/'
mutate "change exit 6 to 0" \
  's/return 6/return 0/'
mutate "drop the missing list from the message" \
  's/missing: \$missing"/missing:"/'
mutate "change the template line" \
  's/Template: SPEC.template.md/Template: none/'
mutate "drop the OK line" \
  's/echo "OK: all five parts present"/:/'
mutate "break --verify-line label stripping" \
  "s#\\| sed -E '.*'\$#| cat#"
mutate "print every VERIFICATION line instead of the first" \
  's/ \| head -1//'
mutate "change the usage exit code" \
  's/^  exit 5$/  exit 4/'
mutate "skip the readable-file check" \
  's/^if \[ ! -f "\$spec" \] \|\| \[ ! -r "\$spec" \]; then$/if false; then/'
mutate "skip only the unreadable-file test" \
  's/ \|\| \[ ! -r "\$spec" \]//'
mutate "accept three or more hashes before the KEY: form" \
  's/grep -qiE "\^\(##\?/grep -qiE "^(#+/'
mutate "accept three or more hashes before the heading form" \
  's/grep -qiE "\^##\?/grep -qiE "^#{1,3}/'
mutate "accept an option-looking file name" \
  's/^  -\*\) usage ;;$/  zzz-never) usage ;;/'

echo "mutations killed: $killed  survived: $survived  errors: $errors"
if [ "$survived" -ne 0 ] || [ "$errors" -ne 0 ]; then
  exit 1
fi
exit 0
