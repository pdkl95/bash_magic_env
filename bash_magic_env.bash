#!/bin/bash

### bash_magic_env.bash --- Environment updates when changing directories ###

# Copyright (C) 2012 Brent Sanders
#
# Author: Brent Sanders <git@thoughtnoise.net>
# URL: http://github.com/pdkl95/bash_magic_env
# Version: 0.1
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

### Comentary ###
#
#  Set environment variables as usual in variosu .magic_env fiels
#  in the directories you want them to be active. They will be
#  loaded when you cd to the directory, and unloaded when you cd away.
#
### Settings ###
#
#  If desired, set these before sourcing this file. All settings
#  are packed into a single associative array, to avoid polluting
#  the main environment namespace. When changing options, you should
#  declare that varaible first:
#
#    declare -A MAGIC_ENV
#
#  Then, set these as needed. If left untouched, it will receive
#  the default value when sourcing this file.
#
#    MAGIC_ENV[LOADER]            (default: ".magic_env")
#         The name of the files found around the filesystem
#         thast have the local environment variables.
#
#    MAGIC_ENV[UNLOADER]          (default: "${MAGIC_ENV[LOADER]}.unload")
#         The name of the optional unload callback scripts.
#
#    MAGIC_ENV[SHOW_CHANGES]      (default: true)
#         Send messages to the terminal about any changes
#         to the environment. Currently, this simply shows
#         the 'declare -- foo=bar' creation statements, and
#         the counterpart 'unset' commands.
#
#    MAGIC_ENV[VERBOSE]           (default: false)
#         Be more verbose with what's happening.
#         Probably only useful during debugging.
#
#    MAGIC_ENV[CONFDIR]           (default: ${HOME}/.bash_magic_env)
#         The directory that holds various config data and
#         environment templates for loading in .magic_env files
#
### Installation ###
#
#  cd ~/opt
#  git clone http://github.com/pdkl95/bash_magic_env.git
#  echo ". ${HOME}/opt/bash_magic_env/bash_magic_env.bash" >> $HOME/.bashrc
#
### Code ###



###  Trap direct-running, as it's useless
if [[ $_ == $0 ]] ; then
cat <<EOF
Running $(basename $0) directly will not do anything - it cannot
modify your currently-running shell! Instead, tell your current
shell to evaluate this file directly. Try running:

    . $0

(the dot '.' at the front is important!)
EOF

    exit 1
fi

# our main footprint on the in the environment
[[ -v MAGIC_ENV        ]] || declare -A MAGIC_ENV
[[ -v MAGIC_ENV_ACTIVE ]] || declare -A MAGIC_ENV_ACTIVE

# settings
me_set() { [[ -z "${MAGIC_ENV[${1}]}" ]] && MAGIC_ENV[${1}]="$2" ; };
me_set SHOW_CHANGES true
me_set VERBOSE      false
me_set LOADER       ".magic_env"
me_set UNLOADER     "${MAGIC_ENV[LOADER]}.unload"
me_set CONFDIR      "${XDG_CONFIG_HOME:-${HOME}/.config}/magic_env"
unset me_set

_magic_env_listdef() {
    read -r -d '' script <<'EOF'
/declare -[-aAfFgilrtux]+ \w+/ ! d
s/^declare\s\S+?\s([^ =]+)=?.*$/\1/g
EOF

    declare -p | sed -re "${script}" | sort --stable
}

_magic_env_list_prune() {
    command /usr/bin/diff \
        --old-line-format='' \
        --unchanged-line-format='' \
        --new-line-format='%L' \
        "$@"
}
# attempting to diff the environment before and after the load
# of a the current .magic_env file, so we know what needs of
# be unloaded later on.
_magic_env_newdefs() {
    _magic_env_list_prune <(echo "$@") <(_magic_env_listdef)
}

