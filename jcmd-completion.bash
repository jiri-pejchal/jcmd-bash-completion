#!/bin/bash

# Bash completion script for jcmd

_jcmd_completion() {
    local cur prev pid commands processes pids main_class_last_parts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # Cache the output of jcmd to avoid redundant calls
    if [[ -z "${_JCMD_PROCESSES_CACHE}" ]]; then
        mapfile -t _JCMD_PROCESSES_CACHE < <(jcmd | awk '$2 != "jdk.jcmd/sun.tools.jcmd.JCmd" {print $1, $2}')
    fi
    processes=("${_JCMD_PROCESSES_CACHE[@]}")

    # If at the first argument, complete with PIDs or main class names initially
    if [[ ${COMP_CWORD} -eq 1 ]]; then
        if [[ -n "${cur}" ]]; then
            # Extract the last part of the main class name only if the current input is not empty
            main_class_last_parts=()
            for process in "${processes[@]}"; do
                main_class=$(echo "${process}" | awk '{print $2}')
                last_part=$(echo "${main_class}" | awk -F. '{print $NF}')
                main_class_last_parts+=("${last_part}")
            done

            # Combine PIDs, full main class names, and last parts of main class names for completion
            COMPREPLY=( $(compgen -W "${processes[*]} ${main_class_last_parts[*]}" -- "${cur}") )
        else
            # Complete with only PIDs and full main class names
            COMPREPLY=( $(compgen -W "${processes[*]}" -- "${cur}") )
        fi
        return 0
    fi

    # Determine the target for jcmd (PID or main class)
    local target="${COMP_WORDS[1]}"

    # Function to get available commands for a given PID
    get_commands_for_pid() {
        local pid=$1
        jcmd "${pid}" help 2>/dev/null | awk '
            /The following commands are available:/ {flag=1; next}
            /For more information/ {flag=0}
            flag {print $1}
        '
    }

    # If at the second argument, complete with commands for the given PID or main class
    if [[ ${COMP_CWORD} -eq 2 ]]; then
        if [[ ${target} =~ ^[0-9]+$ ]]; then
            # Get available commands for the given PID
            mapfile -t commands < <(get_commands_for_pid "${target}")
        else
            # Get PIDs for the given main class or last part of the main class, excluding jcmd itself
            mapfile -t pids < <(jcmd | awk -v tgt="$target" '$2 == tgt || $2 ~ "\\." tgt "$" && $2 != "jdk.jcmd/sun.tools.jcmd.JCmd" {print $1}')
            commands=()
            for pid in "${pids[@]}"; do
                mapfile -t pid_commands < <(get_commands_for_pid "${pid}")
                commands+=("${pid_commands[@]}")
            done
            commands=($(printf "%s\n" "${commands[@]}" | sort -u))
        fi
        COMPREPLY=( $(compgen -W "${commands[*]}" -- "${cur}") )
        return 0
    fi

    # Delegate completion to the specific command handler if applicable
    if [[ ${COMP_CWORD} -ge 3 ]]; then
        if type "_jcmd_complete_${COMP_WORDS[2]}" &>/dev/null; then
            "_jcmd_complete_${COMP_WORDS[2]}"
            return 0
        fi
    fi

    # If at the third argument and the second argument is `help`, complete with commands excluding `help`
    if [[ ${COMP_CWORD} -eq 3 && ${COMP_WORDS[2]} == "help" ]]; then
        if [[ ${target} =~ ^[0-9]+$ ]]; then
            # Get available commands for the given PID
            mapfile -t commands < <(get_commands_for_pid "${target}" | awk '$1 != "help" {print $1}')
        else
            # Get PIDs for the given main class, excluding jcmd itself
            mapfile -t pids < <(jcmd | awk -v tgt="$target" '$2 == tgt || $2 ~ "\\." tgt "$" && $2 != "jdk.jcmd/sun.tools.jcmd.JCmd" {print $1}')
            commands=()
            for pid in "${pids[@]}"; do
                mapfile -t pid_commands < <(get_commands_for_pid "${pid}" | awk '$1 != "help" {print $1}')
                commands+=("${pid_commands[@]}")
            done
            commands=($(printf "%s\n" "${commands[@]}" | sort -u))
        fi
        COMPREPLY=( $(compgen -W "${commands[*]}" -- "${cur}") )
        return 0
    fi

    # Default completion (beyond third argument) does not have further completion
    if [[ ${COMP_CWORD} -gt 3 ]]; then
        return 0
    fi
}

# Handler for specific jcmd command "GC.heap_dump"
_jcmd_complete_GC.heap_dump() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local heap_dump_options="-all -gz= -overwrite -parallel="
    # Collect the options that have already been used
    local used_options=()
    for ((i = 3; i < ${COMP_CWORD}; i++)); do
        if [[ "${COMP_WORDS[i]}" == -* ]]; then
            used_options+=("${COMP_WORDS[i]%%=*}")
        fi
    done

    # Filter out used options to avoid suggesting them again
    local available_options=""
    for option in ${heap_dump_options}; do
        if [[ ! " ${used_options[@]} " =~ " ${option%%=*} " ]]; then
            available_options+="${option} "
        fi
    done

    if [[ "${cur}" == -* ]]; then
        # If completing an option, suggest available options
        COMPREPLY=( $(compgen -W "${available_options}" -- "${cur}") )
    else
        # Otherwise, suggest file paths
        _filedir
    fi
}

# Register the completion function for the jcmd command
complete -F _jcmd_completion jcmd
