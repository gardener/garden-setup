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

# convert kubeconfig to one using serviceaccount token
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

  local ns="garden-setup-auth"
  local sa="garden-setup"
  local crb="garden-setup-auth"
  # create namespace, if it doesn't exist
  verbose "Creating namespace '$ns', if it doesn't exist ..."
  exec_cmd kubectl --kubeconfig "$kubeconfig" get namespace $ns &>/dev/null || exec_cmd kubectl --kubeconfig "$kubeconfig" create namespace $ns

  # create serviceaccount, if it doesn't exist
  verbose "Creating serviceaccount '$sa', if it doesn't exist ..."
  exec_cmd kubectl --kubeconfig "$kubeconfig" -n $ns get serviceaccount $sa &>/dev/null || exec_cmd kubectl --kubeconfig "$kubeconfig" -n $ns create serviceaccount $sa

  # create serviceaccount secret manually (required for clusters >=1.24)
  verbose "Creating serviceaccount secret '$sa', if it doesn't exist ..."
  exec_cmd kubectl --kubeconfig "$kubeconfig" -n $ns get secret $sa &>/dev/null || exec_cmd kubectl --kubeconfig "$kubeconfig" -n $ns apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: $sa
  annotations:
    kubernetes.io/service-account.name: $sa
type: kubernetes.io/service-account-token
EOF

  # wait for serviceaccount to get token
  local timeout=180
  local sleep_time=5
  local start_time=$(date +%s)
  local token=
  local secret=
  verbose "Fetching serviceaccount token. This might take few seconds."
  while true; do
    debug "kubectl --kubeconfig \"$kubeconfig\" -n $ns get secret $sa -o jsonpath='{.data.token}'"
    if token=$(kubectl --kubeconfig "$kubeconfig" -n $ns get secret $sa -o jsonpath='{.data.token}' 2>/dev/null | base64 -d) && [[ -n "$token" ]]; then
      debug "found token"
      break
    else
      echo "token cannot be retrieved from secret, retrying in $sleep_time seconds ..."
    fi
    local now=$(date +%s)
    if [[ $(($now - $start_time)) -gt $timeout ]]; then
      fail "timeout reached while retrying"
    fi
    sleep 5
  done

  local tmp=$(mktemp)
  spiff merge --json "$kubeconfig" | jq -r '.users[0].user={token: $token}' --arg token "$token" > "$tmp"

  # adding clusterrolebinding
  verbose "Creating clusterrolebinding '$crb' ..."
crb_template=$(cat << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $crb
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: $sa
  namespace: $ns
EOF
)
  kubectl --kubeconfig "$kubeconfig" apply -f - <<< $crb_template

  # validating kubeconfig
  verbose "Validating new kubeconfig ..."
  debug "kubectl --kubeconfig "$tmp" get ns >/dev/null"
  if ! kubectl --kubeconfig "$tmp" get ns >/dev/null; then
    fail "Validation of the newly generated kubeconfig failed. For debugging purposes, you can check the new kubeconfig at $tmp."
  fi

  cp "$tmp" "$kubeconfig"
}

HELP_convertkubeconfig()
{
  echo "convertkubeconfig:convert kubeconfig to serviceaccount token one"
  echo ":this will create a serviceaccount and replace the kubeconfig with one using that serviceaccount's token"
}

