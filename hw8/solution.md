# Homework 8: systemd

## Task

* Create a service that checks log for certain keyword every 30s
* Install spawn-fcgi and create systemd unit `spawn-fcgi.service`
* Modify `nginx.service`: enable starting several instances of server with different config files

## Prerequisites

OS: **Ubuntu 24.04**

## Solution

### 1. Add monitoring unit

Create watchlog conf and test log file with keyword (**ALERT**) in it

```sh
❯ cat /etc/default/watchlog

WORD="ALERT"
LOG="/var/log/watchlog.log"
```

```sh
❯ cat /var/log/watchlog.log

INFO aaaaa
INFO bbbbb
ALERT wtf help
WARNING aaaa
```

Create watchdog script

```sh
❯ cat /opt/watchlog.sh

#!/bin/bash

WORD=$1
LOG=$2
DATE=`date`

if grep $WORD $LOG &> /dev/null
then
logger "$DATE: ALERT FOUND! WE WILL DIE!!!"
else
exit 0
fi

❯ sudo chmod +x /opt/watchlog.sh
```

Create service and timer systemd units

```sh
❯ cat /etc/systemd/system/watchlog.service
[Unit]
Description=Ultra alert watcher

[Service]
Type=oneshot
EnvironmentFile=/etc/default/watchlog
ExecStart=/opt/watchlog.sh $WORD $LOG

❯ cat /etc/systemd/system/watchlog.timer
[Unit]
Description=Run ultra alert watcher every 30 second

[Timer]
OnUnitActiveSec=30
OnActiveSec=5s
Unit=watchlog.service

[Install]
WantedBy=multi-user.target
```

Start timer service and watch `watchlog.service` realtime logs

```sh
❯ sudo systemctl start watchlog.timer
❯ sudo journalctl -u watchlog.service -f

Sep 12 18:30:08 giveuperPC systemd[1]: Starting watchlog.service - Ultra alert watcher...
Sep 12 18:30:08 giveuperPC root[31102]: Sat Sep 12 18:30:08 MSK 2026: ALERT FOUND! WE WILL DIE!!!
Sep 12 18:30:08 giveuperPC systemd[1]: watchlog.service: Deactivated successfully.
Sep 12 18:30:08 giveuperPC systemd[1]: Finished watchlog.service - Ultra alert watcher.
Sep 12 18:30:38 giveuperPC systemd[1]: Starting watchlog.service - Ultra alert watcher...
Sep 12 18:30:38 giveuperPC root[31273]: Sat Sep 12 18:30:38 MSK 2026: ALERT FOUND! WE WILL DIE!!!
Sep 12 18:30:38 giveuperPC systemd[1]: watchlog.service: Deactivated successfully.
Sep 12 18:30:38 giveuperPC systemd[1]: Finished watchlog.service - Ultra alert watcher.
Sep 12 18:31:08 giveuperPC systemd[1]: Starting watchlog.service - Ultra alert watcher...
Sep 12 18:31:08 giveuperPC root[31452]: Sat Sep 12 18:31:08 MSK 2026: ALERT FOUND! WE WILL DIE!!!
Sep 12 18:31:08 giveuperPC systemd[1]: watchlog.service: Deactivated successfully.
Sep 12 18:31:08 giveuperPC systemd[1]: Finished watchlog.service - Ultra alert watcher.
Sep 12 18:31:38 giveuperPC systemd[1]: Starting watchlog.service - Ultra alert watcher...
Sep 12 18:31:38 giveuperPC root[31642]: Sat Sep 12 18:31:38 MSK 2026: ALERT FOUND! WE WILL DIE!!!
Sep 12 18:31:38 giveuperPC systemd[1]: watchlog.service: Deactivated successfully.
Sep 12 18:31:38 giveuperPC systemd[1]: Finished watchlog.service - Ultra alert watcher.
```

### 2. spawn-fcgi

Install dependencies and spawn-fcgi itself

