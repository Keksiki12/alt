#!/bin/bash
# cleanup_lr1.sh — полная очистка изменений ЛР1 "Аудит и hardening ОС Альт"
# Запускать ОТ ROOT на КАЖДОЙ машине (и workstation, и server).
# Скрипт идемпотентен: можно запускать несколько раз.

set +e  # не прерываться при ошибках — чистим всё, что найдём

echo "======================================================"
echo " Очистка ЛР1 на узле: $(hostname)"
echo " Дата: $(date)"
echo "======================================================"
echo

# ------------------------------------------------------------------
# 1. Остановка тестовой службы http.server на порту 8080
# ------------------------------------------------------------------
echo "[1/14] Остановка python http.server на 8080..."
pkill -f "http.server 8080" 2>/dev/null
sleep 1
if ss -tulnp 2>/dev/null | grep -q ':8080'; then
    # Если что-то осталось — попробуем через fuser
    fuser -k 8080/tcp 2>/dev/null
    sleep 1
fi
echo "    Готово."

# ------------------------------------------------------------------
# 2. Разустановка избыточных служб (cups, avahi, bluetooth)
# ------------------------------------------------------------------
echo "[2/14] Разустановка служб cups, avahi-daemon, bluetooth..."
for svc in cups avahi-daemon bluetooth; do
    if systemctl list-unit-files 2>/dev/null | grep -q "^${svc}"; then
        systemctl unmask "$svc" 2>/dev/null
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null
        echo "    $svc — остановлена, отключена, размаскирована."
    fi
done

# ------------------------------------------------------------------
# 3. Возврат политик control к штатным значениям
# ------------------------------------------------------------------
echo "[3/14] Возврат политик control..."
if command -v control >/dev/null 2>&1; then
    control su public 2>/dev/null
    control sudo public 2>/dev/null
    control passwd tcb 2>/dev/null
    control mount public 2>/dev/null
    echo "    Текущее состояние control:"
    for f in su sudo passwd mount; do
        printf "      %-8s -> " "$f"
        control "$f" 2>/dev/null || echo "n/a"
    done
else
    echo "    [!] control не найден — пропускаем."
fi

# ------------------------------------------------------------------
# 4. Удаление правил sudo
# ------------------------------------------------------------------
echo "[4/14] Удаление /etc/sudoers.d/90-legacy..."
rm -f /etc/sudoers.d/90-legacy
# Проверка синтаксиса
if command -v visudo >/dev/null 2>&1; then
    visudo -c 2>&1 | tail -3
fi

# ------------------------------------------------------------------
# 5. Удаление SUID-копии bash и каталога /opt/legacy
# ------------------------------------------------------------------
echo "[5/14] Удаление /opt/legacy/lbash и /opt/legacy..."
if [ -e /opt/legacy/lbash ]; then
    chmod -s /opt/legacy/lbash 2>/dev/null
    rm -f /opt/legacy/lbash
fi
# Удаляем каталог, если он пуст
rmdir /opt/legacy 2>/dev/null
# Если остались другие файлы — не трогаем, но сообщаем
if [ -d /opt/legacy ]; then
    echo "    [!] /opt/legacy не пуст:"
    ls -la /opt/legacy
fi

# ------------------------------------------------------------------
# 6. Удаление /srv/share и восстановление прав
# ------------------------------------------------------------------
echo "[6/14] Удаление /srv/share..."
if [ -e /srv/share/config.conf ]; then
    chmod 0644 /srv/share/config.conf 2>/dev/null
    chown root:root /srv/share/config.conf 2>/dev/null
    rm -f /srv/share/config.conf
fi
if [ -d /srv/share ]; then
    # Сначала пробуем удалить как пустой
    rmdir /srv/share 2>/dev/null
    # Если не пуст — сообщаем
    if [ -d /srv/share ]; then
        echo "    [!] /srv/share не пуст:"
        ls -la /srv/share
        echo "    Удалите вручную: rm -rf /srv/share"
    fi
fi

# ------------------------------------------------------------------
# 7. Восстановление прав /etc/shadow и /etc/tcb
# ------------------------------------------------------------------
echo "[7/14] Восстановление прав /etc/shadow и /etc/tcb..."
# Штатные права в Альт: /etc/shadow — 0640 root:shadow
if [ -e /etc/shadow ]; then
    chmod 0640 /etc/shadow 2>/dev/null
    # Определяем группу
    if getent group shadow >/dev/null 2>&1; then
        chown root:shadow /etc/shadow 2>/dev/null
    else
        chown root:root /etc/shadow 2>/dev/null
    fi
    echo "    /etc/shadow: $(stat -c '%a %U:%G' /etc/shadow)"
fi
# tcb
if [ -d /etc/tcb ]; then
    chmod 0710 /etc/tcb 2>/dev/null
    if getent group tcb >/dev/null 2>&1; then
        chown root:tcb /etc/tcb 2>/dev/null
    fi
    echo "    /etc/tcb:    $(stat -c '%a %U:%G' /etc/tcb)"
fi

