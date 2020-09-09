# Configuration Options for 'landscape.extensionsValuesOverwrite'

The `landscape.extensionsValuesOverwrite` is entirely optional. 
Whatever is specified in `landscape.extensionsValuesOverwrite.<extensionName>` will be given directly to the helm values for the extension, so you can overwrite the corresponding default values. 
Some values are set by default (take a look in the [deployment.yaml](../../components/gardener/extensions/deployment.yaml)), this values can also overwrite with the `landscape.extensionsValuesOverwrite`.

The following extentions are availibe in `landscape.extensionsValuesOverwrite`:

- dns-external: [values.yaml](https://github.com/gardener/gardener-extension-shoot-dns-service/blob/master/charts/gardener-extension-shoot-dns-service/values.yaml)
- os-coreos: [values.yaml](https://github.com/gardener/gardener-extension-os-coreos/blob/master/charts/gardener-extension-os-coreos/values.yaml)
- os-ubuntu: [values.yaml](https://github.com/gardener/gardener-extension-os-ubuntu/blob/master/charts/gardener-extension-os-ubuntu/values.yaml)
- os-gardenlinux: [values.yaml](https://github.com/gardener/gardener-extension-os-gardenlinux/blob/master/charts/gardener-extension-os-gardenlinux/values.yaml)
- os-suse-chost: [values.yaml](https://github.com/gardener/gardener-extension-os-suse-chost/blob/master/charts/gardener-extension-os-suse-chost/values.yaml)
- provider-aws: [values.yaml](https://github.com/gardener/gardener-extension-provider-aws/blob/master/charts/gardener-extension-provider-aws/values.yaml)
- provider-gcp: [values.yaml](https://github.com/gardener/gardener-extension-provider-gcp/blob/master/charts/gardener-extension-provider-gcp/values.yaml)
- provider-azure: [values.yaml](https://github.com/gardener/gardener-extension-provider-azure/blob/master/charts/gardener-extension-provider-azure/values.yaml)
- provider-openstack: [values.yaml](https://github.com/gardener/gardener-extension-provider-openstack/blob/master/charts/gardener-extension-provider-openstack/values.yaml)
- networking-calico: [values.yaml](https://github.com/gardener/gardener-extension-networking-calico/blob/master/charts/gardener-extension-networking-calico/values.yaml)
- shoot-cert-service: [values.yaml](https://github.com/gardener/gardener-extension-shoot-cert-service/blob/master/charts/gardener-extension-shoot-cert-service/values.yaml)

Example to set the `imageVectorOverwrite` (see [values.yaml](https://github.com/gardener/gardener-extension-networking-calico/blob/master/charts/gardener-extension-networking-calico/values.yaml#L7-L19)) for `gardener-extension-networking-calico`:

```yaml
  ...
  extensionsValuesOverwrite:
    ...
    networking-calico:
      imageVectorOverwrite: |
        images:
        - name: calico-node
          sourceRepository: github.com/projectcalico/calico
          repository: some-other-registry/calico/node
        - name: calico-cni
          sourceRepository: github.com/projectcalico/cni-plugin
          repository: some-other-registry/calico/cni
        - name: calico-typha
          sourceRepository: github.com/projectcalico/typha
          repository: some-other-registry/calico/typha
        ...
```