```sh
❯ sudo apt install spawn-fcgi php php-cgi php-cli apache2 libapache2-mod-fcgid -y
```

Create spawn-fcgi config and unit file

```sh
❯ cat /etc/spawn-fcgi/fcgi.conf
SOCKET=/var/run/php-fcgi.sock
OPTIONS="-u www-data -g www-data -s $SOCKET -S -M 0600 -C 32 -F 1 -- /usr/bin/php-cgi"

❯ cat /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by me
After=network.target

[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/spawn-fcgi/fcgi.conf
ExecStart=/usr/bin/spawn-fcgi -n $OPTIONS
KillMode=process

[Install]
WantedBy=multi-user.target
```

Validate it works

```sh
❯ sudo systemctl daemon-reload && sudo systemctl start spawn-fcgi
❯ sudo systemctl status spawn-fcgi.service
● spawn-fcgi.service - Spawn-fcgi startup service by me
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; preset: enabled)
     Active: active (running) since Sat 2026-09-12 18:47:05 MSK; 1min 37s ago
   Main PID: 46003 (php-cgi)
      Tasks: 33 (limit: 19130)
     Memory: 14.4M (peak: 15.6M)
        CPU: 29ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─46003 /usr/bin/php-cgi
             ├─46007 /usr/bin/php-cgi
             ├─46008 /usr/bin/php-cgi
             ├─46009 /usr/bin/php-cgi
             ├─46010 /usr/bin/php-cgi
             ├─46011 /usr/bin/php-cgi
             ├─46012 /usr/bin/php-cgi
             ├─46013 /usr/bin/php-cgi
             ├─46014 /usr/bin/php-cgi
             ├─46015 /usr/bin/php-cgi
             ├─46016 /usr/bin/php-cgi
             ├─46017 /usr/bin/php-cgi
             ├─46018 /usr/bin/php-cgi
             ├─46019 /usr/bin/php-cgi
             ├─46020 /usr/bin/php-cgi
             ├─46021 /usr/bin/php-cgi
             ├─46022 /usr/bin/php-cgi
             ├─46023 /usr/bin/php-cgi
             ├─46024 /usr/bin/php-cgi
             ├─46025 /usr/bin/php-cgi
             ├─46026 /usr/bin/php-cgi
             ├─46027 /usr/bin/php-cgi
             ├─46028 /usr/bin/php-cgi
             ├─46029 /usr/bin/php-cgi
             ├─46030 /usr/bin/php-cgi
             ├─46031 /usr/bin/php-cgi
             ├─46032 /usr/bin/php-cgi
             ├─46033 /usr/bin/php-cgi
             ├─46034 /usr/bin/php-cgi
             ├─46035 /usr/bin/php-cgi
             ├─46036 /usr/bin/php-cgi
             ├─46037 /usr/bin/php-cgi
             └─46038 /usr/bin/php-cgi

Sep 12 18:47:05 giveuperPC systemd[1]: Started spawn-fcgi.service - Spawn-fcgi startup service by me.
```

### 3. Modify nginx unit

After installation create new custom nginx service file

```sh
❯ cat /etc/systemd/system/nginx@.service -p
[Unit]
Description=A high performance web server and a reverse proxy server
Documentation=man:nginx(8)
After=network.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx-%I.pid
ExecStartPre=/usr/sbin/nginx -t -c /etc/nginx/nginx-%I.conf -q -g 'daemon on; master_process on;'
ExecStart=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;'
ExecReload=/usr/sbin/nginx -c /etc/nginx/nginx-%I.conf -g 'daemon on; master_process on;' -s reload
ExecStop=-/sbin/start-stop-daemon --quiet --stop --retry QUIT/5 --pidfile /run/nginx-%I.pid
TimeoutStopSec=5
KillMode=mixed

[Install]
WantedBy=multi-user.target
```

Then create two config files with different pids and ports (copied from `nginx.conf`, only printed diff)

