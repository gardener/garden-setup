# Copyright 2019 Copyright (c) 2019 SAP SE or an SAP affiliate company. All rights reserved. This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the LICENSE file.
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

################################################################################
# sow command extensions for garden
################################################################################

CMD_k() {
  local kubeconfig
  local data
  local n=0
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    n="$1"
    shift
  fi
  getRequiredValue data "landscape.clusters["$n"].kubeconfig" CONFIGJSON

  if [[ "$data" = /* ]]; then
    kubeconfig="$1"
  else
    kubeconfig="$ROOT/$data"
  fi

  kubectl --kubeconfig "$kubeconfig" "$@"
}

HELP_k()
{
  echo "k [#] <args>:kubectl for base cluster"
  echo " [#]:first arument might be the number of the base cluster"
  echo " :if multiple base clusters are used"
  echo " <args>:regular kubectl arguments and options"
}

CMD_kv() {
  local kubeconfig="$EXPORT/kube-apiserver/kubeconfig"
  if [ ! -f "$kubeconfig" ]; then
    fail "kube api server not yet deployed"
  fi
  kubectl --kubeconfig "$kubeconfig" "$@"
}

HELP_kv()
{
  echo "kv <args>:kubectl for nodeless garden cluster"
  echo " <args>:regular kubectl arguments and options"
}

CMD_kvg() {
  CMD_kv -n garden "$@"
}

HELP_kvg()
{
  echo "kvg <args>:kubectl for garden namespace of nodeless garden cluster"
}

CMD_kg() {
  CMD_k -n garden "$@"
}

HELP_kg()
{
  echo "kg:kubectl for garden namespace of base cluster"
}

CMD_url() {
  cat "$EXPORT/dashboard/dashboard_url"
}

HELP_url()
{
  echo "url:show the dashbord url for installed garden"
}

# dummy method to easily execute a command within the sow image
CMD_exec() {
  bash -c "$@"
}

HELP_exec()
{
  echo "exec <command>:execute shell command"
  echo ":useful fow executing commands in sow docker container"
  echo ":when using the sow docker wrapper"
}

# convert GCP kubeconfig to basic auth format
# replaces(!) the kubeconfig specified in acre.yaml
# optional argument: which kubeconfig, if several are given in acre.yaml
CMD_convertkubeconfig() {
  local kubeconfig
  local data
  local n=0
  if [[ "$1" =~ ^[0-9]+$ ]]; then
    n="$1"
    shift
  fi
  getRequiredValue data "landscape.clusters["$n"].kubeconfig" CONFIGJSON

  if [[ "$data" = /* ]]; then
    kubeconfig="$1"
  else
    kubeconfig="$ROOT/$data"
  fi

  echo -n "Username: "
  read username

  echo -n "Password: "
  read -s password

  local tmp=$(spiff merge --json "$kubeconfig" | jq -r '.users[0].user={username:"'"$username"'",password:"'"$password"'"}')
  echo -n "$tmp" > "$kubeconfig"
}

HELP_convertkubeconfig()
{
  echo "convertkubeconfig:convert kubeconfig of GKE clusters"
}

