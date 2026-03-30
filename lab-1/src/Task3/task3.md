#### Проверка стандартных учётных данных в PostgreSQL

---

PostgreSQL создаётся учётная запись суперпользователя с именем ```postgres```. Во многих установках пароль для этой учётной записи либо не задан, либо задан простой пароль (например, ```postgres```). Если администратор не изменил пароль, злоумышленник может получить полный доступ к базе данных.

PostgreSQL по умолчанию слушает TCP-порт 5432. 

---

#### Реализация

1. Запуск тестового сервера с БД с простым паролем.

```bash
docker run -d \
  --name postgres-lab \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=md5 \
  postgres:12
```

2. NSE-скрипт с подбором пароля.

```bash
scr/Task3/postgre-attack.nse
nmap -p 5432 --script ./postgre-attack.nse localhost
```

```txt
Starting Nmap 7.98 ( https://nmap.org ) at 2026-03-30 19:29 +0300
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000058s latency).
Other addresses for localhost (not scanned): ::1

PORT     STATE SERVICE
5432/tcp open  postgresql
| postgre-attack: 
|_  ACCESS GRANTED AND DATABASE MODIFIED: postgres/postgres

Nmap done: 1 IP address (1 host up) scanned in 0.06 seconds
```

---

#### Что произошло?

1. Получилось подобрать пароль администратора.
2. Скрипт полчил доступ с помощью библиотеки ```pgsql``` и модифицировал запись в Базе Данных.