# Homework 10: process management (option 2 - lsof)

## Task

Create a script, which prints open files of the processes (using /proc) 

## Prerequisites

OS: **Ubuntu 24.04**

## Solution

### 1. Start a test process

Create a script, that opens the file in 3rd descriptor and leaves it like that for 300 seconds

```sh
❯ cat test_open_file.sh

#!/bin/bash
FILE="/tmp/lsof_test.txt"
echo "Test process PID: $$"
echo "Opened file: $FILE"
exec 3>>"$FILE"
echo "Process $$ started" >&3
sleep 300

❯ chmod +x test_open_file.sh
❯ touch /tmp/lsof_test.txt
```

Run in in the background

```sh
❯ bash test_open_file.sh &
[1] 4708
Test process PID: 4708
Opened file: /tmp/lsof_test.txt
```

### 2. Check where is the process fd info stored

```bash
❯ cd /proc/4708
❯ sudo -s
root@giveuperPC:/proc/4708# cd fd
root@giveuperPC:/proc/4708/fd# ls -la
total 0
dr-x------ 2 giveuper39 giveuper39  5 Sep 23 18:40 .
dr-xr-xr-x 9 giveuper39 giveuper39  0 Sep 23 18:40 ..
lrwx------ 1 giveuper39 giveuper39 64 Sep 23 18:43 0 -> /dev/pts/0
lrwx------ 1 giveuper39 giveuper39 64 Sep 23 18:43 1 -> /dev/pts/0
lrwx------ 1 giveuper39 giveuper39 64 Sep 23 18:43 2 -> /dev/pts/0
lr-x------ 1 giveuper39 giveuper39 64 Sep 23 18:43 255 -> /home/giveuper39/test_open_file.sh
l-wx------ 1 giveuper39 giveuper39 64 Sep 23 18:43 3 -> /tmp/lsof_test.txt
```

We see that fd=3 is the file we opened and others are stdin(0), stdout(1) and stderr(2). 255 is our bash script file.

Knowing all this info we could write our lsof-like script, calling it lsof2

### 3. Writing and testing lsof2

