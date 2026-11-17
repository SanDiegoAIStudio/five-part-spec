#!/bin/sh
# check-spec.sh: refuse a spec that is missing one of the five parts.
#
#   sh check-spec.sh SPEC.md                 exit 0 when all five parts are present,
#                                            exit 6 and name the missing ones otherwise
#   sh check-spec.sh --verify-line SPEC.md   print the text after the first VERIFICATION label
#
# Exit codes: 0 ok, 5 bad arguments, 6 spec incomplete.
# Works under sh, bash, zsh and dash. No bash arrays.

usage() {
  echo "usage: check-spec.sh SPEC.md | check-spec.sh --verify-line SPEC.md" >&2
  exit 5
}

# A part counts when a line matches "KEY:" (optionally behind one or two #)
# or a heading made only of "#" and KEY. Case-insensitive.
validate_five_part() {
  f="$1"
  missing=""
  for key in OBJECTIVE FILES INTERFACES CONSTRAINTS VERIFICATION; do
    if ! grep -qiE "^(##?[[:space:]]*)?${key}[[:space:]]*:" "$f" \
      && ! grep -qiE "^##?[[:space:]]*${key}[[:space:]]*$" "$f"; then
      missing="${missing:+$missing }$key"
    fi
  done
  if [ -n "$missing" ]; then
    echo "ERROR: five-part spec incomplete - missing: $missing" >&2
    echo "Template: SPEC.template.md" >&2
    return 6
  fi
  echo "OK: all five parts present"
  return 0
}

# Print the text after the label on the first VERIFICATION line, or an empty line.
extract_verify_cmd() {
  f="$1"
  line=$(grep -iE '^(##?[[:space:]]*)?VERIFICATION[[:space:]]*:' "$f" | head -1 || true)
  if [ -n "$line" ]; then
    printf '%s\n' "$line" | sed -E 's/^(##?[[:space:]]*)?[Vv][Ee][Rr][Ii][Ff][Ii][Cc][Aa][Tt][Ii][Oo][Nn][[:space:]]*:[[:space:]]*//'
    return 0
  fi
  echo ""
}

mode=check
case "$#" in
  1) spec="$1" ;;
  2)
    if [ "$1" = "--verify-line" ]; then
      mode=verify
      spec="$2"
    else
      usage
    fi
    ;;
  *) usage ;;
esac

case "$spec" in
  -*) usage ;;
esac
if [ ! -f "$spec" ] || [ ! -r "$spec" ]; then
  usage
fi

if [ "$mode" = verify ]; then
  extract_verify_cmd "$spec"
  exit 0
fi
validate_five_part "$spec"
exit $?
