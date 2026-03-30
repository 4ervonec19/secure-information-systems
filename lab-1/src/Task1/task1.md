#### Уязвимость Shellshock

---

Уязвимость в программе Bash (командная оболочка), которая позволяет выполнить вредоносную команду на сервере, если сервер использует Bash для обработки некоторых веб-запросов. Например, если на сервере есть специальные скрипты (CGI), которые написаны на Bash, то через специальный заголовок можно заставить сервер выполнить любую команду

--- 

#### Шаги реализации

1. Запуск докер-контейнера с уязвимой тестовой средой

```bash
docker run -d -p 8080:80 --name shellshock vulnerables/cve-2014-6271
```

2. Минимальный тестовый скрипт и запуск ```nmap scripting engine```

```bash
# src/Task1/attack_script.nse 
nmap -p 8080 --script attack_script.nse localhost
```

3. Результат

```txt
Starting Nmap 7.98 ( https://nmap.org ) at 2026-03-30 18:08 +0300
Nmap scan report for localhost (127.0.0.1)
Host is up (0.000099s latency).
Other addresses for localhost (not scanned): ::1

PORT     STATE SERVICE
8080/tcp open  http-proxy
|_attack_script: Shellshock vulnerability DETECTED!

Nmap done: 1 IP address (1 host up) scanned in 0.09 seconds
```

---

#### Что произошло?

Уязвимость Shellshock в Bash на сервере. 

1. Веб-сервер обрабатывает CGI-скрипты, передавая им HTTP-заголовки как переменные окружения.
2. Заголовое User-Agent преобразуется в переменную окружения ```HTTP_USER_AGENT.```
3. В уязвимых версиях Bash, если значение переменной начинается с ```() {```, Bash интерпретирует его как определение функции. Ошибка заключалась в том, что после определения функции Bash также выполнял любые команды, следующие после ```}``` в том же значении переменной окружения.
4. Следовательно, Bash выполнил часть с ```echo VULNERABLE``` из переменной окружения.
