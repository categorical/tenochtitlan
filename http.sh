#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
source $IMPORTDIR/out.sh
source $IMPORTDIR/strings.sh

function http::foo(){
    out::info "hello"
}

#@param $1 uri
function http::geturifilename(){
    local _uri=$1
    local _curlopts=('-sLI' '-XGET')
    [ -z "$COOKIE" ]||_curlopts+=('-H' "cookie:$COOKIE")
    local h;h=$(curl "${_curlopts[@]}" "$_uri" 2>/dev/null)
    [ "$?" -eq 0 ]||return 1
    
    local f=$(printf '%s' "$h"|egrep -o 'filename=.*$'|tail -n1|tr -d '\r\n')
    f=${f#filename=};f=$(strings::trim "$f" $'\'"')
    local l=$(printf '%s' "$h"|egrep -o 'Location:.*$'|tail -n1|tr -d '\r\n')
    l=${l#Location:};l=$(strings::trimspace "$l")
    local n
    if [ -n "$f" ];then
        n="$f"
    elif [ -n "$l" ];then
        n=$(strings::percentdecode "$(basename "${l%%\?*}")")
    else
        n=$(strings::percentdecode "$(basename "${_uri%%\?*}")")
    fi
    n=$(strings::trimspace "$n")
    [[ $n =~ ^[a-zA-Z0-9\ _.+-]+$ ]]||return 1
    printf '%s' "$n"
}

#@param $1 uri
#@param $2 dest
#@param $3 overwrites existing
#@param $4 *file
function http::downloadfile(){
    local _uri=$1
    local _dest=$2
    local f=$(http::geturifilename $_uri)
    if [ -z "$f" ];then
        out::error "file name not determined"     
        return 1
    fi
    if [[ -f $_dest/$f && $3 != 't' ]];then
        out::info "file already exists" $_dest/$f    
    else
        pushd $_dest
        local _curlopts=('-L' '-o' "$f")
        [ -z "$COOKIE" ]||_curlopts+=('-H' "cookie:$COOKIE")
        curl "${_curlopts[@]}" "$_uri"        
        popd               
        out::info "downloaded file" $_dest/$f
    fi
    if [ -n "$4" ];then
        eval "$4='$_dest/$f'"
    fi
}


