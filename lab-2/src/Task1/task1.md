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
nuclei -u http://localhost:8080 -t shellshock_nuclei.yaml # можно --debug для большей информативности
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
[INF] Current nuclei version: v3.7.1 (latest)
[INF] Current nuclei-templates version: v10.4.2 (latest)
[INF] New templates added in latest release: 121
[INF] Templates loaded for current scan: 1
[WRN] Loading 1 unsigned templates for scan. Use with caution.
[INF] Targets loaded for current scan: 1
[shellshock-vulnerability-nuclei] [http] [critical] http://localhost:8080/cgi-bin/vulnerable
[INF] Scan completed in 41.617959ms. 1 matches found.
```

---

#### Что произошло?

Уязвимость Shellshock в Bash на сервере. 

1. Веб-сервер обрабатывает CGI-скрипты, передавая им HTTP-заголовки как переменные окружения.
2. Заголовое User-Agent преобразуется в переменную окружения ```HTTP_USER_AGENT.```
3. В уязвимых версиях Bash, если значение переменной начинается с ```() {```, Bash интерпретирует его как определение функции. Ошибка заключалась в том, что после определения функции Bash также выполнял любые команды, следующие после ```}``` в том же значении переменной окружения.
4. Следовательно, Bash выполнил часть с ```echo {{rand}} SHELLSHOCK VULNERABILITY NUCLEI``` из переменной окружения. Рандом позволяет получать каждый раз разное значение (полезная загрузка не влияет на результат) и каждый раз убеждаться в корректности атаки.
