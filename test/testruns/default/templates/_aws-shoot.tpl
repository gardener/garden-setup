{{- define "aws-shoot" }}
  - name: create-shoot-aws
    dependsOn: [ create-garden ]
    definition:
      name: create-shoot
      locationSet: default
      config:
      - name: SHOOT_NAME
        type: env
        value: {{ .prefix }}
      - name: CLOUDPROVIDER
        type: env
        value: aws
      - name: K8S_VERSION
        type: env
        value: {{ .Values.shoot.k8sVersion }}
      - name: SEED
        type: env
        value: gcp
      - name: CLOUDPROFILE
        type: env
        value: aws
      - name: SECRET_BINDING
        type: env
        value: core-aws-aws
      - name: REGION
        type: env
        value: eu-west-1
      - name: ZONE
        type: env
        value: eu-west-1b
{{- end }}