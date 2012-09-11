#!/bin/bash

[[ -v MAGIC_ENV        ]] || declare -A MAGIC_ENV
[[ -v MAGIC_ENV_ACTIVE ]] || declare -A MAGIC_ENV_ACTIVE

# [[ -n "${MAGIC_ENV[SHOW_CHANGES]}" ]] && MAGIC_ENV[SHOW_CHANGES]=true
# [[ -n "${MAGIC_ENV[VERBOSE]}"      ]] && MAGIC_ENV[VERBOSE]=true
# [[ -n "${MAGIC_ENV[LOADER]}"       ]] && MAGIC_ENV[LOADER]=".magic_env"
# [[ -n "${MAGIC_ENV[UNLOADER]}"     ]] && MAGIC_ENV[UNLOADER]="${MAGIC_ENV[LOADER]}.unload"

me_set() { [[ -z "${MAGIC_ENV[${1}]}" ]] && MAGIC_ENV[${1}]="$2" ; };
me_set SHOW_CHANGES true
me_set VERBOSE      true
me_set LOADER       ".magic_env"
me_set UNLOADER     "${MAGIC_ENV[LOADER]}.unload"
unset me_set

_magic_env_listdef() {
    read -r -d '' script <<'EOF'
/declare -[-aAfFgilrtux]+ \w+/ ! d
s/^declare\s\S+?\s([^ =]+)=?.*$/\1/g
EOF

    declare -p | sed -re "${script}" | sort -s
}

_magic_env_newdefs() {
    command diff \
        --old-line-format='' \
        --unchanged-line-format='' \
        --new-line-format='%L' \
        <(echo "$@") \
        <(_magic_env_listdef)
}

_magic_env_load() {
    local old="${1}" new="${2}"
    local loader="${new}/${MAGIC_ENV[LOADER]}"

    if [[ -n "${MAGIC_ENV_ACTIVE[${new}]}" ]] ; then
        return    # only if new (no double loading)
    fi

    if ! [[ -r  "${loader}" ]] ; then
        return    # only if the local environment file is present
    fi

    local cur env_vars local
    cur="$(_magic_env_listdef)";
    . "${loader}"
    env_vars="$(_magic_env_newdefs "${cur}")"
    len="$(echo "${env_vars}" | wc -w)"

    ${MAGIC_ENV[VERBOSE]}      && echo "loaded ${len} vars form: ${loader}"
    ${MAGIC_ENV[SHOW_CHANGES]} && declare -p ${env_vars}

    MAGIC_ENV_ACTIVE[${new}]=${env_vars}
}

_magic_env_unload() {
    local old="${1}" new="${2}"
    [[ -z "${old}" ]] && return

    local var="${MAGIC_ENV_ACTIVE[${old}]}"
    [[ -z "${var}" ]] && return

    echo "UNLOAD: ${old}"
    local unloader="${old}/${MAGIC_ENV[UNLOADER]}"
    [[ -r "${unloader}" ]] && . "${unloader}"

    ${MAGIC_ENV[SHOW_CHANGES]} && echo unset ${var}
    unset ${var}

    MAGIC_ENV_ACTIVE[${old}]=
}

_magic_env_update() {
    local pwd="$PWD"
    if [[ "${pwd}" != "${MAGIC_ENV[PWD]}" ]]; then
        _magic_env_unload "${MAGIC_ENV[PWD]}" "${pwd}"
        _magic_env_load   "${MAGIC_ENV[PWD]}" "${pwd}"
        MAGIC_ENV[PWD]="${pwd}"
    fi
}

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



# Local Variables:
# mode: sh
# sh-basic-offset: 4
# sh-shell: bash
# coding: unix
# End:
