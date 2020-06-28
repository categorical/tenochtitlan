#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
#source $IMPORTDIR/out.sh


# @param $1
# @see http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_03
function strings::escapebre(){
    printf '%s' "$1"|sed 's/[.[\*^$]/\\&/g'
}

function strings::escapelf(){
    printf '%s' "$1"|sed -n 'H;1x;$x;$s/\n/\\n/g;$p'
}

function strings::escapebresed(){
    printf '%s' "$1"|sed 's/[.[\*^$/]/\\&/g'
}

function strings::escapesed(){
    local s;s="$(printf '%s' "$1"|sed 's/[\/& ]/\\&/g')"
    # BSD's sed needs (leading) spaces escaped as well.
    
    local a;IFS=$'\n' read -d $'\0' -ra a <<<"$s"
    local len="${#a[@]}"
    local i;for ((i=0;i<len;i++));do
        printf '%s' "${a[i]}"
        [ "$i" -eq $((len-1)) ]||printf '%s\n' '\'
    done
}

# @param $1
function strings::trimspace(){
    local s="$1" 
    s="${s#${s%%[^[:space:]]*}}"
    s="${s%${s##*[^[:space:]]}}"
    printf '%s' "$s"
}

# @param $1
# @param $2
function strings::trim(){
    local s="$1"
    local cs="$2"
    s="${s#${s%%[^$2]*}}"
    s="${s%${s##*[^$2]}}"
    printf '%s' "$s"
}

# @param $1
# @param $2
function strings::rtrim(){
    local s="$1"
    local cs="$2"
    s="${s%${s##*[^$2]}}"
    printf '%s' "$s"
}

# @param $1
# @param $2
function strings::ltrim(){
    local s="$1"
    local cs="$2"
    s="${s#${s%%[^$2]*}}"
    printf '%s' "$s"
}

# @param $@
function strings::join(){
    local d="${DELIMITER:-,}"
    local s
    printf -v 's' '%s' "${@/#/$d}"
    printf '%s' "${s#$d}"
}

# @param $1 string to be splitted
# @param $2 dest array
function strings::split(){
    local d="${DELIMITER:-,}"
    local s="$1" a="$2" 
    [ -n "$a" ]||return 1
    IFS="$d" read -d $'\0' -ra "$a" < <(echo -n "$s")
}


function strings::ord(){
    [ "${#1}" -gt 0 ]||return 1
    local c="${1:0:1}"
    printf '%d' "'$c"
}

function strings::chr(){
    local n="$1"
    [ "$n" -lt 128 -a "$n" -ge 0 ]||return 1
    printf '%b' "\\x$(printf '%x' "$n")"
}

function strings::percentencode(){
    local l="${#1}"
    for (( i=0;i<$l;i++ ));do
        local c="${1:i:1}"
        if [[ "$c" =~ ^[a-zA-Z0-9_.~-]$ ]];then
            printf '%s' "$c"
        else
            printf '%%%02X' "'$c"
        fi
    done
}

function strings::percentdecode(){
    local s="$1";s="${s//+/ }"
    s="${s//%/\\x}"
    printf '%b' "$s" 
}

# @param $1 length
function strings::rand(){
    local l="${1:-8}"
    local cs='abcdefghijklmnopqrstuvwxyz0123456789'
    local i
    for (( i=0;i<$l;i++ ));do
        printf '%s' "${cs:RANDOM%${#cs}:1}"
    done
    echo
}

