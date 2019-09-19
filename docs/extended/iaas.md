# Advanced Configuration Options for 'landscape.iaas'

```yaml
iaas:
  - name: (( type ))                             # name of the seed
    type: <gcp|aws|azure|openstack>              # iaas provider
    mode: <seed|soil>                            # optional, defaults to 'seed'
    cloudprofile: <name of cloudprofile>         # optional, will deploy its own cloudprofile if not specified
    region: <major region>-<minor region>        # region for initial seed
    zones:                                       # remove zones block for Azure
      - <major region>-<minor region>-<zone>     # example: europe-west1-b
      - <major region>-<minor region>-<zone>     # example: europe-west1-c
      - <major region>-<minor region>-<zone>     # example: europe-west1-d
    credentials:                                 # provide access to IaaS layer used for creating resources for shoot clusters
    seeds:
      - name:                                    # max. 10 characters
        type: <gcp|aws|azure|openstack>
        mode: <seed|soil>                        # NOT optional
        region: <major region>-<minor region>
        zones:
          - <major region>-<minor region>-<zone>
          - <major region>-<minor region>-<zone>
          - <major region>-<minor region>-<zone>
        credentials:
        cluster:
          networks:
            nodes: <CIDR IP range>
            pods: <CIDR IP range>
            services: <CIDR IP range>
            <additional fields depending on type>
      ...
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
            offeredVersions:
              - version: 1.13.0
```

## The 'mode' Field

In addition to the fields mentioned in the readme, there is also a field `mode` in each iaas entry. 
This decides what actually will be deployed:
The default value is `seed`. In this case, the setup will deploy a cloudprofile, a seed, a seed secret, and a provider secret (which will be visible in the dashboard to create shoots from it).
The value `soil` basically behaves like `seed`, but the field `spec.visible` in the seed resource will be set to `false`. The seed will not be taken into account when scheduling shoots - although shoots can be scheduled on that seed if they specifically reference it - and the corresponding provider option may not be visible in the dashboard. You should at least have one visible seed, otherwise you won't be able to create shoots via the dashboard.
`cloudprofile` and `profile` are used synonymously here. In this case, only the cloudprofile will be created, but no seed. The `cluster` and `credentials` nodes are not needed in this case. If the credentials are given anyway, the provider secret will be created. The dashboard only shows infrastructures, if a corresponding (visible) seed and cloudprofile exist. So the cloudprofile alone won't show up in the dashboard, but it can be used to create shoots programmatically, by using one of the existing seeds as seed for that shoot.
If `mode` is set to `inactive`, the complete entry will be removed before the setup processes the entries, it will thus be ignored.


## The 'cloudprofile' Field

By default - that means there is no `cloudprofile` field - each seed will be deployed with its own cloudprofile. However, you might want to have additional seeds (e.g. to support different regions) without having additional cloudprofiles. If the entry has mode `seed` or `soil` and has a `cloudprofile` node, it will not deploy a cloudprofile and instead use the one with the given name.
Cloudprofiles are created first, before any seed. Thus, entries of `landscape.iaas` (as well as nested entries for shooted seeds, see below) can reference cloudprofiles defined by any other entry, independent of the position of either entry.


## Shooted Seeds

```yaml
    ...
    seeds:
      - name:                                    # max. 10 characters
        type: <gcp|aws|azure|openstack>
        mode: <seed|soil>                        # NOT optional for nested entries
        region: <major region>-<minor region>
        zones:
          - <major region>-<minor region>-<zone>
          - <major region>-<minor region>-<zone>
          - <major region>-<minor region>-<zone>
        credentials:
        cluster:
          networks:
            nodes: <CIDR IP range>
            pods: <CIDR IP range>
            services: <CIDR IP range>
            <additional fields depending on type>
      ...
```

Each `landscape.iaas` entry with mode `seed` or `soil` can have an optional `seeds` node. This node contains a list of entries that look very similar to the entries of `landscape.iaas`. For each of these entries, garden-setup will first create a shoot - using the seed corresponding to the `landscape.iaas` entry the current `seeds` entry is nested in - and then create a seed on that cluster (works exactly like the seed creation for the `landscape.iaas` entries).
The `cluster.networks` node always needs the `nodes`, `pods`, and `services` fields, but the CIDRs must not overlap with the ones of the seed used for that shoot. If you want to create shoots using the dashboard, the CIDRs also must not overlap with the default CIDRs the dashboard uses for shoots. To find out which additional fields are needed, check the `networks` node in the shoot example for that provider. You can find the examples [here](https://github.com/gardener/gardener/tree/master/example).

It is not possible to create cascades of shooted seeds this way - `seeds` nodes in already nested entries will not be evaluated. The `seeds` node also doesn't work for entries with mode `cloudprofile`, inner and outer entry have to have mode set to either `seed` or `soil`.

If you want to create shoots on all IaaS providers, best practise is to configure your initial seed (the first entry of `landscape.iaas`) as soil and create one (or more, if necessary) shooted seed for each infrastructure. You can prevent having multiple cloudprofiles by using the `cloudprofile` field explained above, it also works for `seeds` entries.

A few important things to know:
- creating shoots takes some time, thus using shooted seeds will significantly increase the time needed for a complete setup
  - the shoots are created and deleted in parallel to minimize the delay
- all shoots for the shooted seeds will be created in the `core` project with purpose set to `infrastructure`
  - they use a big worker node size and are configured to scale between 1 and 100 workers depending on their load
  - **do not delete these shoots!**
- shoots have a length restriction of 10 characters for their name - this restriction applies to the `name` fields of `seeds` entries


## Overwriting Cloudprofiles

By adding a `profile` node in a iaas entry, it is possible to overwrite parts of the cloudprofile. If the node is present, everything under it will be merged into the `spec` node of the cloudprofile. In this context, 'merged' means that every node that is under or next to `constraints` will be overwritten by what you specify here. You can add nodes that are not part of the default cloudprofile this way. Nodes on these levels that are not given here will use their defaults. A more fine-grained merge of values is not possible - the example above will not add `1.13.0` to the possible kubernetes versions in this cloudprofile, but instead set it to be the only available option.

This is incompatible with the `cloudprofile` field explained above (because no cloudprofile will be created in this case).


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