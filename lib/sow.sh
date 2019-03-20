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

CMD_kv() {
  local kubeconfig="$EXPORT/kube-apiserver/kubeconfig"
  if [ ! -f "$kubeconfig" ]; then
    fail "kube api server not yet deployed"
  fi
  kubectl --kubeconfig "$kubeconfig" "$@"
}

CMD_kvg() {
  CMD_kv -n garden "$@"
}

CMD_kg() {
  CMD_k -n garden "$@"
}
