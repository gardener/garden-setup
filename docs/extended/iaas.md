# Extended Configuration Options for 'landscape.iaas'

```yaml
iaas:
  - name: (( type ))                             # name of the seed
    type: <gcp|aws|azure|openstack>              # iaas provider
    region: <major region>-<minor region>        # region for initial seed
    zones:                                       # remove zones block for Azure
      - <major region>-<minor region>-<zone>     # example: europe-west1-b
      - <major region>-<minor region>-<zone>     # example: europe-west1-c
      - <major region>-<minor region>-<zone>     # example: europe-west1-d
    credentials:                                 # provide access to IaaS layer used for creating resources for shoot clusters
  - name:                                        # see above
    mode: <seed|cloudprofile|profile|inactive>   # what should be deployed
    type: <gcp|aws|azure|openstack>              # see above
    region: <major region>-<minor region>        # region for seed
    zones:                                       # remove zones block for Azure
      - <major region>-<minor region>-<zone>     # example: europe-west1-b
      - <major region>-<minor region>-<zone>     # example: europe-west1-c
      - <major region>-<minor region>-<zone>     # example: europe-west1-d
    cluster:                                     # information about your seed's base cluster
      networks:                                  # CIDR IP ranges of seed cluster
        nodes: <CIDR IP range>
        pods: <CIDR IP range>
        services: <CIDR IP range>
      kubeconfig:                                # kubeconfig for seed cluster
        apiVersion: v1
        kind: Config
        ...
    credentials:
    profile:
      <gcp|aws|azure|openstack>:                 # depends on infrastructure provider
        constraints:
          kubernetes:
            versions:
              - 1.13.0
```

## The 'mode' Field

In addition to the fields mentioned in the readme, there is also a field `mode` in each iaas entry. 
This decides what actually will be deployed:
The default value is `seed`. In this case, the setup will deploy a cloudprofile, a seed, a seed secret, and a provider secret (which will be visible in the dashboard to create shoots from it).
`cloudprofile` and `profile` are used synonymously here. In this case, only the cloudprofile will be created, but no seed. The `cluster` and `credentials` nodes are not needed in this case. If the credentials are given anyway, the provider secret will be created. The dashboard only shows infrastructures, if a corresponding seed and cloudprofile exist. So the cloudprofile won't show up in the dashboard, but it can be used to create shoots programmatically, by using one of the existing seeds as seed for that shoot.
If `mode` is set to `inactive`, the complete entry will be removed before the setup processes the entries, it will thus be ignored.


## Overwriting Cloudprofiles

By adding a `profile` node in a iaas entry, it is also possible to overwrite parts of the cloudprofile. If the node is present, everything under it will be merged into the `spec` node of the cloudprofile. In this context, 'merged' means that every node that is under or next to `constraints` will be overwritten by what you specify here. You can add nodes that are not part of the default cloudprofile this way. Nodes on these levels that are not given here will use their defaults. A more fine-grained merge of values is not possible - the example above will not add `1.13.0` to the possible kubernetes versions in this cloudprofile, but instead set it to be the only available option.


## Openstack

Since every Openstack installation is different, configuring the setup for Openstack needs some additional configuration. See below for an example configuration:

```yaml
landscape:
  iaas:
    - name: openstack
      type: openstack
      ... # other iaas configuration, e.g. credentials
      floatingPools:
        - name: my-floating-pool-network
      loadBalancerProviders:
        - name: haproxy
      extensionConfig:
        machineImages:
        - cloudProfiles:
          - image: coreos-2023.5.0
            name: openstack
          name: coreos
          version: 2023.5.0
      machineImages:
        - name: coreos
          version: 2023.5.0
      machineTypes:
        - name: medium_2_4
          cpu: "2"
          gpu: "0"
          memory: 4Gi
          usable: true
          volumeType: default
          volumeSize: 20Gi
        - name: medium_4_8
          cpu: "4"
          gpu: "0"
          memory: 8Gi
          usable: true
          volumeType: default
          volumeSize: 40Gi
```

The information specified in `extensionConfig` will be used for the [Openstack provider extension](https://github.com/gardener/gardener-extensions/tree/master/controllers/provider-openstack), while all other Openstack-specific nodes go into the [cloudprofile](https://github.com/gardener/gardener/blob/master/example/30-cloudprofile-openstack.yaml).

### Openstack 'extensionConfig'

The `extensionConfig` node in the openstack iaas configuration is somewhat special. First of all, if at least one iaas entry of type `openstack` is present in your acre.yaml, **exactly one** of the openstack iaas entries should have the `extensionConfig` node. Furthermore, some values there have to match other values of your configuration, otherwise you won't be able to create shoots:
```yaml
landscape:
  iaas:
    - name: openstack               # A
      ...
      extensionConfig:
        machineImages:
        - cloudProfiles:
          - image: coreos-2023.5.0
            name: openstack         # A
          name: coreos              # B
          version: 2023.5.0         # C
      machineImages:
        - name: coreos              # B
          version: 2023.5.0         # C
```
- each entry in `machineImages` must have a corresponding entry in `extensionConfig.machineImages` with matching `name` and `version`
- each `iaas` entry of type `openstack` must have a corresponding entry in `extensionConfig.machineImages[].cloudProfiles` with matching `name`