#!/bin/bash
# usage: ./count.sh [-l|-w|-c] filename

while getopts "lwc" opt; do
    case $opt in
        l) OPT_LINES=1 ;;
        w) OPT_WORDS=1 ;;
        c) OPT_CHARS=1 ;;
        *) echo "Usage: $0 [-l|-w|-c] file"; exit 1 ;;
    esac
done
shift $((OPTIND - 1))
FILE="$1"

if [ -z "$FILE" ]; then
    echo "Usage: $0 [-l|-w|-c] file"
    exit 1
fi

if [ ! -f "$FILE" ]; then
    echo "Файл не найден: $FILE"
    exit 1
fi

# Если ни одна опция не задана — выводим всё
if [ -z "$OPT_LINES" ] && [ -z "$OPT_WORDS" ] && [ -z "$OPT_CHARS" ]; then
    wc "$FILE"
    exit 0
fi

ARGS=""
[ -n "$OPT_LINES" ] && ARGS="$ARGS -l"
[ -n "$OPT_WORDS" ] && ARGS="$ARGS -w"
[ -n "$OPT_CHARS" ] && ARGS="$ARGS -c"

wc $ARGS "$FILE"
