{{- define "gcp-shoot" }}
  - name: create-shoot-gcp
    dependsOn: [ create-garden ]
    definition:
      name: create-shoot
      locationSet: default
      config:
      - name: SHOOT_NAME
        type: env
        value: {{ .prefix }}
      - name: K8S_VERSION
        type: env
        value: {{ .Values.shoot.k8sVersion }}
      - name: CLOUDPROVIDER
        type: env
        value: gcp
      - name: CLOUDPROFILE
        type: env
        value: gcp
      - name: SECRET_BINDING
        type: env
        value: core-gcp-gcp
      - name: REGION
        type: env
        value: europe-west1
      - name: ZONE
        type: env
        value: europe-west1-b
{{- end }}