# Advanced Configuration Options for 'landscape.monitoring'

```yaml
landscape:
  ...
  monitoring:
    active: false
    username: admin
    password: # password in clear-text
```

Via the `landscape.monitoring` node, the monitoring feature can be activated. If activated, garden-setup will deploy a [Prometheus](https://prometheus.io/) and a [Grafana](https://grafana.com/) instance in the cluster, as well as the [Gardener Metrics Exporter](https://github.com/gardener/gardener-metrics-exporter). The monitoring is pre-configured and can not be adapted in the `acre.yaml` currently.
- `monitoring.active`: if set to `true` (or anything else that is recognized as `true` by YAML), the monitoring components will be deployed. Defaults to `false`.
- `monitoring.username`: the username for the ingress authentication to access the monitoring dashboards. Defaults to `admin`.
- `monitoring.password`: the clear-text password for the ingress authentication to access the monitoring dashboards. Will be automatically generated and stored in the state (clear-text and hash) and export (hash only) of the `monitoring/prometheus` component, if not given.

Instead of username and password, `monitoring.hash` can be specified, containing a hash of the password. The hash should be created via `htpasswd -nb <username> <password>`.