#### Использование ```metasploit``` (шпаргалка по командам)

---


1. Запуск:
```bash
cd /opt/metasploit-framework/bin
./msfconsole
```

Полученный вывод:
```bash
Metasploit tip: Use check before run to confirm if a target is 
vulnerable
                                                  
Call trans opt: received. 2-19-98 13:24:18 REC:Loc

     Trace program: running

           wake up, Neo...
        the matrix has you
      follow the white rabbit.

          knock, knock, Neo.

                        (`.         ,-,
                        ` `.    ,;' /
                         `.  ,'/ .'
                          `. X /.'
                .-;--''--.._` ` (
              .'            /   `
             ,           ` '   Q '
             ,         ,   `._    \
          ,.|         '     `-.;_'
          :  . `  ;    `  ` --,.._;
           ' `    ,   )   .'
              `._ ,  '   /_
                 ; ,''-,;' ``-
                  ``-..__``--`

                             https://metasploit.com


       =[ metasploit v6.4.126-dev-4bacaee3e707a12fd7904ced6e3ca1c417abbc52]
+ -- --=[ 2,635 exploits - 1,330 auxiliary - 2,146 payloads     ]
+ -- --=[ 431 post - 49 encoders - 14 nops - 12 evasion         ]

Metasploit Documentation: https://docs.metasploit.com/
The Metasploit Framework is a Rapid7 Open Source Project

msf > 
```

2. Выполнение команд идёт классический образом: можно привычным образом работать с системой. Фреймворк ```metasploit``` активирует совокупноксть команд, которые недоступны в терминале.

3. Команда ```show:``` показывает модули, которые в данный момент есть в установленном фреймворке:

```bash
show -h
```

Вывод:
```bash
[*] Valid parameters for the "show" command are: all, encoders, nops, exploits, payloads, auxiliary, post, plugins, info, options, favorites
[*] Additional module-specific parameters are: missing, advanced, evasion, targets, actions
```

```bash
show exploits
show encoders
```

4. Команда ```search:``` поиск модулей по ключевым словам

5. Команда ```use:``` выбирает конкретный модуль (exploit, auxiliary, payload, encoder, post). После ввода use ```exploit/unix/...``` мы по сути переходим в модуль и можем выполнять команды для этого модуля `(run, exploit etc)`

6. Команда ```info:``` показывает подробную информацию о выбранном модуле: описание уязвимости, автора, подходящие платформы, ссылки (CVE, advisories), необходимые опции (RHOSTS, RPORT и т.д.), целевые системы, а также примечания. Используется после use.

7. Команда ```options:``` описывает параметры для выбранного модуля.

8. Команда ```set:``` присвоение значения параметру модуля.

9. Выбор полезной нагрузки `(payload):` после выбора эксплойта можно задать `payload,` который будет выполняться при успешной атаке.

10. Настройка параметров  `payload:` настроить порты, хосты, например. 

11. Команда `check:` проверить уязвимость.

12. Запустить эксплоит: `exploit` или `run.`

13. Можно работать с сессиями через `sessions.`

14. `Meterpreter` – для пост-эксплуатации.

---

#### Простой пример для понимания:

+ ```Auxiliary``` — сканер портов (подготовка).

+ `Exploit` – модуль `vsftpd_234_backdoor` (какой-то код, эксплуатирующий уязвимость).

+ `Payload` – `cmd/unix/reverse_netcat` (код, который выполнится на стороне жертвы и будет эксплуатировать уязвимость).

+ `Encoder` – может добавить обфускацию.

+ `Meterpreter` – для расширенной полезной нагрузки (альтернатива `reverse_netcat`) и пост-эксплуатация.

---