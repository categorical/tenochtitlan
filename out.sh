#!/bin/sh

out::info() {
    local levelstr='info'
    if [ -t 1 ];then
        local _msg="$*"
        _msg="${_msg/%$'\n'/}";_msg="${_msg//$'\n'/$'\n'$(printf "%${#levelstr}s  ")}"
        printf "\033[96m$levelstr: \033[0m%s\n" "$_msg"
    else
        printf "$levelstr:%s\n" "$*"
    fi
}

out::warn() {
    local levelstr='warn'
    if [ -t 2 ];then
        printf "\033[93m$levelstr: \033[0m%s\n" "$*" >&2
    else
        printf "$levelstr:%s\n" "$*" >&2
    fi
}

out::error() {
    local levelstr='error'
    if [ -t 2 ];then
        printf "\033[31m$levelstr: \033[0m%s\n" "$*" >&2
    else
        printf "$levelstr:%s\n" "$*" >&2
    fi
}

out::debug() {
    local levelstr='debug'
    if [ -t 1 ];then
        printf "\033[37m$levelstr: \033[0m%s\n" "$*"
    else
        printf "$levelstr:%s\n" "$*"
    fi
}

out::fatal() {
    local levelstr='fatal'
    
    if [ -t 2 ];then
        printf "\033[31m$levelstr: \033[0m%s\n" "$*" >&2
    else
        printf "$levelstr:%s\n" "$*" >&2
    fi
    exit 1
}

out::infocr(){
    local levelstr='info'
    if [ -t 1 ];then
        printf "\033[96m$levelstr: \033[0m%s\033[0K\r" "$*"
    else
        printf "$levelstr:%s\n" "$*"
    fi
}

# @param $1 callback
# @param ${@:2} args
out::tick(){
    local _f="$1";shift
    if [ "$(type -t "$_f")" == 'function' -o "$(type -t "$_f")" == 'builtin' ];then
        while :;do
            "$_f" "$1"
            shift
            if ! [ "$#" -gt 0 ];then
                return 0
            fi
            sleep 1
        done
    else
        return 1
    fi
}

out::scanbool(){
    local levelstr='scan'
    
    if [ -t 2 ];then
        printf "\033[32m$levelstr: \033[0m%s (y/N): " "$*" >&2
    else
        printf "$levelstr:%s\n" "$*" >&2
    fi
    local b;read -r 'b'
    if ! [[ $b =~ ^y|Y|t|yes|Yes$ ]];then
        return 1
    fi
    return 0
}




