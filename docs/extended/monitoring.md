# Advanced Configuration Options for 'landscape.monitoring'

```yaml
landscape:
  ...
  monitoring:
    active: false
    username: admin
    password: # password in clear-text
    customScrapeConfigPath: ./my-scrape-configs
```

Via the `landscape.monitoring` node, the monitoring feature can be activated. If activated, garden-setup will deploy a [Prometheus](https://prometheus.io/) and a [Grafana](https://grafana.com/) instance in the cluster, as well as the [Gardener Metrics Exporter](https://github.com/gardener/gardener-metrics-exporter). The monitoring is pre-configured and can not be adapted in the `acre.yaml` currently.
- `monitoring.active`: if set to `true` (or anything else that is recognized as `true` by YAML), the monitoring components will be deployed. Defaults to `false`.
- `monitoring.username`: the username for the ingress authentication to access the monitoring dashboards. Defaults to `admin`.
- `monitoring.password`: the clear-text password for the ingress authentication to access the monitoring dashboards. Will be automatically generated and stored in the state (clear-text and hash) and export (hash only) of the `monitoring/prometheus` component, if not given.
- `monitoring.customScrapeConfigPath`: if set, all `yaml` files in this folder will be added to the prometheus `scrape_config`. Preceding `./` can be omitted. Absolute aswell as relative paths like `../configs` work.

Instead of username and password, `monitoring.hash` can be specified, containing a hash of the password. The hash should be created via `htpasswd -nb <username> <password>`.

## Configure Prometheus `remote_write`

You can also configure Prometheus to use the `remote_write` feature for central logging. See the 
following configuration:

```yaml
landscape:
  ...
  monitoring:
    ... # (see above)
    remoteWrite:
      url: # url path to remote_write endpoint
      username: # remote_write username
      password: # remote_write password
    externalLabels:
      key1: value1
      key2: value2
      ...
```

You can set credentials for the remote_write endpoint reachable at `url` using `username` and
`password`. The optional user-defined key-value pairs underneath `externalLabels` are passed to
the Prometheus _external labels_ config option.