# ------------------------------------------------------------------
# 8. Восстановление штатных SUID-битов
# ------------------------------------------------------------------
echo "[8/14] Восстановление SUID на штатных утилитах..."
for f in /usr/bin/passwd /bin/su /usr/bin/sudo /bin/mount /bin/umount /usr/bin/chsh /usr/bin/chfn /usr/bin/newgrp /usr/bin/gpasswd; do
    if [ -e "$f" ]; then
        chmod 4755 "$f" 2>/dev/null
    fi
done
# Контрольная проверка passwd по пакету
if command -v rpm >/dev/null 2>&1; then
    rpm -Vf /usr/bin/passwd 2>&1 | head -5
fi

# ------------------------------------------------------------------
# 9. Разблокировка и удаление учётных записей
# ------------------------------------------------------------------
echo "[9/14] Удаление учётных записей devops1, devops2, svc-backup, legacy-app..."
for u in legacy-app svc-backup devops1 devops2; do
    if id "$u" >/dev/null 2>&1; then
        # Разблокируем пароль (на случай passwd -l)
        passwd -u "$u" 2>/dev/null
        # Возвращаем оболочку (если меняли на nologin)
        usermod -s /bin/bash "$u" 2>/dev/null
        # Удаляем домашний каталог и почту
        userdel -r "$u" 2>/dev/null
        if id "$u" >/dev/null 2>&1; then
            # Если не удалился — форсируем
            userdel -f -r "$u" 2>/dev/null
        fi
        if id "$u" >/dev/null 2>&1; then
            echo "    [!] $u всё ещё существует — удалите вручную"
        else
            echo "    [OK] $u удалён"
        fi
    else
        echo "    [OK] $u отсутствует"
    fi
done

# ------------------------------------------------------------------
# 10. Удаление каталогов аудита и baseline
# ------------------------------------------------------------------
echo "[10/14] Удаление /root/audit, /root/baseline, архивов..."
rm -rf /root/audit 2>/dev/null
rm -rf /root/baseline 2>/dev/null
rm -f /root/baseline_hardened_*.tar.gz 2>/dev/null
echo "    Готово."

# ------------------------------------------------------------------
# 11. Удаление временных файлов, логов nmap, скриптов очистки
# ------------------------------------------------------------------
echo "[11/14] Удаление временных файлов и логов..."
rm -f /tmp/http8080.log 2>/dev/null
rm -f /root/nmap-before.txt /root/nmap-after.txt 2>/dev/null
rm -f /tmp/nmap-*.txt 2>/dev/null
rm -f /root/cleanup_lr1.sh /root/cleanup_workstation.sh /root/cleanup_server.sh 2>/dev/null
# Удаляем временный файл visudo, если остался
rm -f /etc/sudoers.d/90-legacy.tmp 2>/dev/null
echo "    Готово."

# ------------------------------------------------------------------
# 12. Удаление установленных утилит (nmap, netcat) — ОПЦИОНАЛЬНО
# ------------------------------------------------------------------
echo "[12/14] Опциональная очистка пакетов nmap/netcat..."
# Раскомментируйте, если хотите удалить:
# if rpm -q nmap >/dev/null 2>&1; then
#     apt-get remove -y nmap 2>/dev/null
#     apt-get autoremove -y 2>/dev/null
# fi
# if rpm -q netcat >/dev/null 2>&1; then
#     apt-get remove -y netcat 2>/dev/null
#     apt-get autoremove -y 2>/dev/null
# fi
echo "    Пропущено (раскомментируйте в скрипте при необходимости)."

# ------------------------------------------------------------------
# 13. Проверка: не осталось ли чего-то из ЛР
# ------------------------------------------------------------------
echo "[13/14] Проверка остатков ЛР..."
echo "    --- Учётные записи ---"
for u in devops1 devops2 svc-backup legacy-app; do
    if id "$u" >/dev/null 2>&1; then
        echo "    [!] $u найден"
    else
        echo "    [OK] $u отсутствует"
    fi
done

echo "    --- Файлы ЛР ---"
for f in /opt/legacy/lbash /srv/share/config.conf /etc/sudoers.d/90-legacy; do
    if [ -e "$f" ]; then
        echo "    [!] $f найден"
    else
        echo "    [OK] $f отсутствует"
    fi
done

echo "    --- Каталоги аудита ---"
for d in /root/audit /root/baseline; do
    if [ -d "$d" ]; then
        echo "    [!] $d найден"
    else
        echo "    [OK] $d отсутствует"
    fi
done

echo "    --- Порт 8080 ---"
if ss -tulnp 2>/dev/null | grep -q ':8080'; then
    echo "    [!] порт 8080 всё ещё занят"
    ss -tulnp | grep ':8080'
else
    echo "    [OK] порт 8080 свободен"
fi

echo "    --- SUID-файлы ---"
find / -xdev -type f -perm -4000 -exec ls -l {} \; 2>/dev/null

# ------------------------------------------------------------------
# 14. Итог
# ------------------------------------------------------------------
echo
echo "======================================================"
echo " Очистка на $(hostname) завершена."
echo "======================================================"
echo
echo "Рекомендуется перезагрузить узел:"
echo "    reboot"
echo
echo "После перезагрузки проверьте:"
echo "    id devops1                    # no such user"
echo "    ls /opt/legacy                # No such file or directory"
echo "    ss -tulnp | grep 8080         # пусто"
echo "    control su                    # public"