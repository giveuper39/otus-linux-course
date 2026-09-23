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