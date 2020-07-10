#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
source $IMPORTDIR/out.sh
source $IMPORTDIR/strings.sh

#@param $1 uri
function ftp::geturifilename(){
    local _uri=$1
    local h;h=$(curl --proto '=ftp' -sI "$_uri" 2>/dev/null)
     
    [ "$?" -eq 0 ]||return 1
    local s=$(printf '%s' "$h"|grep 'Content-Length:'|cut -d' ' -f2|tr -d '\r\n')
    [ "$s" -gt 0 ]||return 1
    
    local n;n="$(strings::trimspace "$(basename "$_uri")")"
    [[ $n =~ ^[a-zA-Z0-9\ _.+-]+$ ]]||return 1
    printf '%s' "$n"
}

#@param $1 uri
#@param $2 dest
#@param $3 overwrites existing
#@param $4 *file
function ftp::downloadfile(){
    local _uri=$1
    local _dest=$2
    local f;f=$(ftp::geturifilename "$_uri")
    if [ "$?" -ne 0 -o -z "$f" ];then
        out::error "file name not determined"     
        return 1
    fi
    if [[ -f $_dest/$f && $3 != 't' ]];then
        out::info 'file already exists' "$_dest/$f"   
    else
        (cd $_dest && curl --proto '=ftp' -o "$f" "$_uri")    
        if [ "$?" -ne 0 ];then
            out::error 'failed to download' "$_dest/$f"
            return 1
        fi
        out::info 'downloaded file' "$_dest/$f"
    fi
    if [ -n "$4" ];then
        printf -v "$4" '%s' "$_dest/$f"
    fi
}


