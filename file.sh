#!/bin/bash

declare IMPORTDIR=$(cd `dirname ${BASH_SOURCE[0]}` && pwd)
source $IMPORTDIR/out.sh
source $IMPORTDIR/strings.sh

function file::scriptdir(){
    local s=${BASH_SOURCE[1]}
    local d=$(cd -P `dirname $s` && pwd)
    while [ -L "$s" ];do
        s=$(readlink "$s")
        [ "$s" == /* ]||s="$d/$s"
        d=$(cd -P `dirname "$s"` && pwd)
    done
    printf "$d"
}


function file::abspath(){
    local relative=$1
    printf '%s' "$(cd "`dirname "$1"`" && pwd)/`basename "$1"`"
}


#@param $1 file
#@param $2 dest
#@param $3 *dest
function file::unpack(){
    local f=$1
    local _dest=$2
    if [ -z "$f" -o -z "$_dest" ];then
        out::error "invalid argument"
        return 1
    fi 
    if [ ! -f "$f" ];then
        out::error "file not found" "$f"
        return 1
    fi
    if [ ! -d "$_dest" ];then
        out::error "directory not found" "$_dest"
        return 1
    fi    
   
    local n=`basename $f`
    if [[ $n =~ ^.+(\.tar\.gz|\.tgz)$ ]];then
        n=${n%.t*gz}
        mkdir -p "$_dest/$n"
        if ! tar xzf "$f" -C "$_dest/$n" --strip-component 1;then
            out::error "failed to unpack" "$f"
            return 1
        fi
        if [ -n "$3" ];then
            eval "$3='$_dest/$n'"
        fi
        out::info "unpacked" "$f"       
        return
    elif [[ $n =~ ^.+\.tar\.bz2$ ]];then
        n=${n%.tar.bz2}
        mkdir -p "$_dest/$n"
        if ! tar xjf "$f" -C "$_dest/$n" --strip-component 1;then
            out::error "failed to unpack" "$f"
            return 1
        fi
        if [ -n "$3" ];then
            eval "$3='$_dest/$n'"
        fi
        out::info "unpacked" "$f"       
        return
    elif [[ $n =~ ^.+\.zip$ ]];then
        n=${n%.zip}
        if ! unzip -q "$f" -d "$_dest/$n";then
            out::error "failed to unpack" "$f"
            return 1
        fi
        
        pushd "$_dest/$n" >/dev/null
            local ds=$(find . -type d -mindepth 1 -maxdepth 1;printf EOF);ds=${ds%EOF}
            if [ "$(printf "$ds"|wc -l)" -eq 1 ];then # archived file has only one directory
                local ds0="$(printf "$ds"|head -n1)"
                if [ "$(ls -A $ds0 2>/dev/null)" ];then # and the directory is not empty
                    (shopt -s dotglob && mv "$ds0"/* .) && rmdir "$ds0" # eliminates the directory
                fi
            fi
        popd >/dev/null

        if [ -n "$3" ];then
            eval "$3='$_dest/$n'"
        fi
        out::info "unpacked" "$f"
        return
    elif [[ $n =~ ^.+\.tar\.xz$ ]];then
        n=${n%.tar.xz}
        mkdir -p "$_dest/$n"
        if ! tar xf "$f" -C "$_dest/$n" --strip-component 1;then
            out::error "failed to unpack" "$f"
            return 1
        fi
        if [ -n "$3" ];then
            eval "$3='$_dest/$n'"
        fi
        out::info "unpacked" "$f"
        return        
    else
        out::error "unable to unpack" "$f"
        return 1
    fi
}

function file::mktemp()(
    local d=${TMPDIR:-'/tmp'}
    d=$(strings::rtrim "$d" '/')
    
    set -o noclobber
    local i
    for (( i=0;i<3;i++ ));do
        local n="foo$(strings::rand)"
        if (: >"$d/$n") 2>/dev/null;then
            printf '%s\n' "$d/$n"
            return 0   
        fi
    done
    return 1
)

function file::mktempdir(){
    local d=${TMPDIR:-'/tmp'}
    d=$(strings::rtrim "$d" '/')
    [ -n "$d" ]||return 1

    local i
    for (( i=0;i<3;i++ ));do
        local n="foo$(strings::rand)"
        if mkdir "$d/$n" 2>/dev/null;then
            printf '%s\n' "$d/$n"
            return 0
        fi
    done
    return 1
}

# @param $1 file
# @param $2 *callback
function file::withdmg(){
    local f="$1"
    local c="$2"
    if [[ ! -f "$f" || $f != *.dmg ]];then
        out::error 'file not found' "$f"
        return 1
    fi
        
    local m
    if ! m="$(hdiutil attach -nobrowse "$f" 2>/dev/null)";then
        out::error 'failed to attach image' "$f"
        return 1
    else
        m="$(cat <<<"$m"|tail -n1|cut -d$'\t' -f3)"
        out::info 'attached image' "$m"
    fi
    file::_withdmgexit(){
        if [ -n "$m" ];then
            if ! hdiutil detach "$m" 1>/dev/null;then
                out::warn 'failed to detach image' "$m"
            else
                out::info 'detached image' "$m"
            fi
        fi
    }

    trap '{ file::_withdmgexit;trap - RETURN;}' RETURN
   
    if declare -f "$c" >/dev/null;then
        pushd "$m">/dev/null||return 1
        "$c" "$m";local r="$?"
        popd >/dev/null
        return "$r"
    fi
}

# @param $1 *callback
function file::withtempdir(){
    local _withtempdirc="$1"
    local t;t="$(file::mktempdir)"
    if [ "$?" -ne 0 ];then
        out::error 'failed to create directory'
        return 1
    fi

    file::_withtempdirexit(){
        if [ -n "$t" -a -d "$t" ];then
            if ! rm -R "$t" &>/dev/null;then
                out::warn 'failed to delete directory' "$t"
            else
                out::info 'deleted directory' "$t"
            fi
        fi
    }

    trap '{ file::_withtempdirexit;trap - RETURN;}' RETURN

    if declare -f "$_withtempdirc" >/dev/null;then
        pushd "$t">/dev/null||return 1
        "$_withtempdirc" "$t";local r="$?"
        popd >/dev/null
        return "$r"
    fi
}

# @param $1 file
# @param $2 *callback
function file::withpkg(){
    local f="$1"
    local c="$2"
    if [ -d "$f" ];then
        f="$(find "$f" -type 'f' -maxdepth 1 -mindepth 1 -name '*.pkg'|tail -n1)"
    fi
    if [[ ! -f "$f" || $f != *.pkg ]];then
        out::error 'file not found' "$f"
        return 1
    fi
   
    file::_withpkg(){
        local t="$1"
        if ! pkgutil --expand "$f" "$t/foo";then
            out:error "failed to unpack" "$f"
            return 1
        fi

        local d;for d in "$t/foo/"*.pkg/;do
            local n=`basename "$d"`;n="${n%.pkg}"
            [[ $n =~ ^[a-zA-Z0-9\ _.-]+$ ]]||continue
            [ -f "$d/Payload" ]||continue
            
            local _dest="$t/$n"
            mkdir -p "$_dest"       
            if ! tar xzf "$d/Payload" -C "$_dest";then
                out::error 'failed to unpack' "$d/Payload"
                return 1
            fi
        done

        if declare -f "$c" >/dev/null;then
            pushd "$t">/dev/null||return 1
            "$c" "$t";local r="$?"
            popd >/dev/null
            return "$r"
        fi
    }
    file::withtempdir 'file::_withpkg'
}

# @param $1 file
function file::installpkg(){
    local f="$1"
    if [ -d "$f" ];then
        f="$(find "$f" -type 'f' -maxdepth 1 -mindepth 1 '(' -name '*.pkg' -o -name '*.mpkg' ')'|tail -n1)"
    fi
    if [[ ! -f "$f" ]] || \
        [[ $f != *.pkg && $f != *.mpkg ]];then
        out::error 'file not found' "$f"
        return 1
    fi
    local n=`basename "$f"`
    if ! out::scanbool "$(printf 'Install %s, continue?' "$n")";then
        return 1
    fi
    sudo installer -pkg "$f" -target /
}

# @param $1 file
function file::installdmg(){
    local d=${DEST:-'/Applications'}
    if [ ! -d "$d" ];then
        out::error 'directory not found' "$d"
        return 1
    fi

    file::_installdmg(){ 
        local _item="$(find "$1" -type 'd' -maxdepth 1 -mindepth 1 -name '*.app'|tail -n1)"
        local _itemname=`basename "$_item"`
        
        if [ ! -d "$_item" ];then
            return 1
        fi

        local regdest
        if file::_copydirconfirm "$_item" "$d" 'regdest';then
            [ ! -d "$regdest" ]||touch "$regdest"
        else
            return 1
        fi
    }
    file::withdmg "$1" 'file::_installdmg'
}

# @param $1 file
# @param $2 *callback
function file::withzip(){
    local f="$1"
    local c="$2"
    if [ ! -f "$f" ];then
        out::error 'file not found' "$f"
        return 1
    fi
    local t;t="$(file::mktempdir)"
    if [ "$?" -ne 0 ];then
        out::error 'failed to create directory'
        return 1
    fi
  
    file::_withzipexit(){
        if [ -n "$t" -a -d "$t" ];then
            if ! rm -R "$t" &>/dev/null;then
                out::warn 'failed to delete directory' "$t"
            else
                out::info 'deleted directory' "$t"
            fi
        fi
    }

    trap '{ file::_withzipexit;trap - RETURN;}' RETURN
 
    local n=`basename "$f"`
    if [[ $n =~ ^.+(\.tar\.gz|\.tgz|\.tar\.xz|\.tar\.bz2)$ ]];then
        n=${n%.t*}
        if ! tar xf "$f" -C "$t";then
            out::error "failed to unpack" "$f"
            return 1
        fi
    elif [[ $n =~ ^.+\.zip$ ]];then
        n=${n%.zip}
        if ! unzip -q "$f" -d "$t";then
            out:error "failed to unpack" "$f"
            return 1
        fi
    else
        out::error "unable to unpack" "$f"
        return 1
    fi

    if declare -f "$c" >/dev/null;then
        pushd "$t">/dev/null||return 1
        "$c" "$t";local r="$?"
        popd >/dev/null
        return "$r"
    fi
}

# @param $1 file
function file::installzip(){
    local d=${DEST:-'/Applications'}
    if [ ! -d "$d" ];then
        out::error 'directory not found' "$d"
        return 1
    fi
    file::_installzip(){
        local t="$1"
        local _item="$(find "$t" -type 'd' -maxdepth 1 -mindepth 1 -name '*.app'|tail -n1)"
        
        if [ ! -d "$_item" ];then
            return 1
        fi
   
        local regdest
        if file::_copydirconfirm "$_item" "$d" 'regdest';then
            [ ! -d "$regdest" ]||touch "$regdest"   
        else
            return 1
        fi 
    }

    file::withzip "$1" 'file::_installzip'
}

# @param source
# @param dest
# @param *dest
function file::_copydirconfirm(){
    local s="$1"
    local d="$2"
    [ -d "$s" -a -d "$d" ]||return 1
    local _itemname=`basename "$s"`
    
    if [ -d "$d/$_itemname" ];then
        if ! out::scanbool "$(printf 'Existing item found, overwrite %s?' "$d/$_itemname")";then
            return 1
        fi
    else    
        if ! out::scanbool "$(printf 'Copy %s to %s, continue?' "$_itemname" "$d")";then
            return 1
        fi
    fi
    #if ! cp -RL "$s" "$d" 2>/dev/null;then
    if ! cp -R "$s" "$d" 2>/dev/null;then
        return 1
    fi   
    [ -z "$3" ]||printf -v "$3" '%s' "$d/$_itemname"
    out::info 'copied directory' "$s" "$d"
    return 0
}




