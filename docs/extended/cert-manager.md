# Extended Configuration Options for the 'cert-manager' Component

```yaml
  cert-manager:
    email:                                   
    server: <live|staging|self-signed|url>
```

Internally, if `landscape.cert-manager.server` is a string, it is converted into a map with `server.url` containing the given string. The structure then looks like this:

```yaml
  cert-manager:
    email:                                   
    server: 
      url: <live|staging|self-signed|url>
      ca:
        crt:
        key:
```

It is also possible to use this structure directly in the `acre.yaml` file, with the following effects:

If `url` is `self-signed` and `ca.crt` and `ca.key` contain a CA certificate and its key (respectively), this CA will be used to sign the dashboard certificate.
`ca.key` is only evaluated for the `self-signed` case and can be ignored otherwise.

If `url` points to an ACME server that produces untrusted certificates (as the letsencrypt staging server, for example), *the root CA and all intermediate CAs that are used by that ACME server to sign certificates* have to be given in `ca.crt` (simply appended to each other). Otherwise, the deployed kube-apiserver won't be able to verify the dashboard certificate and thus won't accept it. There is one exception to this - if `server.url` is set to `staging`, the required letsencrypt certificates (root CA and intermediate CA) are automatically downloaded and do not have to be provided.

If `url` is `live` or points to an ACME server generating publicly trusted certificates, the `ca` node must not be there at all. You can just use the simplified notation and put the acme server URL directly into `landscape.cert-manager.server`.