_magic_env_load() {
    local dir="${1}"
    local loader="${dir}/${MAGIC_ENV[LOADER]}"

    ${MAGIC_ENV[VERBOSE]} && echo "REQ: [${dir}] -> Load"

    if [[ -n "${MAGIC_ENV_ACTIVE[${dir}]}" ]] ; then
        return    # only if new (no double loading)
    fi

    if ! [[ -r  "${loader}" ]] ; then
        return    # only if the local environment file is present
    fi

    local cur env_vars local
    prev="$(_magic_env_listdef)"
    . "${loader}"
    cur="$(_magic_env_listdef)"
    env_vars="$(_magic_env_list_prune \
        <(_magic_env_array_to_list "${prev[@]}") \
        <(_magic_env_array_to_list "${cur[@]}") )"
    len="$(echo "${env_vars}" | wc -w)"

    ${MAGIC_ENV[VERBOSE]}      && echo "loaded ${len} vars form: ${loader}"
    ${MAGIC_ENV[SHOW_CHANGES]} && {
        (( len > 0 )) && declare -p ${env_vars}
    }

    local hdr="active"
    MAGIC_ENV_ACTIVE[${dir}]="${hdr}|${env_vars}"
}

_magic_env_unload() {
    local dir="${1}"
    ${MAGIC_ENV[VERBOSE]} && echo "REQ: [${dir}] -> Unload"

    [[ -z "${dir}" ]] && return

    local rec="${MAGIC_ENV_ACTIVE[${dir}]}"
    local hdr="${rec%%|*}"
    local var="${rec#*|}"

    [[ -z "${var}" ]] && return

    ${MAGIC_ENV[VERBOSE]} && echo "UNLOAD: ${dir}"
    local unloader="${dir}/${MAGIC_ENV[UNLOADER]}"
    [[ -r "${unloader}" ]] && . "${unloader}"

    ${MAGIC_ENV[SHOW_CHANGES]} && echo unset ${var}
    unset ${var}

    MAGIC_ENV_ACTIVE[${dir}]=
}

_magic_env_scan_parents() {
    local file="$1"
    local dir="${PWD}"
    local -a dirs=()
    local path last
    # buffering on a stack to reverse the order
    # (parent environments should apply before the children)
    while [[ -n "$dir" ]] ; do
        dirs[${#dirs[@]}]="$dir"
        dir="${dir%/*}"
    done

    while (( ${#dirs[@]} > 0 )) ; do
        last=${#dirs[@]}
        dir="${dirs[$last-1]}"
        unset dirs[$last-1]
        path="${dir}/${file}"
        [[ -e "${path}" ]] && echo "${dir}"
    done
}

_magic_env_array_to_list() {
    for i in "${@}" ; do
        echo "$i"
    done | sort --stable
}

# must be called every time the workign directory changes!
_magic_env_update() {
    local pwd="$PWD" dir
    if [[ "${pwd}" != "${MAGIC_ENV[PWD]}" ]]; then

        local -a active=( $(_magic_env_scan_parents "${MAGIC_ENV[LOADER]}") )
        local -a unload=( $(_magic_env_list_prune \
            <(_magic_env_array_to_list "${active[@]}") \
            <(_magic_env_array_to_list "${!MAGIC_ENV_ACTIVE[@]}")) )

        # unloads happen first, to simplify things
        for dir in "${unload[@]}" ; do
            _magic_env_unload "${dir}"
        done

        # these happen in the order the parent-dir scan returned,
        # which should be general->specific. (that is, it should
        # load the ourter, parent dirs first, before the child
        # subdirs that may depend on stuff the parent setus up.
        for dir in "${active[@]}" ; do
            _magic_env_load "${dir}"
        done

        # finally, log the current dir for next time
        MAGIC_ENV[PWD]="${pwd}"
    fi
}

if ! [[ -v DEFS_ONLY ]] ; then
    cd() {
        if command cd "${@}" ; then
            _magic_env_update
            return 0
        else
            return $?
        fi
    }

    # finally, update it once for the current directory
    _magic_env_update
fi



# Local Variables:
# mode: sh
# sh-basic-offset: 4
# sh-shell: bash
# coding: unix
# End:
