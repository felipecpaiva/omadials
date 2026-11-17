#!/usr/bin/env bash
# Architecture rules, checked mechanically (architecture.md sections 3, 7, 10): only core/CommandRunner.qml starts
# processes, only theme/Theme.qml (and Service.qml for ShellIpc) import qs.Commons, no colour literals in QML,
# QML at most 150 lines, JS at most 250, no `sh -c`.
cd "$(dirname "$0")/.." || exit 1
fail=0
qml=$(find . -name '*.qml' -not -path './spikes/*' -not -path './docs/*' -not -path './app/*')  # app/ is a separate program with its own rules
bad=$(grep -ln 'Process {' $qml | grep -v '^./core/CommandRunner.qml$'); [ -n "$bad" ] && { echo "Process outside CommandRunner: $bad"; fail=1; }
bad=$(grep -ln 'import qs.Commons' $qml | grep -vE '^./(theme/Theme|Service)\.qml$'); [ -n "$bad" ] && { echo "qs.Commons outside Theme: $bad"; fail=1; }
bad=$(grep -nE '"#[0-9a-fA-F]{3,8}"' $qml | grep -v '^./spikes'); [ -n "$bad" ] && { echo "colour literal: $bad"; fail=1; }
bad=$(grep -rnE "\"sh\", *\"-c\"|'sh', *'-c'" --include=*.qml --include=*.js core controls views vm settings logic); [ -n "$bad" ] && { echo "sh -c: $bad"; fail=1; }
for f in $qml; do n=$(wc -l < "$f"); [ "$n" -gt 150 ] && { echo "QML over 150 lines: $f ($n)"; fail=1; }; done
for f in logic/*.js controls/*/*.js; do n=$(wc -l < "$f"); [ "$n" -gt 250 ] && { echo "JS over 250 lines: $f ($n)"; fail=1; }; done
[ $fail = 0 ] && echo "isolation: ok"
exit $fail
