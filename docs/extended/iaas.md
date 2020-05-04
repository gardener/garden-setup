# Advanced Configuration Options for 'landscape.iaas'

```yaml
iaas:
  - name: (( type ))                             # name of the seed
    type: <gcp|aws|azure|openstack>              # iaas provider
    mode: <seed|soil>                            # optional, defaults to 'seed'
    cloudprofile: <name of cloudprofile>         # optional, will deploy its own cloudprofile if not specified
    shootDefaultNetworks:                        # optional, overwrites defaults of .spec.networks.shootDefaults in the seed manifest
      pods: 100.96.0.0/11
      services: 100.64.0.0/13
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
    shootDefaultNetworks:                        # see above
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
      kubernetes:
        versions:
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
        shootDefaultNetworks:                    # see above
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
- all shoots for the shooted seeds will be created in the `core` project with purpose set to `production`
  - they use a big worker node size and are configured to scale between 1 and 100 workers depending on their load
  - **do not delete these shoots!**
- shoots have a length restriction of 10 characters for their name - this restriction applies to the `name` fields of `seeds` entries


### Example CIDRs

Setting the CIDRs correctly is somewhat difficult and having them configured wrongly often results in very strange errors. Here are some example CIDRs for reference:

This example assumes these CIDRs for your base cluster:
```yaml
networks:
  nodes: 10.254.0.0/19
  pods: 10.255.0.0/17
  services: 10.255.128.0/17
```
Remember that the CIDRs of a shoot and its corresponding seed must not overlap. The base cluster is configured as initial seed, so the CIDRs for shooted seeds have to be disjunct. Furthermore, the shooted seed CIDRs should be disjunct from the dashboard's defaults. You can modify these defaults with the `iaas[*].shootDefaultNetworks` field per seed, see the example at the beginning of this page.
Depending on where you get your base cluster from, you might not be able to influence its CIDRs.

#### Shooted Seed CIDRs Example for AWS
```yaml
networks:
  nodes: 10.242.0.0/16
  pods: 10.243.128.0/17
  services: 10.243.0.0/17
  public: 10.242.96.0/22
  internal: 10.242.112.0/22
  vpc:
    cidr: 10.242.0.0/16
  workers: 10.242.0.0/19
```

#### Shooted Seed CIDRs Example for GCP
```yaml
networks:
  nodes: 10.242.0.0/16
  pods: 10.243.128.0/17
  services: 10.243.0.0/17
  workers: 10.242.0.0/19
```

#### Shooted Seed CIDRs Example for Azure
```yaml
networks:
  nodes: 10.242.0.0/19
  pods: 10.243.128.0/17
  services: 10.243.0.0/17
  vnet:
    cidr: 10.242.0.0/16
  workers: 10.242.0.0/19
```


### Worker Configuration

It is possible to configure the worker groups for the shooted seeds. To do so, just add a `shootMachines` node to the shooted seed's iaas configuration, which follows the same structure as the worker configuration of the [shoot spec](https://github.com/gardener/gardener/blob/0.30.2/example/90-shoot.yaml#L29-L91).

By default, only one worker group will be configured with these values:
```yaml
name: cpu-worker
minimum: 1
maximum: 50
maxSurge: "50%"
maxUnavailable: 0
machine:
  type: <depends on iaas provider>
  image:
    name: coreos # or first image from `machineImages` for openstack
    version: <some coreos version>
volume:
  type: <depends on iaas provider>
  size: "50Gi"
zones: <first zone from the specified zones, if found>
```

If you only want to overwrite some values of this worker group, you can just add the corresponding key and value in the `shootMachines` node:
```yaml
      - name: my-seed
        type: gcp
        mode: seed
        shootMachines:
          maxSurge: 1
        ...
```
This example would only overwrite the `maxSurge` field and use the defaults for everything else.

If you want to add another worker group, provide a list instead with each entry overwriting the defaults of the corresponding worker group as explained above:
```yaml
        ...
        shootMachines:
          - {} # use defaults for first worker group
          - name: logging
            maximum: 3
            labels:
              my-logging-label: "true"
        ...
```
This would configure two worker groups, the first one completely with default values and the second one with default values except for `name`, `maximum`, and `labels`.

Note that if you don't overwrite the name, the first worker group will be named `cpu-worker` and each following worker group will be named `worker`, followed by its index. In the above example, the second worker group would have been named `worker1`, if the name wasn't overwritten.


## Overwriting Cloudprofiles

By adding a `profile` node in a iaas entry, it is possible to overwrite parts of the cloudprofile. If the node is present, everything under it will be merged into the `spec` node of the cloudprofile. In this context, 'merged' means that every node that is directly under `spec` will be overwritten by what you specify here. You can add nodes that are not part of the default cloudprofile this way. Nodes on these levels that are not given here will use their defaults. A more fine-grained merge of values is not possible - the example above will not add `1.13.0` to the possible kubernetes versions in this cloudprofile, but instead set it to be the only available option.

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
          - name: coreos
            versions:
              - image: coreos-2303.3.0
                version: 2303.3.0
              - image: coreos-2135.6.0
                version: 2135.6.0
          - name: ubuntu
            versions:
              - image: ubuntu-18.04
                version: 18.4.20190617
      machineImages:
        - name: coreos
          versions:
          - version: 2303.3.0
          - version: 2135.6.0
        - name: ubuntu
          versions:
          - version: 18.4.20190617
      machineTypes:
        - name: medium_2_4
          cpu: "2"
          gpu: "0"
          memory: 4Gi
          usable: true
          storage:
            class: ""
            type: default
            size: 20Gi
        - name: medium_4_8
          cpu: "4"
          gpu: "0"
          memory: 8Gi
          usable: true
          storage:
            class: ""
            type: default
            size: 40Gi
```

All of the Openstack-specific nodes go into the [cloudprofile](https://github.com/gardener/gardener/blob/master/example/30-cloudprofile-openstack.yaml), with `extensionConfig.machineImages` providing the values for `spec.providerConfig.machineImages`.

### Openstack 'extensionConfig'

The `extensionConfig` node in the openstack iaas configuration is somewhat special - some values there have to match other values of your configuration, otherwise you won't be able to create shoots:
```yaml
landscape:
  iaas:
      ...
      extensionConfig:
        machineImages:
          - name: coreos                 # A
            versions:
              - image: coreos-2303.3.0
                version: 2303.3.0        # B
      machineImages:
        - name: coreos                   # A
          versions:
          - version: 2303.3.0            # B
```
Each entry in `machineImages` must have a corresponding entry in `extensionConfig.machineImages` with matching `name` and `version`.