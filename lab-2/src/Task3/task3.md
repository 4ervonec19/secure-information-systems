#### Перебор УЗ к SSH

---

В данном задании необходимо просканировать ```SSH-серверы``` на предмет уязвимости перебора учётных данных ```(brute force).``` Требуется создать шаблон, который будет отправлять запросы на основе комбинаций логинов и паролей, анализировать ответы на успешность входа. Критичность – ```High.```

---

#### Шаги реализации

1. Запуск докер-контейнеров с уязвимыми тестовыми средами

```bash
docker run -d -p 2222:22 --name ssh-test rastasheep/ubuntu-sshd
```

2. Создание шаблона ```nuclei:``` ```ssh_brute_force_nuclei.yaml.```

3. Запуск 

```bash
# src/Task3/ssh_brute_force_nuclei.yaml
nuclei -u localhost:2222 -t ssh_brute_force_nuclei.yaml -debug # можно --debug для большей информативности
```

4. Результат:

```bash

                     __     _
   ____  __  _______/ /__  (_)
  / __ \/ / / / ___/ / _ \/ /
 / / / / /_/ / /__/ /  __/ /
/_/ /_/\__,_/\___/_/\___/_/   v3.7.1

                projectdiscovery.io

[INF] Current nuclei version: v3.7.1 (latest)
[INF] Current nuclei-templates version: v10.4.2 (latest)
[INF] New templates added in latest release: 121
[INF] Templates loaded for current scan: 1
[WRN] Loading 1 unsigned templates for scan. Use with caution.
[INF] Targets loaded for current scan: 1
[ssh-brute-force] [javascript] [high] localhost:2222 [pass="root",user="root"]
[INF] Scan completed in 143.3995ms. 1 matches found.
```

---

#### Что произошло?

Запуск шаблона перебрал пароли, использую ```JS-Script``` и логин ```root``` + пароль ```root``` дал финальный результат и мэтч с требованиями.