#!/bin/bash

[[ -v MAGIC_ENV_ACTIVE ]] || declare -A MAGIC_ENV_ACTIVE=()

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
    local cur env_vars env="${new}/.env"
    if ! [[ -v MAGIC_ENV_ACTIVE[${new}] ]] && [[ -r  "${env}" ]] ; then
        # only if new (no double loading)
        # only if the local environment file is present

        cur="$(_magic_env_listdef)";
        . "${env}"
        env_vars="$(_magic_env_newdefs "${cur}")"

        echo "$(echo "${env_vars}" | wc -w) vars loaded form: ${env}"
        declare -p ${env_vars}

        MAGIC_ENV_ACTIVE[${new}]=${env_vars}
    fi

}

_magic_env_unload() {
    local old="${1}" new="${2}"
    local vars="${MAGIC_ENV_ACTIVE[${old}]}"
    if [[ -n "${vars}" ]] ; then
        echo "UNLOAD: ${old}"
        echo unset ${vars}
        unset ${vars}
        MAGIC_ENV_ACTIVE[${old}]=
    fi
}

_magic_env_chdir() {
    local pwd="${1}"
    _magic_env_unload "${MAGICENV_PWD}" "${pwd}"
    _magic_env_load "${MAGICENV_PWD}" "${pwd}"
    MAGICENV_PWD="${pwd}"
}

function _magic_env_update() {
    local dir="$PWD"
    if [[ "$dir" != "${MAGICENV_PWD}" ]]; then
        _magic_env_chdir "$PWD"
    fi
}

function cd() {
    if command cd "${@}" ; then
        _magic_env_update
        return 0
    else
        return $?
    fi
}

# Local Variables:
# mode: sh
# sh-basic-offset: 4
# sh-shell: bash
# coding: unix
# End:
