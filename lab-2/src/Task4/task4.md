#### Анализ nuclei-шаблона

---

Представлен шаблон. Необходимо понять, как он работает

---

#### Документация

```yaml
id: airflow-api-default-login # id шаблона

# Блок метаинформации
info:
  name: Apache Airflow API - Default Logins # Название
  author: Pavel Parkhomets # Автор
  severity: critical # Критичность при нахождении уязвимости
  tags: api,airflow,default-login,brute-force # теги (возможно, для кластеризации или оптимизаций)

requests: # описание HTTP-запросов
  - method: GET # GET-запрос
    path:
      - "{{BaseURL}}/api/v1/dags" # переменная {{BaseURL}} подставляется из источника (из файла или через CLI)

    # Заголовки запросов
    headers:
      Authorization: "Basic {{base64(username + ':' + password)}}" # аутентификация: логин и пароль в base64
      Content-Type: application/json

    # значения для brute-force
    payloads:
      username: # логин
        - "airflow"
        - "admin"
      password: # пароль
        - "airflow"
        - "admin"

    attack: clusterbomb # декартово произвдение комбинаций (2 x 2 = 4)

    matchers-condition: and # мэтч, когда оба условия выполнены

    matchers: # мэтчеры
      - type: word # ищем успешный ключ в API-ответе
        words:
          - "dag_id" # ключ json, который присутствует в ответе при успешной аутентификации
        part: body # ищем в теле ответа

      - type: word # второй матчер
        words:
          - "-kafka_server_socketservermetrics_successful_reauthentication_rate" # ключ
        part: body # в теле ответа
        negative: true # выполнено, если в теле ответа нет строки 

    stop-at-first-match: true # остановить перебор при первом мэтче
```