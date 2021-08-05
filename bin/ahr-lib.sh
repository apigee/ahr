# Copyright 2020 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


function vaml() { vim -R -c 'set syntax=yaml' -;}

function token { echo -n "$(gcloud config config-helper --force-auth-refresh | grep access_token | grep -o -E '[^ ]+$')" ; }

function check_envvars() {
    local varlist=$1

    local varsnotset="F"

    for v in $varlist; do
        if [ -z "${!v}" ]; then
            >&2 echo "Required environment variable $v is not set."
            varsnotset="T"
        fi
    done

    if [ "$varsnotset" = "T" ]; then
        >&2 echo ""
        >&2 echo "ABEND. Please set up required variables."
        return 1
    fi
}


function check_commands() {
    local comlist=$1

    local comsnotset="F"

    for c in $comlist; do
        if ! [ -x "$(command -v $c)" ]; then
            >&2 echo "Required command is not on your PATH: $c."
            comsnotset="T"
        fi
    done

    if [ "$comsnotset" = "T" ]; then
        >&2 echo ""
        >&2 echo "ABEND. Please make sure required commands are set and accesible via PATH."
        return 1
    fi
}

function check_gnu_date() {

    VERSION=$( set +e; date --version 2>&1; echo "$?" )

    if [ "$( grep -c GNU <<< "$VERSION" )" -eq 0  ]; then
        >&2 echo ""
        >&2 echo "ABEND. date command is not GNU."
        >&2 echo "       For OSX  set up coreutils and use"
        >&2 echo "       <your local bin with mv-ed date>/PATH to substitute date with gdate"
        >&2 echo "       instead of the resident one."
        >&2 echo "       For Windows, use cygwin."
        return 1
    fi
}


function check_already_exists() {
    response="$1"

    if [ "$( grep -c error <<< "$response" )" -ne 0  ]; then
        >&2 echo "$response"
        if [[ "$response" =~ "ALREADY_EXISTS" ]]; then
            >&2 echo "Already Exists. Continue."
        else
            return 1
        fi
    fi
}


function get_org_env_sha() {
    # ENV == "" controls $ORG or $ORG/$ENV sha
    local ORG=$1
    local ENV=$2

    if [ "$ENV" = "" ]; then
        # $ORG_SHA

        local ORG_SHA=${ORG:0:15}-$(echo -n "$ORG" | openssl dgst -sha256 -binary | xxd -p -c256 | cut -c1-7)
        echo -n "$ORG_SHA"

    else
        # $ORG_ENV_SHA

        local ORG_ENV_SHA=${ORG:0:15}-${ENV:0:15}-$(echo -n "$ORG:$ENV" | openssl dgst -sha256 -binary | xxd -p -c256 | cut -c1-7)
        echo -n "$ORG_ENV_SHA"
    fi
}

function get_password(){
    local password
    local passconfirm
    while true; do
        read -srp "Enter password: " password
        echo "" >&2
        read -srp "Confirm password: " passconfirm
        echo "" >&2
        if [ "$password" == "$passconfirm" ]; then
            break
        else
            echo "Passwords do not match. Please re-enter" >&2
        fi
    done
    echo -n "$password"
}

# example: wait_for_ready "ready" 'cat ready.txt' "File is ready."
function wait_for_ready(){
    local status=$1
    local action=$2
    local message=$3

    while true; do
        local signal=$(eval "$action")
        if [ $(echo $status) = "$signal" ]; then
            echo -e "\n$message"
            break
        fi
        echo -n "."
        sleep 5
    done
}


function get_account_as_member() {
  ACCOUNT=$(gcloud config list --format='value(core.account)')
  gcloud iam service-accounts describe $ACCOUNT &> /dev/null
  if [ $? -eq 0 ] ; then
    echo "serviceAccount:$ACCOUNT"
    return
  fi
  echo "user:$ACCOUNT"
}

function get_hybrid_path_repo() {
  # compare second version number
  # before and after 1.4
  local VERSION=$1

  local REPO_PATH="apigee-release/hybrid"
  local V_2ND_NMBR=$( echo "$VERSION" | awk -F. '{print $2}' )

  if [ $V_2ND_NMBR -le 3 ]; then
     REPO_PATH="apigee-public"

  fi
  echo -n "$REPO_PATH"
}

function get_platform_suffix() {
  local COMP=$1
  local PLATFORM=$2
  local SUFFIX

  case "$COMP" in
  [0-9][0-9.]*-asm*)
    case "$PLATFORM" in
    linux)

      case "$COMP" in
      1.5[0-9.]*-asm*)
         SUFFIX=linux.tar.gz ;;
      *)
         SUFFIX=linux-amd64.tar.gz ;;
      esac ;;
    osx)
      SUFFIX=osx.tar.gz ;;
    win)
      SUFFIX=win.zip ;;
    esac ;;

  apigeectl)
    case "$PLATFORM" in
    linux)
      SUFFIX=linux_64.tar.gz ;;
    osx)
      SUFFIX=mac_64.tar.gz ;;
    esac ;;
  esac

  echo -n "$SUFFIX"
}

function get_apigeectl_tarball_url(){
  if [ -z "$1" ]; then
    echo -n "ERROR: no version provided"
  elif [ -z "$2" ]; then
    echo -n "ERROR: no PLATFORM provided"
  else
    local VERSION=$1
    local PLATFORM=$2

    echo -n "https://storage.googleapis.com/$(get_hybrid_path_repo $VERSION)/apigee-hybrid-setup/$VERSION/apigeectl_$(get_platform_suffix apigeectl $PLATFORM)"
  fi
}
