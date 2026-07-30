#!/bin/sh
set -eu

IONICE_CLASS="${IONICE_CLASS:-3}"
IONICE_LEVEL="${IONICE_LEVEL:-7}"

# Built-in report mode:
#   docker run ... rmlint scan /scan/target [extra rmlint args]
# Writes report files into REPORT_DIR (default: /reports).
if [ "${1:-}" = "scan" ]; then
    shift
    SCAN_TARGET="${1:-/work}"
    if [ "$#" -gt 0 ]; then
        shift
    fi

    REPORT_DIR="${REPORT_DIR:-/reports}"
    REPORT_NAME="${REPORT_NAME:-duplicates-report}"
    REPORT_TIMESTAMP="${REPORT_TIMESTAMP:-1}"

    mkdir -p "$REPORT_DIR"

    SUFFIX=""
    if [ "$REPORT_TIMESTAMP" = "1" ]; then
        SUFFIX="-$(date +%Y%m%d-%H%M%S)"
    fi

    REPORT_JSON="$REPORT_DIR/${REPORT_NAME}${SUFFIX}.json"
    REPORT_TXT="$REPORT_DIR/${REPORT_NAME}${SUFFIX}.txt"
    REPORT_SH="$REPORT_DIR/${REPORT_NAME}${SUFFIX}.sh"

    if [ "$IONICE_CLASS" = "3" ]; then
        exec ionice -c "$IONICE_CLASS" rmlint "$SCAN_TARGET" "$@" \
            -o json:"$REPORT_JSON" \
            -o summary:"$REPORT_TXT" \
            -o sh:"$REPORT_SH"
    fi

    exec ionice -c "$IONICE_CLASS" -n "$IONICE_LEVEL" rmlint "$SCAN_TARGET" "$@" \
        -o json:"$REPORT_JSON" \
        -o summary:"$REPORT_TXT" \
        -o sh:"$REPORT_SH"
fi

# class 3 (idle) ignores priority level; class 1/2 can use -n.
if [ "$IONICE_CLASS" = "3" ]; then
    exec ionice -c "$IONICE_CLASS" rmlint "$@"
fi

exec ionice -c "$IONICE_CLASS" -n "$IONICE_LEVEL" rmlint "$@"
