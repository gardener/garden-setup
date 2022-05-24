# Advanced Configuration Options for 'landscape.iaas'

```yaml
iaas:
  - name: (( type ))                             # name of the seed (can be chosen, must be unique among iaas entries)
    type: <gcp|aws|azure|alicloud|openstack>              # iaas provider
    mode: <seed|soil>                            # optional, defaults to 'seed'
    cloudprofile: <name of cloudprofile>         # optional, will deploy its own cloudprofile if not specified
    featureGates:                                # optional, set featureGates for the gardenlet
      ManagedIstio: true
      APIServerSNI: true
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
        type: <gcp|aws|azure|alicloud|openstack>
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
    seedSettings:                                    # settings for the seed
      excessCapacityReservation:
        enabled: true
      scheduling:
        visible: true
      shootDNS:
        enabled: true
      verticalPodAutoscaler:
        enabled: true
    logging:                                     # optional, configure logging settings for the gardenlet
    # enabled: false
    # fluentBit:                                 # example for FluentBit
    #   output: |-
    #     [Output]
    #         ...
      ...
  - name:                                        # see above
    mode: <seed|cloudprofile|profile|inactive>   # what should be deployed
    type: <gcp|aws|azure|alicloud|openstack>              # see above
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


## The 'featureGates' Field

The `featureGates` field enable/disable featureGates for the gardenlet. A list of available featureGates you can find in the gardener documentation - [Feature Gates in Gardener](https://github.com/gardener/gardener/blob/master/docs/deployment/feature_gates.md)

## The 'logging' Field

The `logging` field contains configuration for the logging behaviour of the gardenlet - [20-componentconfig-gardenlet.yaml](https://github.com/gardener/gardener/blob/master/example/20-componentconfig-gardenlet.yaml)

## The 'seedSettings' Field

The `seedSettings` field let you modify the settings for you seed for further customization. See [here](https://github.com/gardener/gardener/blob/master/docs/usage/seed_settings.md#settings-for-seeds) the documentation.

## The 'gardenClientConnection' Field

The `gardenClientConnection.qps` and `gardenClientConnection.burst` is to overwrite the `qps`  and `burst` default values in gardenlet-configmap - [20-componentconfig-gardenlet.yaml](https://github.com/gardener/gardener/blob/master/example/20-componentconfig-gardenlet.yaml)


## The 'seedClientConnection' Field

The `seedClientConnection.qps` and `seedClientConnection.burst` is to overwrite the `qps`  and `burst` default values in gardenlet-configmap - [20-componentconfig-gardenlet.yaml](https://github.com/gardener/gardener/blob/master/example/20-componentconfig-gardenlet.yaml)


## The 'shootClientConnection' Field

The `shootClientConnection.qps` and `shootClientConnection.burst` is to overwrite the `qps`  and `burst` default values in gardenlet-configmap - [20-componentconfig-gardenlet.yaml](https://github.com/gardener/gardener/blob/master/example/20-componentconfig-gardenlet.yaml)


## Shooted Seeds

```yaml
    ...
    seeds:
      - name:                                    # max. 10 characters
        type: <gcp|aws|azure|alicloud|openstack>
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
- all shoots for the shooted seeds will be created in the `garden` project with purpose set to `infrastructure`
  - they use a big worker node size and are configured to scale between 1 and 100 workers depending on their load
  - **do not delete these shoots!**
- shoot names have a length restriction: project and shoot name together may not exceed 21 characters, therefore the `name` fields of `seeds` entries have a maximum length of 15 characters


### Example CIDRs

Setting the CIDRs correctly is somewhat difficult and having them configured wrongly often results in very strange errors. Here are some example CIDRs for reference:

This example assumes these CIDRs for your base cluster:
```yaml
networks:
  nodes: 10.254.0.0/19
  pods: 10.255.0.0/17
  services: 10.255.128.0/17
```
Remember that the CIDRs of a shoot and its corresponding seed must not overlap. The base cluster is configured as initial seed, so the CIDRs for shooted seeds have to be disjunct. Furthermore, the shooted seed CIDRs should be disjunct from the dashboard's defaults. You can modify these defaults with the `iaas[*].shootDefaultNetworks` field per seed, see the example at the beginning of this page, for Alicloud the dedault value will be `{ "pods" = "172.32.0.0/13", "services" = "172.40.0.0/13" }` if you do not modify it.
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

