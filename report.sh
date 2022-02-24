#!/bin/bash

SHELL_DIR=$(dirname $0)

DEFAULT="nalbam/releases-reporter"
REPOSITORY=${GITHUB_REPOSITORY:-$DEFAULT}

USERNAME=${GITHUB_ACTOR}
REPONAME=$(echo "${REPOSITORY}" | cut -d'/' -f2)

_init() {
  rm -rf ${SHELL_DIR}/.previous

  mkdir ${SHELL_DIR}/target

  cp -rf ${SHELL_DIR}/versions ${SHELL_DIR}/.previous
}

_check() {
  # printf '# %-50s %-20s %-20s\n' "NAME" "NOW" "NEW"

  # check versions
  while read LINE; do
    _get_versions ${LINE}
  done <${SHELL_DIR}/checklist.txt

  echo
}

_get_versions() {
  CHART="$1"

  REPO="$(echo ${CHART} | cut -d'/' -f1)"
  NAME="$(echo ${CHART} | cut -d'/' -f2)"

  EMOJI="${2:-$NAME}"

  curl -sL https://api.github.com/repos/${CHART}/releases | jq '.[].tag_name' -r | grep -v '-' | head -10 \
    >${SHELL_DIR}/versions/${NAME}

  while read V1; do
    if [ -z "$V1" ]; then
      continue
    fi

    EXIST="false"
    while read V2; do
      if [ "$V1" == "$V2" ]; then
        EXIST="true"
        # echo "# ${NAME} ${V1} EXIST"
        continue
      fi
    done <${SHELL_DIR}/.previous/${NAME}

    if [ "$EXIST" == "false" ]; then
      # send slack message
      _slack "$V1"
    fi
  done <${SHELL_DIR}/versions/${NAME}

  echo
}

_slack() {
  if [ -z "${SLACK_TOKEN}" ]; then
    return
  fi

  VERSION="$1"

  curl -sL opspresso.github.io/tools/slack.sh | bash -s -- \
    --token="${SLACK_TOKEN}" --emoji="${EMOJI}" --color="good" --username="${REPONAME}" \
    --footer="<https://github.com/${CHART}/releases/tag/${VERSION}|${CHART}>" \
    --title="tools updated" \
    "\`${CHART}\`\n${VERSION}"

  echo "# slack ${CHART} ${VERSION}"
  echo
}

_message() {
  # commit message
  printf "$(date +%Y%m%d-%H%M)" >${SHELL_DIR}/target/commit_message.txt
}

_run() {
  _init

  _check

  _message
}

_run
