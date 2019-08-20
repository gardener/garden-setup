{{- define "garden-config" }}
      - name: BASE_CLOUDPROVIDER
        type: env
        value: {{ .Values.baseCluster }}
      - name: gcloud
        type: file
        path: "/tmp/garden/gcloud.json"
        valueFrom:
          secretKeyRef:
            name: garden-test
            key: gcloud.json
      - name: ACCESS_KEY_ID
        type: env
        private: true
        valueFrom:
          secretKeyRef:
            name: garden-test
            key: accessKeyID
      - name: SECRET_ACCESS_KEY_ID
        type: env
        private: true
        valueFrom:
          secretKeyRef:
            name: garden-test
            key: secretAccessKey
      - name: AZ_CLIENT_ID
        type: env
        private: true
        valueFrom:
          secretKeyRef:
            name: garden-test
            key: clientID
      - name: AZ_CLIENT_SECRET
        type: env
        private: true
        valueFrom:
          secretKeyRef:
            name: garden-test
            key: clientSecret
      - name: AZ_SUBSCRIPTION_ID
        type: env
        private: true
        valueFrom:
          secretKeyRef:
            name: garden-test
            key: subscriptionID
      - name: AZ_TENANT_ID
        type: env
        private: true
        valueFrom:
          secretKeyRef:
            name: garden-test
            key: tenantID
{{- end }}