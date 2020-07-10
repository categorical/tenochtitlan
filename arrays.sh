#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
#source $IMPORTDIR/out.sh


# @param $1 array a
# @param $2 array b
# @param $3 intersection of a and b
function arrays::intersection(){
    [ "$#" -ge 3 ]||return 1

    local _a="$1[@]" _b="$2[@]"
    local -a _c
    for v in "${!_a}";do
        for w in "${!_b}";do
            if [ "$v" == "$w" ];then
                _c+=("$v")
                break
            fi
        done
    done
    eval "$3=("'"${_c[@]}")'
}

# @param $1 array a
# @param $2 array b
# @param $3 a\b
function arrays::difference(){
    [ "$#" -ge 3 ]||return 1

    local _a="$1[@]" _b="$2[@]"
    local -a _c

    for v in "${!_a}";do
        for w in "${!_b}";do
            if [ "$v" == "$w" ];then
                continue 2
            fi
        done
        _c+=($v)
    done
    eval "$3=("'"${_c[@]}")'
}

# @param $1
function arrays::removeduplicatestrings(){
    [ "$#" -gt 0 ]||return 1
    
    local _a="$1[@]"
    local -a _b
    for v in "${!_a}";do
        for w in "${_b[@]}";do
            if [ "$v" == "$w" ];then
                continue 2
            fi
        done
        _b+=("$v")
    done
    eval "$1=("'"${_b[@]}")'   
}

# @param $1
function arrays::removeemptystrings(){
    [ "$#" -gt 0 ]||return 1

    local _a="$1[@]"
    local -a _b
    for v in "${!_a}";do
        [ -z "$v" ]||_b+=("$v")
    done
    eval "$1=("'"${_b[@]}")'   
}

# @param $1 array
# @param $2 element
function arrays::contains(){
    [ "$#" -gt 1 ]||return 1

    local _a="$1[@]"
    for _v in "${!_a}";do
        [ "$_v" != "$2" ]||return 0
    done
    return 1
}

# @param $1 array
# @param $2 element
function arrays::remove(){
    [ "$#" -gt 1 ]||return 1

    local _a="$1[@]"
    local -a _b=("${!_a}")
    
    local _altered
    for i in "${!_b[@]}";do
        if [ "${_b[i]}" == "$2" ];then
            unset '_b[i]';_altered='t'
            break 
        fi
    done
    [ "$_altered" == 't' ]||return 1

    eval "$1=("'"${_b[@]}")'
}

# @param $1 array
# @param $2 element
function arrays::indexof(){
    [ "$#" -gt 1 ]||return 1
 
    local _a="$1[@]"
    local -a _b
    eval "$(cat <<EOF
    for i in "\${!${_a}}";do
        _b[i]="\${$1[i]}"
    done
EOF)"
    for i in "${!_b[@]}";do
        if [ "$2" == "${_b[i]}" ];then
            printf '%d' "$i"
            return
        fi
    done
    printf '%d' '-1'
}



