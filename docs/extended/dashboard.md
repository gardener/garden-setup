# Advanced Configuration Options for 'landscape.dashboard'

The `landscape.dashboard` node is entirely optional. 
Whatever is specified for
- `landscape.dashboard.frontendConfig`
- `landscape.dashboard.gitHub`
will be given directly to the [dashboard helm chart](https://github.com/gardener/dashboard/blob/master/charts/gardener-dashboard/values.yaml), so you can overwrite the corresponding default values.

Please note that `frontendConfig.seedCandidateDeterminationStrategy` can not be overwritten here, as that value is derived from the Gardener. You can overwrite it [here](gardener.md).
The same is true for `frontendConfig.features.terminalEnabled`. See [below](#landscape-dashboard-terminals) on how to activate the terminals.

### landscape.dashboard.cname

With `landscape.dashboard.cname`, you can provide another domain from which the dashboard will be reachable.
```yaml
  ...
  dashboard:
    ...
    cname:
      domain: dashboard.my-other-domain.org
      dns:   # optional
        type: <google-clouddns|aws-route53|azure-dns|openstack-designate|cloudflare-dns>
        credentials: ...
```
If you specify `landscape.dashboard.cname`, the `domain` field has to exist. A `CNAME` DNS entry will be created for that domain, pointing to the Gardener dashboard domain. This differs from `landscape.domain`, where you enter a base domain for your cluster and the dashboard will be available on a subdomain of that domain - this one will point directly to the dashboard.
The `dns` field follows the same structure as `landscape.dns`. If the domain is managed by the same account on the same cloud provider as the one given in `landscape.dns`, you can remove the `dns` field completely, in which case it will use the same values as `landscape.dns`.

The given domain will be included in the generated certificate. If you use untrusted certificates (e.g. self-signed or from the letsencrypt staging server) and access the dashboard via the domain given here.


### landscape.dashboard.terminals

```yaml
  ...
  dashboard:
    ...
    terminals:
      active: false
      cert:
        email: # email for ACME registration
        server: "https://acme-v02.api.letsencrypt.org/directory"
        privateKey: # optional private key for ACME server
```

Via `landscape.dashboard.terminals.active`, the dashboard terminals can be activated, adding terminals to the dashboard that allow easy access to the base cluster, any shoot, and any seed (if you have sufficient privileges to access the corresponding cluster). By default, the terminals are deactivated.

The terminals need trusted certificates and won't work with self-signed ones. The [shoot-cert-service](https://github.com/gardener/gardener-extensions/tree/master/controllers/extension-shoot-cert-service) is used to generate the certificates. The configuration can be done in the optional `landscape.dashboard.terminals.cert` node:
- With `email`, you can set the email used for the ACME registration. If not specified, it will default to `landscape.cert-manager.email` or `landscape.identity.users[0].email`, in that order. 
  - > Using the same email for the cert-manager and the shoot-cert-service can cause problems (duplicate email registration at ACME server), therefore you are advised to use a different email here.
- `server` specifies the ACME server to use for signing certificates. If not set, it defaults to the server specified in `landscape.cert-manager`.
  - This field does not allow `live` for a value, as opposed to the `landscape.cert-manager` spec. Defaulting to the server given for the cert-manager will work though, even if that value is set to `live`.
- If you have a private key for the ACME server, you can specify it at `privateKey`.
  - If `landscape.dashboard.terminals.cert.server` is not set, this field defaults to `landscape.cert-manager.privateKey`, otherwise it is empty.

Due to technical limitations, some ingresses in shoot will have a `certmanager.k8s.io/cluster-issuer: ...` annotation despite the cert-manager not being deployed on the shoots. To avoid conflicts when valid certificates are needed on a shoot, you can either use the [shoot-cert-service](https://github.com/gardener/gardener-extensions/tree/master/controllers/extension-shoot-cert-service), which is deployed on the shoot, or, if you want to use your own cert-manager deployment, make sure you choose a different name for your clusterissuer(s).

Check out the [terminal-controller-manager](https://github.com/gardener/terminal-controller-manager) for more information on the terminals.