{{- define "az-shoot" }}
  - name: create-shoot-az
    dependsOn: [ create-garden ]
    definition:
      name: create-shoot
      locationSet: default
      config:
      - name: SEED
        type: env
        value: gcp
      - name: SHOOT_NAME
        type: env
        value: {{ .prefix }}
      - name: K8S_VERSION
        type: env
        value: {{ .Values.shoot.k8sVersion }}
      - name: CLOUDPROVIDER
        type: env
        value: azure
      - name: CLOUDPROFILE
        type: env
        value: azure
      - name: SECRET_BINDING
        type: env
        value: core-azure-azure
      - name: REGION
        type: env
        value: westeurope
{{- end }}