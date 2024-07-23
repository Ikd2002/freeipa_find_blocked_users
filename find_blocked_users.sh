#!/bin/bash
echo "ChangeMe" | kinit admin

failed_logins=0
already_problem_send=false
TOKEN="7........0:A..................U"
ID="-4..........."
URL="https://api.telegram.org/bot$TOKEN/sendMessage"

# Добавляем бесконечный цикл
while true; do

# Обнуляем лог файл
cp /dev/null /var/log/freeipa_blocked.log

# Проверка
users=$(ipa user-find --all --disabled=false | grep 'User login' | awk '{print $3}');
for user in $users;
do
     failed_logins=$(ipa user-status $user | head -n 5 | grep 'Failed logins' | awk '{print $3}');
     if (( $(echo "$failed_logins > 4" | bc) )); then
          echo "FreeIPA User: $user has $failed_logins failed logins." >> /var/log/freeipa_blocked.log
          echo "User: $user has $failed_logins failed logins."
     else
          echo  "OK. User account is Active"
     fi;
done

# Если пользователи найдены, отправляем алерт
if [ "$already_problem_send" == "false" ]; then
    # Если размер файла лога больше 0
  if [ $(stat -c '%s' /var/log/freeipa_blocked.log) -gt 0 ] ; then
      cat /var/log/freeipa_blocked.log | mail -s "ALERT. Blocked users found" security@change.domain
      content=$(cat /var/log/freeipa_blocked.log)
      curl -s -X POST $URL -d chat_id=$ID -d text="$content" > /dev/null 2>&1
      already_problem_send=true
  fi
else
  echo "alert already sent"
fi

# Если размер файла 0, то есть пользователи не найдены то  выставляем флаг already_problem_send как ложь
if [ $(stat -c '%s' /var/log/freeipa_blocked.log) == 0 ] ; then
   echo "ok. no blocked users"
   already_problem_send=false
fi

  # Ждем 5 минут перед следующей проверкой
  sleep 300
done
