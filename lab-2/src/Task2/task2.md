#### Детектирование заголовков с помощью Nuclei

--- 

В данном задании необходимо получить шаблон ```nuclei``` для анализа типа веб-сервера ```(Apache или Nginx).``` Шаблон должен отправлять запрос к целевому хосту, на основании ответа детектировать веб-сервер. Критичность шаблона – ```Info.```

---

#### Шаги реализации

1. Запуск докер-контейнеров с уязвимыми тестовыми средами

```bash
docker run -d -p 8082:80 --name apache-test httpd # Apache server
docker run -d -p 8081:80 --name nginx-test nginx # Nginx server
```

2. Создание шаблона ```nuclei:``` ```nginx_apache_nuclei.yaml.```

3. Запуск команд:
```bash
# src/Task2/nginx_apache_nuclei.yaml
nuclei -u http://localhost:8081 -t nginx_apache_nuclei.yaml # nginx
nuclei -u http://localhost:8082 -t nginx_apache_nuclei.yaml # apache
```

4. Результаты:

+ Для ```nginx:```

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
[nginx-apache-nuclei] [http] [info] http://localhost:8081/
[INF] Scan completed in 4.532667ms. 1 matches found.
```

При ```--debug:```

```bash
HTTP/1.1 200 OK
Connection: close
Content-Length: 896
Accept-Ranges: bytes
Content-Type: text/html
Date: Fri, 17 Apr 2026 12:11:37 GMT
Etag: "69d4ec68-380"
Last-Modified: Tue, 07 Apr 2026 11:37:12 GMT
Server: nginx/1.29.8

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

+ Для ```apache:```

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
[nginx-apache-nuclei] [http] [info] http://localhost:8082/
[INF] Scan completed in 11.409833ms. 1 matches found.
```

При ```--debug:```

```bash
HTTP/1.1 200 OK
Connection: close
Content-Length: 191
Accept-Ranges: bytes
Content-Type: text/html
Date: Fri, 17 Apr 2026 12:13:40 GMT
Etag: "bf-642fce432f300"
Last-Modified: Fri, 07 Nov 2025 08:23:08 GMT
Server: Apache/2.4.66 (Unix)

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>
```

--- 

#### Что произошло?

Запуск шаблона отправил тестовый запрос на указанные URL, и ответы серверов содержали заголовки `Server: Apache/2.4.66 (Unix)` и ```Server: nginx/1.29.8```. Шаблон успешно извлёк информацию.

