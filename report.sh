#!/bin/bash

SHELL_DIR=$(dirname $0)

DEFAULT="nalbam/releases-reporter"
REPOSITORY=${GITHUB_REPOSITORY:-$DEFAULT}

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

_init() {
    rm -rf ${SHELL_DIR}/target

    mkdir -p ${SHELL_DIR}/target
    mkdir -p ${SHELL_DIR}/versions

    cp -rf ${SHELL_DIR}/versions ${SHELL_DIR}/target/
}

_check() {
    printf '# %-50s %-20s %-20s\n' "NAME" "NOW" "NEW"

    # check versions
    while read LINE; do
        _get_version ${LINE}
    done < ${SHELL_DIR}/checklist.txt
    echo
}

_get_version() {
    CHART="$1"

    REPO="$(echo ${CHART} | cut -d'/' -f1)"
    NAME="$(echo ${CHART} | cut -d'/' -f2)"

    touch ${SHELL_DIR}/versions/${NAME}
    NOW="$(cat ${SHELL_DIR}/versions/${NAME} | xargs)"

    NEW="$(curl -s https://api.github.com/repos/${CHART}/releases | grep tag_name | cut -d'"' -f4 | grep -v '-' | sort -V -r | head -1)"

    printf '# %-50s %-20s %-20s\n' "${CHART}" "${NOW}" "${NEW}"

    printf "${NEW}" > ${SHELL_DIR}/versions/${NAME}

    if [ "${NOW}" == "${NEW}" ]; then
        return
    fi

    if [ -z "${SLACK_TOKEN}" ]; then
        return
    fi

    CHART_URL="https://github.com/${CHART}/releases/tag/${NEW}"

    curl -sL opspresso.github.io/tools/slack.sh | bash -s -- \
        --token="${SLACK_TOKEN}" --emoji="gear" --color="good" --username="${REPONAME}" \
        --footer="<${CHART_URL}|${CHART}>" \
        --title="tools updated" \
        "\`${CHART}\`\n ${NOW} > ${NEW}"

    echo " slack ${CHART} ${NOW} > ${NEW} "
    echo
}

_message() {
    # commit message
    printf "$(date +%Y%m%d-%H%M)" > ${SHELL_DIR}/target/commit_message.txt
}

_run() {
    _init

    _check

    _message
}

_run