We can start with the easiest script - just checks all processes and all open fds using /proc/*/fd/

```bash
❯ cat lsof2.sh -p

#!/bin/bash

printf "%-8s %-25s %s\n" "PID" "PROCESS" "OPEN FILE"
printf "%-8s %-25s %s\n" "--------" "-------------------------" "------------------------------"

for proc_dir in /proc/[0-9]*; do
    pid=${proc_dir##*/}
    [[ -r "$proc_dir/comm" ]] || continue   # to read process name
    [[ -d "$proc_dir/fd" ]] || continue # if process has open descriptors
    process_name=$(cat "$proc_dir/comm" 2>/dev/null) || continue
    for fd in "$proc_dir"/fd/*; do
        [[ -e "$fd" || -L "$fd" ]] || continue  # if file exists or symlink exists
        file=$(readlink "$fd" 2>/dev/null) || continue
        printf "%-8s %-25s %s\n" "$pid" "$process_name" "$file"
    done
done

❯ chmod +x lsof2.sh
```

Test it:

```sh
❯ ./lsof2.sh
PID      PROCESS                   OPEN FILE
-------- ------------------------- ------------------------------
10655    lsof2.sh                  /dev/pts/0
10655    lsof2.sh                  /dev/pts/0
10655    lsof2.sh                  /dev/pts/0
10655    lsof2.sh                  /home/giveuper39/lsof2.sh
1203     gunicorn                  /dev/null
1203     gunicorn                  pipe:[8607]
1203     gunicorn                  pipe:[8608]
1203     gunicorn                  pipe:[1707]
1203     gunicorn                  pipe:[1707]
1203     gunicorn                  socket:[1708]
1203     gunicorn                  /tmp/wgunicorn-5xgfo8gx (deleted)
1203     gunicorn                  /tmp/wgunicorn-gj0b2i6n (deleted)
1445     gunicorn                  /dev/null
1445     gunicorn                  pipe:[8607]
1445     gunicorn                  pipe:[8608]
1445     gunicorn                  pipe:[1707]
1445     gunicorn                  pipe:[1707]
1445     gunicorn                  socket:[1708]
1445     gunicorn                  /tmp/wgunicorn-5xgfo8gx (deleted)
1445     gunicorn                  pipe:[11922]
1445     gunicorn                  pipe:[11922]
1451     gunicorn                  /dev/null
1451     gunicorn                  pipe:[8607]
1451     gunicorn                  pipe:[8608]
1451     gunicorn                  pipe:[1707]
1451     gunicorn                  pipe:[1707]
1451     gunicorn                  socket:[1708]
1451     gunicorn                  pipe:[6918]
1451     gunicorn                  /tmp/wgunicorn-gj0b2i6n (deleted)
1451     gunicorn                  pipe:[6918]
1531     zsh                       /dev/pts/0
1531     zsh                       /dev/pts/0
1531     zsh                       /dev/pts/0
1531     zsh                       /tmp/gitstatus.POWERLEVEL9K.1000.1531.1790177539.1.fifo (deleted)
1531     zsh                       /usr/share/zsh/functions/Completion.zwc
1531     zsh                       /tmp/p10k.worker.1000.1531.1790177539.fifo (deleted)
1531     zsh                       /usr/share/zsh/functions/Completion/Base.zwc
1531     zsh                       /usr/share/zsh/functions/Zle.zwc
1531     zsh                       pipe:[1010]
1531     zsh                       pipe:[978]
1531     zsh                       /dev/pts/0
1531     zsh                       /usr/share/zsh/functions/Misc.zwc
1531     zsh                       /usr/share/zsh/functions/Completion/Zsh.zwc
1531     zsh                       /usr/share/zsh/functions/Completion/Unix.zwc
1617     zsh                       /tmp/gitstatus.POWERLEVEL9K.1000.1531.1790177539.1.fifo (deleted)
1617     zsh                       /dev/null
1617     zsh                       pipe:[978]
1617     zsh                       /dev/pts/0
1617     zsh                       /dev/pts/0
1617     zsh                       /dev/pts/0
1617     zsh                       /dev/null
1755     zsh                       /dev/pts/1
1755     zsh                       /dev/pts/1
1755     zsh                       /dev/pts/1
1755     zsh                       /home/giveuper39/.zshrc
1755     zsh                       /usr/share/zsh/functions/Completion.zwc
1755     zsh                       /home/giveuper39/.oh-my-zsh/oh-my-zsh.sh
1755     zsh                       /usr/share/zsh/functions/Completion/Base.zwc
1755     zsh                       /home/giveuper39/.oh-my-zsh/tools/check_for_upgrade.sh
1755     zsh                       /dev/pts/1
1856     zsh                       /tmp/p10k.worker.1000.1531.1790177539.fifo (deleted)
1856     zsh                       pipe:[1010]
1856     zsh                       /dev/tty
1856     zsh                       /dev/pts/0
1856     zsh                       /dev/pts/0
1856     zsh                       /dev/pts/0
1856     zsh                       pipe:[978]
1856     zsh                       /dev/null
1857     zsh                       /dev/null
1857     zsh                       pipe:[1010]
1857     zsh                       /dev/tty
1857     zsh                       /dev/pts/0
1857     zsh                       /dev/pts/0
1857     zsh                       /dev/pts/0
1857     zsh                       pipe:[978]
1857     zsh                       /dev/null
1859     gitstatusd-linu           /tmp/gitstatus.POWERLEVEL9K.1000.1531.1790177539.1.fifo (deleted)
1859     gitstatusd-linu           pipe:[978]
1859     gitstatusd-linu           pipe:[978]
1859     gitstatusd-linu           /dev/pts/0
1859     gitstatusd-linu           /dev/pts/0
1859     gitstatusd-linu           /dev/pts/0
1859     gitstatusd-linu           /dev/null
```

Here we can see two ways to upgrade it:

1. stdin, stdout, stderr descriptors - nearly all processes have them, so we want to have a way to remove them from output
2. Sometimes we need to see fd open mode - **r**, **w**, **rw** via `/proc/<PID>/fdinfo/<FD>`

Let's implement it in the final version.

```sh
❯ cat lsof2.sh -pp

#!/bin/bash

NO_STDIO=false

if [[ "$1" == "-n" ]]; then
    NO_STDIO=true
fi


printf "%-8s %-25s %-5s %-6s %s\n" \
    "PID" "PROCESS" "FD" "MODE" "OPEN FILE"

printf "%-8s %-25s %-5s %-6s %s\n" \
    "--------" "-------------------------" "-----" "------" "------------------------------"


for proc_dir in /proc/[0-9]*; do
    pid=${proc_dir##*/}

    [[ -r "$proc_dir/comm" ]] || continue
    [[ -d "$proc_dir/fd" ]] || continue

    process_name=$(cat "$proc_dir/comm" 2>/dev/null) || continue

    for fd_path in "$proc_dir"/fd/*; do
        [[ -e "$fd_path" || -L "$fd_path" ]] || continue

        fd=${fd_path##*/}

        if [[ "$NO_STDIO" == true && "$fd" =~ ^[012]$ ]]; then
            continue
        fi

        file=$(readlink "$fd_path" 2>/dev/null) || continue

        flags=$(awk '/^flags:/ {print $2}' \
            "$proc_dir/fdinfo/$fd" 2>/dev/null)

        mode="?"

        if [[ -n "$flags" ]]; then
            access_mode=$((8#$flags & 3))

            case "$access_mode" in
                0) mode="r" ;;
                1) mode="w" ;;
                2) mode="rw" ;;
            esac
        fi

        printf "%-8s %-25s %-5s %-6s %s\n" \
            "$pid" "$process_name" "$fd" "$mode" "$file"
    done
