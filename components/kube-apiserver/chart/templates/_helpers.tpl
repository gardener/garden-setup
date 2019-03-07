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

{{- define "garden.kubeconfig-controller-manager" -}}
apiVersion: v1
kind: Config
current-context: garden
contexts:
- context:
    cluster: garden
    user: kube-controller-manager
  name: garden
clusters:
- cluster:
    certificate-authority-data: {{ .Values.tls.kubeAPIServer.ca.crt | b64enc }}
    server: https://localhost:443
  name: garden
users:
- name: kube-controller-manager
  user:
    client-certificate-data: {{ .Values.tls.kubeControllerManager.crt | b64enc }}
    client-key-data: {{ .Values.tls.kubeControllerManager.key | b64enc }}
{{- end -}}

{{- define "garden.kubeconfig-gardener" -}}
apiVersion: v1
kind: Config
current-context: garden
contexts:
- context:
    cluster: garden
    user: gardener
  name: garden
clusters:
- cluster:
    certificate-authority-data: {{ .Values.tls.kubeAPIServer.ca.crt | b64enc }}
    server: https://{{ .Values.apiServer.serviceName }}:443
  name: garden
users:
- name: gardener
  user:
    client-certificate-data: {{ .Values.tls.gardener.crt | b64enc }}
    client-key-data: {{ .Values.tls.gardener.key | b64enc }}
{{- end -}}

{{- define "garden.kubeconfig-admin" -}}
apiVersion: v1
kind: Config
current-context: garden
contexts:
- context:
    cluster: garden
    user: admin
  name: garden
clusters:
- cluster:
    certificate-authority-data: {{ .Values.tls.kubeAPIServer.ca.crt | b64enc }}
    server: https://{{ .Values.apiServer.hostname }}:443
  name: garden
users:
- name: admin
  user:
    client-certificate-data: {{ .Values.tls.admin.crt | b64enc }}
    client-key-data: {{ .Values.tls.admin.key | b64enc }}
{{- end -}}
