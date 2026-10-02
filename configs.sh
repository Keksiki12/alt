#!/bin/bash

LOG_FILE="/var/log/ipa_user_creation.log"
GROUP="4course"

if ! klist &>/dev/null; then
    echo "$(date '+%F %T') - ERROR: Нет билета Kerberos. Выполните kinit admin" >> "$LOG_FILE"
    echo "Сначала выполните: kinit admin"
    exit 1
fi

if ! ipa group-show "$GROUP" &>/dev/null; then
    ipa group-add "$GROUP" && \
    echo "$(date '+%F %T') - SUCCESS: Группа $GROUP создана" >> "$LOG_FILE"
else
    echo "$(date '+%F %T') - INFO: Группа $GROUP уже существует" >> "$LOG_FILE"
fi

for i in $(seq 1 30); do
    USER="student$i"

    if ipa user-show "$USER" &>/dev/null; then
        echo "$(date '+%F %T') - WARN: Пользователь $USER уже существует, пропуск" >> "$LOG_FILE"
        continue
    fi

    if ipa user-add "$USER" --first="Student" --last="$i" --shell=/bin/bash --password <<< "P@ssw0rd$i" &>/dev/null; then
        # Сбрасываем требование смены пароля при первом входе
        ipa user-mod "$USER" --setattr=krbPasswordExpiration=20291225011529Z &>/dev/null
        echo "$(date '+%F %T') - SUCCESS: Пользователь $USER создан" >> "$LOG_FILE"
    else
        echo "$(date '+%F %T') - ERROR: Не удалось создать $USER" >> "$LOG_FILE"
        continue
    fi

    if ipa group-add-member "$GROUP" --users="$USER" &>/dev/null; then
        echo "$(date '+%F %T') - SUCCESS: $USER добавлен в $GROUP" >> "$LOG_FILE"
    else
        echo "$(date '+%F %T') - ERROR: Не удалось добавить $USER в $GROUP" >> "$LOG_FILE"
    fi
done