done
```

And test again:

```sh
❯ bash test_open_file.sh &
[1] 19907
Test process PID: 19907
Opened file: /tmp/lsof_test.txt

❯ ./lsof2.sh -n
PID      PROCESS                   FD    MODE   OPEN FILE
-------- ------------------------- ----- ------ ------------------------------
1203     gunicorn                  3     r      pipe:[1707]
1203     gunicorn                  4     w      pipe:[1707]
1203     gunicorn                  5     rw     socket:[1708]
1203     gunicorn                  6     rw     /tmp/wgunicorn-5xgfo8gx (deleted)
1203     gunicorn                  7     rw     /tmp/wgunicorn-gj0b2i6n (deleted)
1445     gunicorn                  3     r      pipe:[1707]
1445     gunicorn                  4     w      pipe:[1707]
1445     gunicorn                  5     rw     socket:[1708]
1445     gunicorn                  6     rw     /tmp/wgunicorn-5xgfo8gx (deleted)
1445     gunicorn                  7     r      pipe:[11922]
1445     gunicorn                  8     w      pipe:[11922]
1451     gunicorn                  3     r      pipe:[1707]
1451     gunicorn                  4     w      pipe:[1707]
1451     gunicorn                  5     rw     socket:[1708]
1451     gunicorn                  6     r      pipe:[6918]
1451     gunicorn                  7     rw     /tmp/wgunicorn-gj0b2i6n (deleted)
1451     gunicorn                  8     w      pipe:[6918]
1531     zsh                       10    rw     /dev/pts/0
1531     zsh                       11    w      /tmp/gitstatus.POWERLEVEL9K.1000.1531.1790177539.1.fifo (deleted)
1531     zsh                       12    r      /usr/share/zsh/functions/Completion.zwc
1531     zsh                       13    w      /tmp/p10k.worker.1000.1531.1790177539.fifo (deleted)
1531     zsh                       14    r      /usr/share/zsh/functions/Completion/Base.zwc
1531     zsh                       17    r      /usr/share/zsh/functions/Zle.zwc
1531     zsh                       18    r      pipe:[1010]
1531     zsh                       19    r      pipe:[978]
1531     zsh                       20    r      /usr/share/zsh/functions/Misc.zwc
1531     zsh                       21    r      /usr/share/zsh/functions/Completion/Zsh.zwc
1531     zsh                       22    r      /usr/share/zsh/functions/Completion/Unix.zwc
1617     zsh                       11    w      pipe:[978]
1617     zsh                       15    rw     /dev/pts/0
1617     zsh                       16    rw     /dev/pts/0
1617     zsh                       17    rw     /dev/pts/0
1755     zsh                       10    rw     /dev/pts/1
1755     zsh                       11    r      /home/giveuper39/.zshrc
1755     zsh                       12    r      /usr/share/zsh/functions/Completion.zwc
1755     zsh                       13    r      /home/giveuper39/.oh-my-zsh/oh-my-zsh.sh
1755     zsh                       14    r      /usr/share/zsh/functions/Completion/Base.zwc
1755     zsh                       15    r      /home/giveuper39/.oh-my-zsh/tools/check_for_upgrade.sh
1856     zsh                       11    rw     /dev/tty
1856     zsh                       15    rw     /dev/pts/0
1856     zsh                       16    rw     /dev/pts/0
1856     zsh                       17    rw     /dev/pts/0
1856     zsh                       19    r      pipe:[978]
1857     zsh                       11    rw     /dev/tty
1857     zsh                       15    rw     /dev/pts/0
1857     zsh                       16    rw     /dev/pts/0
1857     zsh                       17    rw     /dev/pts/0
1857     zsh                       19    r      pipe:[978]
1859     gitstatusd-linu           11    w      pipe:[978]
1859     gitstatusd-linu           15    rw     /dev/pts/0
1859     gitstatusd-linu           16    rw     /dev/pts/0
1859     gitstatusd-linu           17    rw     /dev/pts/0
19907    bash                      255   r      /home/giveuper39/test_open_file.sh  # <-- here is our test script, opened .sh file in 'r'
19907    bash                      3     w      /tmp/lsof_test.txt  # <-- and txt in 'w'
19910    sleep                     3     w      /tmp/lsof_test.txt 
19914    lsof2.sh                  255   r      /home/giveuper39/lsof2.sh
```

Final version of the script is [here](lsof2.sh).