You might notice that the `node` CIDR is larger than the `workers` CIDR. The reason is that for AWS the `workers` is the configuration for the subnet used by nodes in a single zone.  Since the shoot may span multiple zones you can have more nodes than workers generally (`nodes >= workers`). The AWS Extension repo has [more details](https://github.com/gardener/gardener-extension-provider-aws/blob/master/docs/usage-as-end-user.md#infrastructureconfig).

#### Shooted Seed CIDRs Example for GCP

```yaml
networks:
  nodes: 10.242.0.0/16
  pods: 10.243.128.0/17
  services: 10.243.0.0/17
  workers: 10.242.0.0/19
```

Regarding the `workers` and `nodes` the same as for AWS applies (see above).

#### Shooted Seed CIDRs Example for Alicloud

```yaml
networks:
  nodes: 10.242.0.0/16
  pods: 10.243.128.0/17
  services: 10.243.0.0/17
  vpc:
    cidr: 10.242.0.0/16
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

Unlike GCP or AWS, in Azure a single subnet is used for all zones. Hence here `workers` and `nodes` setting is identical.


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
    name: <first image specified in the cloudprofile> # 'gardenlinux' by default
    version: <some image version>
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


## Image Vector Overwrites

The gardenlet takes an optional image vector overwrite, in case the default image registry is not reachable from the seed cluster (or shouldn't be used for some other reason). The syntax for overwriting the image vectors in the acre.yaml file is as shown below.

```yaml
iaas:
  - name: (( type ))
    ...
    imageVectorOverwrite:                        # optional, overwrites image vector of gardenlet
      images:
        - name: pause-container
          sourceRepository: github.com/kubernetes/kubernetes/blob/master/build/pause/Dockerfile
          repository: my-custom-image-registry/pause-amd64
          tag: "3.0"
          version: 1.11.x
    componentImageVectorOverwrite:               # optional, overwrites component image vector of gardenlet
      components:
        - name: etcd-druid
          imageVectorOverwrite:
            images:
              - name: pause-container
                sourceRepository: github.com/kubernetes/kubernetes/blob/master/build/pause/Dockerfile
                repository: my-custom-image-registry/pause-amd64
                tag: "3.0"
                version: 1.11.x

```

For further information regarding the image vector overwrites, have a look at the documentation [here](https://github.com/gardener/gardener/blob/master/docs/deployment/image_vector.md).
Please note that the component image vector overwrites should be specified as YAML objects and not strings as shown in the aforementioned documentation. The conversion into strings is handled automatically by garden-setup.


## Overwriting Cloudprofiles

By adding a `profile` node in a iaas entry, it is possible to overwrite parts of the cloudprofile. If the node is present, everything under it will be merged into the `spec` node of the cloudprofile. In this context, 'merged' means that every node that is directly under `spec` will be overwritten by what you specify here. You can add nodes that are not part of the default cloudprofile this way. Nodes on these levels that are not given here will use their defaults. A more fine-grained merge of values is not possible - the example above will not add `1.13.0` to the possible kubernetes versions in this cloudprofile, but instead set it to be the only available option.

This is incompatible with the `cloudprofile` field explained above (because no cloudprofile will be created in this case).


## Seed Configuration

```yaml
iaas:
  - name: ...
    ...
    seedConfig:                     # optional
      backup:                       # optional
        active: <true|false>        # optional, defaults to true
        type: <gcs|s3|abs|...>      # optional (type, region, and credentials must be provided together)
        region: <region>            # optional (type, region, and credentials must be provided together)
        credentials:                # optional (type, region, and credentials must be provided together)
      providerConfig:               # optional
        foo: bar
        ...
```
The `seedConfig` node can be added to any iaas entry that has mode `seed` or `soil` (including shooted seed entries).

### Seed Backup

By default, garden-setup configures Gardener to store snapshots of the etcds in shoot controlplanes in a blob store. To disable storing of backups, set `seedConfig.backup.active` to `false`.

Usually, the seed credentials - the ones provided in the corresponding iaas entry - are also used for backing up the etcds of the shoots. If this is not desired, it is possible to configure a different blobstore for the backup. The configuration is basically the same as for `landscape.etcd.backup`, but if one of `type`, `region`, or `credentials` is specified - indicating not to use the default blobstore - no defaulting is done and the other two have to be specified too.
If `active` is set to `false`, this configuration has no effect.

### Seed Provider Config

While usually not needed, in some cases it can be necessary to provide a certain seed with some provider-specific configuration. Everything that is provided under `seedConfig.providerConfig` of a iaas entry will be rendered into `spec.provider.providerConfig` of the corresponding seed. A map structure is expected.


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
      useOctavia: false # optional
      nodeVolumeAttachLimit: 256 # optional, sets the maximum volumes per node in the csi driver
      dnsServers: # optional
        - "8.8.8.8"
      machineImageDefinitions:
        - name: ubuntu # A
          versions:
            - image: ubuntu-18.04
              version: 18.4.20190617 # B
      machineImages:
        - name: ubuntu # A
          versions:
            - version: 18.4.20190617 # B
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

All of the Openstack-specific nodes go into the [cloudprofile](https://github.com/gardener/gardener/blob/master/example/30-cloudprofile.yaml), with `machineImageDefinitions` providing the values for `spec.providerConfig.machineImages`.

The version inside the ``machineImageDefinitions`` and ``machineImages`` sections has to be specified using the [semantic versioning](https://semver.org) format.

For nested Openstack entries, the floating pool name which should be used for the shoot for the shooted seed can be specified by setting `floatingPoolName` in the nested iaas entry. If not specified, the first entry of the `floatingPools` list will be used.

> Keep in mind that you can reference cloudprofiles created by other iaas entries (see [cloudprofile](#the-cloudprofile-field)). If you reference another cloudprofile, none will be created for the current iaas entry and you can leave out all of the provider-specific configuration. You can also use [spiff++ templating](https://github.com/mandelsoft/spiff) to reduce redundancy.


## vSphere

Similarly to Openstack, vSphere also needs additional configuration, see the example below:

```yaml
  iaas:
    - name: vsphere                                                           # can be chosen, must be unique among iaas entries
      type: vsphere
      loadBalancerConfig:
        classes:
          - ipPoolName: <IP pool name>                                        # name of the NSX-T IP pool (must be set for the default load balancer class)
            # tcpAppProfileName: <tcp profile name>                             # optional, profile name of the load balaner profile for TCP
            # udpAppProfileName: <udp profile name>                             # optional, profile name of the load balaner profile for UDP
            name: default
        size: <SMALL|MEDIUM|LARGE>
      defaultClassStoragePolicyName: <default storage class policy name>      # name of vSphere storage policy to use for the 'default-class' storage class
      dnsServers:                                                             # list of IPs
      - <dns server IP>
      folder: <folder>                                                        # vSphere folder name for storing the cloned machine VMs
      machineImageDefinitions:
        - name: <machine image name> # A
          versions:
            - path: <image path>
              version: <image version> # B
              # guestId: <guest id>                                             # optional, overwrites the guestId of the VM template
      machineTypeOptions:                                                     # optional
        - name: std-02-reserved # C
          memoryReservationLockedToMax: true                                  # optional, flag to reserve all guest OS memory (no swapping in ESXi host)
          extraConfig: {}                                                     # optional, allows to specify additional VM options (e.g. sched.swap.vmxSwapEnabled=false to disable the VMX process swap file)
      namePrefix: <name prefix>                                               # name prefix for naming NSX-T resources
      # csiResizerDisabled: false                                               # optional
      # failureDomainLabels:                                                    # optional, tag categories used for regions and zones
      #   region: <region>
      #   zone: <zone>
      regionDefinitions:                                                      # regions and zones topology
        - datacenter: <datacenter name>                                       # optional, name of the vSphere data center (data center can either be defined at region or zone level)
          edgeCluster: <edge cluster>
          logicalTier0Router: <local tier 0 router>
          name: <region name>
          nsxtHost: <nsxt host IP>
          # nsxtInsecureSSL: true                                               # optional, insecure HTTPS is allowed for NSXTHost
          nsxtRemoteAuth: true                                                # NSX-T uses remote authentication (authentication done through the vIDM)?
          snatIPPool: <snat IP pool name>
          transportZone: <transport zone name>
          vsphereHost: <vsphere host IP>
          vsphereInsecureSSL: true                                            # insecure HTTPS is allowed for VsphereHost?
          # datastore: <datastore name>                                         # optional, vSphere datastore to store the cloned machine VM (either datastore or datastoreCluster must be specified at region or zones level)
          # datastoreCluster: <datastore cluster name>                          # vSphere  datastore cluster to store the cloned machine VM (either datastore or datastoreCluster must be specified at region or zones level)
          # caFile: <certificate>                                               # optional, CA file to be trusted when connecting to vCenter (if not set, the node's CA certificates will be used)
          # thumbprint: <thumbprint>                                            # optional, vCenter certificate thumbprint
          zones:
            - datastore: NFS                                                  # vSphere datastore to store the cloned machine VM (either datastore or datastoreCluster must be specified at region or zones level)
              # datacenter: <datacenter name>                                     # optional, name of the vSphere data center (data center can either be defined at region or zone level)
              # computeCluster: <compute cluster>                                 # name of the vSphere compute cluster (either computeCluster or resourcePool or hostSystem must be specified)
              # hostSystem: <host system>                                         # name of the vSphere host system (either computeCluster or resourcePool or hostSystem must be specified)
              resourcePool: <resource pool>                                       # name of the vSphere resource pool (either computeCluster or resourcePool or hostSystem must be specified)
              name: <zone name>
              # switchUuid: 00 11 22 33 44 55 66 77-88 99 00 aa bb cc dd ee       # UUID of the virtual distributed switch the network is assigned to (only needed if there are multiple vds)
      machineTypes:
        - cpu: "2"
          gpu: "0"
          memory: 8Gi
          name: std-02
          usable: true
        - cpu: "4"
          gpu: "0"
          memory: 16Gi
          name: std-04
          usable: true
        - cpu: "2"
          gpu: "0"
          memory: 8Gi
          name: std-02-reserved # C
          usable: true
      machineImages:
        - name: <machine image name> # A
          versions:
            - version: <machine image version> # B
      seedConfig:
        providerConfig:
          # storage policy name used on seed for etcd main of shoots control plane
          storagePolicyName: vSAN Default Storage Policy

```
> Keep in mind that you can reference cloudprofiles created by other iaas entries (see [cloudprofile](#the-cloudprofile-field)). If you reference another cloudprofile, none will be created for the current iaas entry and you can leave out all of the provider-specific configuration. You can also use [spiff++ templating](https://github.com/mandelsoft/spiff) to reduce redundancy.
