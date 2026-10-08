#!/bin/bash

LOG_FILE="/var/log/calc.log"

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: $1" >> "$LOG_FILE"
}

if [ $# -ne 3 ]; then
    log_error "Неверное количество аргументов: $*"
    echo "Использование: $0 <число1> <оператор> <число2>"
    exit 1
fi

NUM1="$1"
OP="$2"
NUM2="$3"

if ! [[ "$NUM1" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    log_error "Первый аргумент не является числом: $NUM1"
    echo "Ошибка: '$NUM1' не является числом"
    exit 1
fi

if ! [[ "$NUM2" =~ ^-?[0-9]+([.][0-9]+)?$ ]]; then
    log_error "Второй аргумент не является числом: $NUM2"
    echo "Ошибка: '$NUM2' не является числом"
    exit 1
fi

case "$OP" in
    +) RESULT=$(echo "$NUM1 + $NUM2" | bc) ;;
    -) RESULT=$(echo "$NUM1 - $NUM2" | bc) ;;
    \*) RESULT=$(echo "$NUM1 * $NUM2" | bc) ;;
    /)
        if [ "$NUM2" == "0" ] || [ "$NUM2" == "0.0" ]; then
            log_error "Деление на ноль: $NUM1 / $NUM2"
            echo "Ошибка: деление на ноль"
            exit 1
        fi
        RESULT=$(echo "scale=2; $NUM1 / $NUM2" | bc)
        ;;
    *)
        log_error "Неизвестный оператор: $OP"
        echo "Ошибка: неизвестный оператор '$OP'"
        exit 1
        ;;
esac

echo "$NUM1 $OP $NUM2 = $RESULT"