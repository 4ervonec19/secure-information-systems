#### Анонимный вход на FTP-сервер

---

```FTP (File-Transfer Protocol)``` -- протокол для передачи файлов между компьютерами. Он работает по принципу «клиент-сервер». Клиент -- программа, которая подключается к серверу, чтобы скачать или загрузить файлы. Сервер -- программа, которая хранит файлы и ждёт подключений.

Обычно используется 2 порта: 20 -- для команд и ответов сервера; 21 -- передача самих файлов и списков файлов.

---

#### Реализация

1. Поднимаем тестовый FTP-сервер через docker

```bash
docker run -d -p 21:21 -p 20:20 -p 21100-21110:21100-21110 --name ftp-anon fauria/vsftpd
docker exec -it ftp-anon sed -i 's/anonymous_enable=NO/anonymous_enable=YES/' /etc/vsftpd/vsftpd.conf
docker restart ftp-anon
docker ps # check
```

2. Скрипт

```bash
# src/Task2/ftp-anon.nse
nmap -p 21 --script ./ftp-anon-script.nse localhost
```

3. Запуск и результат атаки

```txt
Starting Nmap 7.98 ( https://nmap.org ) at 2026-03-30 18:36 +0300
DEBUG: script started
Nmap scan report for localhost (127.0.0.1)
Host is up (0.00011s latency).
Other addresses for localhost (not scanned): ::1

PORT   STATE SERVICE
21/tcp open  ftp
|_ftp-anon-script: Access granted!

Nmap done: 1 IP address (1 host up) scanned in 0.07 seconds
```

---

#### Что произошло?

1. В конфигурации сервера стоит параметр ```anonymous_enable=YES,``` разрешающий доступ с именем ```anonymous``` и любым паролем.

2. NSE-скрипт подключается к порту 21, получает приветствие сервера (220), отправляет команду ```USER anonymous```, получает код 331 -- требование пароля, вводит пароль -- получает доступ.

