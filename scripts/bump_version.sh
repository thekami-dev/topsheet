#!/data/data/com.termux/files/usr/bin/bash
# Bumps pubspec.yaml version following the pattern:
#   1.0.1 -> 1.0.2 -> ... -> 1.0.9 -> 1.1.1 -> 1.1.2 -> ... -> 1.1.9 -> 1.2.1 ...
# (patch cycles 1-9 within a minor; rolling over bumps minor and resets patch to 1, never .0)
set -e

CURRENT=$(grep '^version:' pubspec.yaml | awk '{print $2}' | cut -d'+' -f1)
MAJOR=$(echo "$CURRENT" | cut -d. -f1)
MINOR=$(echo "$CURRENT" | cut -d. -f2)
PATCH=$(echo "$CURRENT" | cut -d. -f3)

if [ "$PATCH" -ge 9 ]; then
  MINOR=$((MINOR + 1))
  PATCH=1
else
  PATCH=$((PATCH + 1))
fi

NEW="$MAJOR.$MINOR.$PATCH"

sed -i "s/^version: .*/version: $NEW+1/" pubspec.yaml
echo "Bumped: $CURRENT -> $NEW"
grep "^version:" pubspec.yaml