```sh
❯ diff /etc/nginx/nginx-first.conf /etc/nginx/nginx.conf
3c3
< pid /run/nginx-first.pid;
---
> pid /run/nginx.pid;
59,63c59,60
<       # include /etc/nginx/conf.d/*.conf;
<       # include /etc/nginx/sites-enabled/*;
<       server {
<               listen 9001;
<       }
---
>       include /etc/nginx/conf.d/*.conf;
>       include /etc/nginx/sites-enabled/*;
❯ diff /etc/nginx/nginx-second.conf /etc/nginx/nginx.conf
3c3
< pid /run/nginx-second.pid;
---
> pid /run/nginx.pid;
59,63c59,60
<       # include /etc/nginx/conf.d/*.conf;
<       # include /etc/nginx/sites-enabled/*;
<       server {
<               listen 9002;
<       }
---
>       include /etc/nginx/conf.d/*.conf;
>       include /etc/nginx/sites-enabled/*;
```

Then run them and validate they have different pids and ports

```sh
❯ sudo systemctl start nginx@first
❯ sudo systemctl start nginx@second

❯ ps afx | grep nginx
...
  52511 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-first.conf -g daemon on; master_process on;
  52512 ?        S      0:00  \_ nginx: worker process
  52513 ?        S      0:00  \_ nginx: worker process
  52514 ?        S      0:00  \_ nginx: worker process
  52515 ?        S      0:00  \_ nginx: worker process
  52516 ?        S      0:00  \_ nginx: worker process
  52517 ?        S      0:00  \_ nginx: worker process
  52519 ?        S      0:00  \_ nginx: worker process
  52520 ?        S      0:00  \_ nginx: worker process
  52521 ?        S      0:00  \_ nginx: worker process
  52522 ?        S      0:00  \_ nginx: worker process
  52523 ?        S      0:00  \_ nginx: worker process
  52524 ?        S      0:00  \_ nginx: worker process
  52532 ?        Ss     0:00 nginx: master process /usr/sbin/nginx -c /etc/nginx/nginx-second.conf -g daemon on; master_process on;
  52533 ?        S      0:00  \_ nginx: worker process
  52534 ?        S      0:00  \_ nginx: worker process
  52535 ?        S      0:00  \_ nginx: worker process
  52537 ?        S      0:00  \_ nginx: worker process
  52538 ?        S      0:00  \_ nginx: worker process
  52539 ?        S      0:00  \_ nginx: worker process
  52540 ?        S      0:00  \_ nginx: worker process
  52541 ?        S      0:00  \_ nginx: worker process
  52542 ?        S      0:00  \_ nginx: worker process
  52543 ?        S      0:00  \_ nginx: worker process
  52544 ?        S      0:00  \_ nginx: worker process
  52545 ?        S      0:00  \_ nginx: worker process
...

❯ sudo ss -tulnp
...
tcp             LISTEN           0                511                               0.0.0.0:9001                          0.0.0.0:*              users:(("nginx",pid=52524,fd=5),("nginx",pid=52523,fd=5),("nginx",pid=52522,fd=5),("nginx",pid=52521,fd=5),("nginx",pid=52520,fd=5),("nginx",pid=52519,fd=5),("nginx",pid=52517,fd=5),("nginx",pid=52516,fd=5),("nginx",pid=52515,fd=5),("nginx",pid=52514,fd=5),("nginx",pid=52513,fd=5),("nginx",pid=52512,fd=5),("nginx",pid=52511,fd=5))
tcp             LISTEN           0                511                               0.0.0.0:9002                          0.0.0.0:*              users:(("nginx",pid=52545,fd=5),("nginx",pid=52544,fd=5),("nginx",pid=52543,fd=5),("nginx",pid=52542,fd=5),("nginx",pid=52541,fd=5),("nginx",pid=52540,fd=5),("nginx",pid=52539,fd=5),("nginx",pid=52538,fd=5),("nginx",pid=52537,fd=5),("nginx",pid=52535,fd=5),("nginx",pid=52534,fd=5),("nginx",pid=52533,fd=5),("nginx",pid=52532,fd=5))
...
```
