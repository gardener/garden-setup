# Advanced Configuration Options for 'landscape.dashboard'

The `landscape.dashboard` node is entirely optional. There are basically three nodes in it that are evaluated:
- `landscape.dashboard.frontendConfig`
- `landscape.dashboard.gitHub`
- `landscape.dashboard.cname`

The contents of the first two will be given directly to the [dashboard helm chart](https://github.com/gardener/dashboard/blob/master/charts/gardener-dashboard/values.yaml), so you can overwrite the corresponding default values.

Please note that `frontendConfig.seedCandidateDeterminationStrategy` can not be overwritten here, as that value is derived from the Gardener. You can overwrite it [here](gardener.md).

### landscape.dashboard.cname

With `landscape.dashboard.cname`, you can provide another domain from which the dashboard will be reachable.
```yaml
  ...
  dashboard:
    ...
    cname:
      domain: dashboard.my-other-domain.org
      dns:   # optional
        type: <google-clouddns|aws-route53|azure-dns|openstack-designate>
        credentials: ...
```
If you specify `landscape.dashboard.cname`, the `domain` field has to exist. A `CNAME` DNS entry will be created for that domain, pointing to the Gardener dashboard domain. This differs from `landscape.domain`, where you enter a base domain for your cluster and the dashboard will be available on a subdomain of that domain - this one will point directly to the dashboard.
The `dns` field follows the same structure as `landscape.dns`. If the domain is managed by the same account on the same cloud provider as the one given in `landscape.dns`, you can remove the `dns` field completely, in which case it will use the same values as `landscape.dns`.

The given domain will be included in the generated certificate. If you use untrusted certificates (e.g. self-signed or from the letsencrypt staging server) and access the dashboard via the domain given here