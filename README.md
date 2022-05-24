# Install Gardener on your Kubernetes Landscape

Gardener uses Kubernetes to manage Kubernetes clusters. This documentation describes how to install Gardener on an existing Kubernetes cluster of your IaaS provider.
> Where reference is made in this document to the *base cluster*, we are actually referring to the existing cluster where you will install Gardener. This helps to distinguish them from the clusters that you will create after the installation using Gardener. Once it's installed, it is also referred to as *garden cluster*. Whenever you create clusters, Gardener will create *seed clusters* and *shoot clusters*. In this documentation we will only cover the installation of clusters in one region of one IaaS provider. More information: [Architecture](https://gardener.cloud/documentation/030-architecture/).

## Disclaimer: Productive Use

Please be aware that garden-setup was created with the intent of providing an easy way to install Gardener for the purpose of "having a look into it". While it offers lots of configuration options and can be used to create landscapes , garden-setup lacks some features which are usually expected from a 'productive' installer. The most prominent example is that garden-setup *does not have any built-in support for upgrading an existing landscape*. You can 'deploy over' an existing landscape with a new version of garden-setup (or one of its components), but this scenario is not tested or validated in any way, and might or might not work.

## Prerequisites

* The installation was tested on Linux and MacOS
* You need to have the following tools installed:
  * [Docker](https://docs.docker.com/install/)
  * [git](https://git-scm.com/downloads)
  * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* You need a *base cluster*. Currently, the installation tools supports to install Gardener on the following Kubernetes clusters:
  * Kubernetes version >= 1.11 or enable the feature gate `CustomResourceSubresources` for 1.10 clusters
  * [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster) on Google Cloud Platform (GCP)
  * [Elastic Container Service for Kubernetes (EKS)](https://docs.aws.amazon.com/eks/) or [Kubernetes Operations (kops)](https://github.com/kubernetes/kops) on Amazon Web Services (AWS)
    * Standard EKS clusters impose some additional difficulties for deploying a Gardener, one example being the EKS networking plugin that uses the same CIDR for nodes and pods, which Gardener can't handle. We are working on an improved documentation for this case. In the meantime, it is recommended to use other means for getting the initial cluster to avoid additional efforts.
  * [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/) on Microsoft Azure
* Your base cluster needs at least 4 nodes with a size of 8GB for each node
  * This is only a rough estimate for the required resources, you can also use fewer or more nodes if the node size is adjusted accordingly
  * If you don't create additional seeds, all shoots' controlplanes will be hosted on your base cluster and these minimal requirements won't hold
* You need a service account for the virtual machine instance of your IaaS provider where your Kubernetes version runs
* You need to have permissions to access your base cluster's private key
* You are connected to your Kubernetes cluster (environment variable `KUBECONFIG` is set)
  * [Viewing kubeconfig (GKE)](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#viewing_kubeconfig)
  * [Create a kubeconfig for Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)
  * [Use Azure role-based access controls to define access to the Kubernetes configuration file in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/control-kubeconfig-access)
* You need to have the [Vertical Pod Autoscaler (VPA)](https://github.com/kubernetes/autoscaler/tree/master/vertical-pod-autoscaler) installed on the base cluster and each seed cluster (Gardener deploys it on [shooted seeds](docs/extended/iaas.md#shooted-seeds) automatically).

## Procedure

To install Gardener in your base cluster, a command line tool [sow](https://github.com/gardener/sow) is used. It depends on other tools to be installed. To make it simple, we have created a Docker image that already contains `sow` and all required tools. To execute `sow` you call a [wrapper script](https://github.com/gardener/sow/tree/master/docker/bin) which starts `sow` in a Docker container (Docker will download the image from [eu.gcr.io/gardener-project/sow](http://eu.gcr.io/gardener-project/sow) if it is not available locally yet). Docker executes the sow command with the given arguments, and mounts parts of your file system into that container so that `sow` can read configuration files for the installation of Gardener components, and can persist the state of your installation. After `sow`'s execution Docker removes the container again.

Which version of `sow` is compatible with this version of garden-setup is specified in the [SOW_VERSION](SOW_VERSION) file. Other versions might work too, but especially older versions of `sow` are probably incompatible with newer versions of garden-setup.

1. Clone the `sow` repository and add the path to our [wrapper script](https://github.com/gardener/sow/tree/master/docker/bin) to your `PATH` variable so you can call `sow` on the command line.

    ```bash
    # setup for calling sow via the wrapper
    git clone "https://github.com/gardener/sow"
    cd sow
    export PATH=$PATH:$PWD/docker/bin
    ```

1. Create a directory `landscape` for your Gardener landscape and clone this repository into a subdirectory called `crop`:

    ```bash
    cd ..
    mkdir landscape
    cd landscape
    git clone "https://github.com/gardener/garden-setup" crop
    ```

1. If you don't have your `kubekonfig` stored locally somewhere yet, download it. For example, for GKE you would use the following command:

    ```bash
    gcloud container clusters get-credentials <your_cluster> --zone <your_zone> --project <your_project>
    ```

1. Save your `kubeconfig` somewhere in your `landscape` directory. For the remaining steps we will assume that you saved it using file path `landscape/kubeconfig`.

1. In your `landscape` directory, create a configuration file called `acre.yaml`. The structure of the configuration file is described [below](#configuration-file-acreyaml). Note that the relative file path `./kubeconfig` file must be specified in field `landscape.cluster.kubeconfig` in the configuration file.

    > Do not use file `acre.yaml` in directory `crop`. This file is used internally by the installation tool.

1. The Gardener itself, but also garden-setup can only handle kubeconfigs with standard authentication methods (basic auth, token, ...). Authentication methods that require a third party tool, e.g. the `aws` or `gcloud` CLI, are not supported.

    - If you created the base cluster using GKE, you can convert your `kubeconfig` file to one that uses basic authentication by using the `sow convertkubeconfig` command:

      ```bash
      sow convertkubeconfig
      ```
      When asked for credentials, enter the ones that the GKE dashboard shows when clicking on `show credentials`.

      `sow` will replace the file specified in `landscape.cluster.kubeconfig` of your `acre.yaml` file by a kubeconfig file that uses basic authentication.

      The basic autentication is disabled by default starting with Kubernetes `1.12`, [see more details here](https://cloud.google.com/kubernetes-engine/docs/how-to/hardening-your-cluster#restrict_authn_methods).

      In case it is disabled on your cluster, the following command can be used to enable it:

      ```bash
      gcloud container clusters update <your-cluster> --enable-basic-auth
      ```

    - If you are not using GKE and don't know how to get a kubeconfig with standard authentication, you can also create a serviceaccount, grant it cluster-admin privileges by adding it to the corresponding `ClusterRoleBinding`, and construct a kubeconfig using that serviceaccount's token.

1. Open a second terminal window which current directory is your `landscape` directory. Set the `KUBECONFIG` environment variable as specified in `landscape.cluster.kubeconfig`, and watch the progress of the Gardener installation:

    ```bash
    export KUBECONFIG=./kubeconfig
    watch -d kubectl -n garden get pods,ingress,sts,svc
    ```

1. In your first terminal window, use the following command to check in which order the components will be installed. Nothing will be deployed yet and you can test this way if your syntax in `acre.yaml` is correct:

    ```bash
    sow order -A
    ```

1. If there are no error messages, use the following command to deploy Gardener on your base cluster:

    ```bash
    sow deploy -A
    ```

1. `sow` now starts to install Gardener in your base cluster. The installation can take about 30 minutes. `sow` prints out status messages to the terminal window so that you can check the status of the installation. The other terminal window will show the newly created Kubernetes resources after a while and if their deployment was successful. Wait until the last component is deployed and all created Kubernetes resources are in status `Running`.

1. Use the following command to find out the URL of the Gardener dashboard.

    ```bash
    sow url
    ```

More information: [Most Important Commands and Directories](#most-important-commands-and-directories)


## Concept: The 'Virtual' Cluster

As a part of garden-setup, a `kube-apiserver` and `kube-controller-manager` will be deployed into your base cluster, creating the so-called 'virtual' cluster. The name comes from the fact that it behaves like a kubernetes cluster, but there aren't any nodes behind this kube-apiserver and thus no workload will actually run on this cluster. This kube-apiserver is then extended by the Gardener apiserver.

### Reasoning

At first glance, this feels unintuitive. Why do we create another kube-apiserver which needs its own kubeconfig? However, there are two major reasons for this approach:

#### Full Control

The kube-apiserver needs to be configured in a certain way so that it can be used for a Gardener landscape. For example, the Gardener dashboard needs some OIDC configuration to be set on the kube-apiserver, otherwise authentication at the dashboard won't work. However, since garden-setup relies on a base cluster created by other means, many people will probably use a managed kubernetes service (like GKE) to create the initial cluster - but most of the managed services do not grant access to the kube-apiserver to the end-users.
By deploying an own kube-apiserver, garden-setup ensures full control over its configuration, which improves stability and reduces complexity of the landscape setup.

#### Disaster Recovery

Garden-setup also deploys an own etcd for the kube-apiserver. Because the kube-apiserver - and thus its etcd - is only being used for Gardener resources, restoring the state of a Gardener landscape from an etcd backup is significantly easier than it would be if the Gardener resources were mixed with other resources in the etcd.

### Disadvantage: Two kubeconfigs

The major disadvantage of this approach is that two kubeconfigs are needed to operate the Gardener: one for the base cluster, where all the pods are running, and one for the 'virtual' cluster where the Gardener resources - `shoot`, `seed`, `cloudprofile`, ... - are maintained. The kubeconfig for the 'virtual' cluster can be found in the landscape folder at `export/kube-apiserver/kubeconfig` or it can be pulled from the secret `garden-kubeconfig-for-admin` in the `garden` namespace of the base cluster after the `kube-apiserver` component of garden-setup has been deployed.


### TL;DR

Use the kubeconfig at `export/kube-apiserver/kubeconfig` to access the cluster where the Gardener resources - `shoot`, `seed`, `cloudprofile`, and so on - are maintained.


## Configuration File acre.yaml

This file will be evaluated using `spiff`, a dynamic templating language for yaml files. For example, this simplifies the specification of field values that are used multiple times in the yaml file. For more information, see the [spiff repository](https://github.com/mandelsoft/spiff/blob/master/README.md).

> Please note that, for the sake of clarity, not all configuration options are listed in this readme. Instead, the more advanced configuration options have been moved into a set of additional documentation files. You can access these pages via their [index](docs/extended/README.md) and they are usually linked in their corresponding sections below.

<pre>
landscape:
  <a href="#landscapename">name</a>: &lt;Identifier&gt;                       # general Gardener landscape identifier, for example, `my-gardener`
  <a href="#landscapedomain">domain</a>: &lt;prefix&gt;.&lt;cluster domain&gt;        # unique basis domain for DNS entries

  <a href="#landscapecluster">cluster</a>:                                          # information about your base cluster
    kubeconfig: &lt;relative path + filename&gt;          # path to your `kubeconfig` file, rel. to directory `landscape` (defaults to `./kubeconfig`)
    <a href="#landscapenetworks">networks</a>:                                       # <a target="_blank" rel="noopener noreferrer" href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">CIDR IP ranges</a> of base cluster
      nodes: &lt;CIDR IP range&gt;
      pods: &lt;CIDR IP range&gt;
      services: &lt;CIDR IP range&gt;

  <a href="#landscapeiaas">iaas</a>:
    - name: (( iaas[0].type ))                   # name of the seed
      type: &lt;gcp|aws|azure|alicloud|openstack|vsphere&gt;    # iaas provider
      region: &lt;major region&gt;-&lt;minor region&gt;      # region for initial seed
      zones:                                     # remove zones block for Azure
        - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # example: europe-west1-b
        - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # example: europe-west1-c
        - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # example: europe-west1-d
      credentials:                               # provide access to IaaS layer used for creating resources for shoot clusters
    - name:                                      # see above
      type: &lt;gcp|aws|azure|alicloud|openstack&gt;            # see above
      region: &lt;major region&gt;-&lt;minor region&gt;      # region for seed
      zones:                                     # remove zones block for Azure
        - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # Example: europe-west1-b
        - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # Example: europe-west1-c
        - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # Example: europe-west1-d
      cluster:                                   # information about your seed's base cluster
        networks:                                # CIDR IP ranges of seed cluster
          nodes: &lt;CIDR IP range&gt;
          pods: &lt;CIDR IP range&gt;
          services: &lt;CIDR IP range&gt;
        kubeconfig:                              # kubeconfig for seed cluster
          apiVersion: v1
          kind: Config
          ...
      credentials:

  <a href="#landscapeetcd">etcd</a>:                                       # optional for gcp/aws/azure/alicloud/openstack, default values based on `landscape.iaas`
    backup:
      type: &lt;gcs|s3|abs|oss|swift&gt;                # type of blob storage
      resourceGroup:                          # Azure resource group you would like to use for your backup
      region: (( iaas.region ))               # region of blob storage (default: same as above)
      credentials: (( iaas.credentials ))     # credentials for the blob storage's IaaS provider (default: same as above)
    resources:                                # optional: override resource requests and limits defaults
      requests:
        cpu: 400m
        memory: 2000Mi
      limits:
        cpu: 1
        memory: 2560Mi

  <a href="#landscapedns">dns</a>:                                    # optional for gcp/aws/azure/openstack, default values based on `landscape.iaas`
    type: &lt;google-clouddns|aws-route53|azure-dns|alicloud-dns|openstack-designate|cloudflare-dns|infoblox-dns&gt;   # dns provider
    credentials: (( iaas.credentials ))   # credentials for the dns provider

  <a href="#landscapeidentity">identity</a>:
    users:
      - email:                                # email (used for Gardener dashboard login)
        username:                             # username (displayed in Gardener dashboard)
        password:                             # clear-text password (used for Gardener dashboard login)
      - email:                                # see above
        username:                             # see above
        hash:                                 # bcrypted hash of password, see above

  <a href="#landscapecert-manager">cert-manager</a>:
    email:                                    # email for acme registration
    server: &lt;live|staging|self-signed|url&gt;    # which kind of certificates to use for the dashboard/identity ingress (defaults to `self-signed`)
    privateKey:                               # optional existing user account's private key
</pre>


### landscape.name
```yaml
landscape:
  name: <Identifier>
```
Arbitrary name for your landscape. The name will be part of the names for resources, for example, the etcd buckets.

### landscape.domain
```yaml
domain: <prefix>.<cluster domain>
```
Basis domain for DNS entries. As a best practice, use an individual prefix together with the cluster domain of your base cluster.

### landscape.cluster
```yaml
cluster:
  kubeconfig: <relative path + filename>
  networks:
    nodes: <CIDR IP range>
    pods: <CIDR IP range>
    services: <CIDR IP range>
```

Information about your base cluster, where the Gardener will be deployed on.

`landscape.cluster.kubeconfig` contains the path to your kubeconfig, relative to your landscape directory. It is recommended to create a kubeconfig file in your landscape directory to be able to sync all files relevant for your installation with a git repository. This value is optional and will default to `./kubeconfig` if not specified.

`landscape.cluster.networks` contains the CIDR ranges of your base cluster.
Finding out CIDR ranges of your cluster is not trivial. For example, GKE only tells you a "pod address range" which is actually a combination of pod and service CIDR. However, since the `kubernetes` service typically has the first IP of the service IP range and most methods to get a kubernetes cluster tell you at least something about the CIDRs, it is usually possible to find out the CIDRs with a little bit of educated guessing.

### landscape.iaas
```yaml
iaas:
  - name: (( type ))                           # name of the seed
    type: <gcp|aws|azure|alicloud|openstack|vsphere>    # iaas provider
    region: <major region>-<minor region>      # region for initial seed
    zones:                                     # remove zones block for Azure
      - <major region>-<minor region>-<zone>   # example: europe-west1-b
      - <major region>-<minor region>-<zone>   # example: europe-west1-c
      - <major region>-<minor region>-<zone>   # example: europe-west1-d
    credentials:                               # provide access to IaaS layer used for creating resources for shoot clusters
  - name:                                      # see above
    type: <gcp|aws|azure|alicloud|openstack|vsphere>    # see above
    region: <major region>-<minor region>      # region for seed
    zones:                                     # remove zones block for Azure
      - <major region>-<minor region>-<zone>   # example: europe-west1-b
      - <major region>-<minor region>-<zone>   # example: europe-west1-c
      - <major region>-<minor region>-<zone>   # example: europe-west1-d
    cluster:                                   # information about your seed's base cluster
      networks:                                # CIDR IP ranges of seed cluster
        nodes: <CIDR IP range>
        pods: <CIDR IP range>
        services: <CIDR IP range>
      kubeconfig:                              # kubeconfig for seed cluster
        apiVersion: v1
        kind: Config
        ...
    credentials:
```
Contains the information where Gardener will create intial seed clusters and cloudprofiles to create shoot clusters.

| Field                | Type                   | Description                                                                                                                                                                                                                                                                                                                                                             | Examples                                                                        | Iaas Provider Documentation                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|:-------------------- |:---------------------- |:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |:------------------------------------------------------------------------------- |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`               | Custom value           | Name of the seed/cloudprofile. Must be unique.                                                                                                                                                                                                                                                                                                                          | `gcp`                                                                           |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `type`               | Fixed value            | IaaS provider for the seed.                                                                                                                                                                                                                                                                                                                                             | `gcp`                                                                           |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `region`             | IaaS provider specific | Region for the seed cluster. The convention to use &lt;major region&gt;-&lt;minor region&gt; does not apply to all providers.<br/><br/>In Azure, use [az account list-locations](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list-locations) to find out the location name (`name` attribute = lower case name without spaces). | `europe-west1` (GCP)<br/><br/>`eu-west-1` (AWS) <br/><br/>`eu-central-1` (Alicloud) <br/><br/> `westeurope` (Azure) | [GCP (HowTo)](https://cloud.google.com/kubernetes-engine/docs/how-to/managing-clusters#viewing_your_clusters), [GCP (overview)](https://cloud.google.com/docs/geography-and-regions); [AWS (HowTo)](https://docs.aws.amazon.com/cli/latest/reference/eks/describe-cluster.html), [AWS (Overview)](https://docs.aws.amazon.com/general/latest/gr/rande.html); [Azure (Overview)](https://azure.microsoft.com/en-us/global-infrastructure/geographies/), [Azure (HowTo)](https://docs.microsoft.com/en-us/cli/azure/account?view=azure-cli-latest#az-account-list-locations) |
| `zones`              | IaaS provider specific | Zones for the seed cluster. Not needed for Azure.                                                                                                                                                                                                                                                                                                                       | `europe-west1-b` (GCP)<br/></br>                                                | [GCP (HowTo)](https://cloud.google.com/kubernetes-engine/docs/how-to/managing-clusters#viewing_your_clusters), [GCP (overview)](https://cloud.google.com/docs/geography-and-regions); [AWS (HowTo)](https://docs.aws.amazon.com/cli/latest/reference/eks/describe-cluster.html), [AWS (Overview)](https://docs.aws.amazon.com/general/latest/gr/rande.html)                                                                                                                                                                                                                |
| `credentials`        | IaaS provider specific | Credentials in a provider-specific format.                                                                                                                                                                                                                                                                                                                              | See table with yaml keys below.                                                 | [GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys), [AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html#id_users_service_accounts), [Azure](https://docs.microsoft.com/en-us/azure/aks/kubernetes-walkthrough-portal)                                                                                                                                                                                                                                                                          |
| `cluster.kubeconfig` | Kubeconfig             | The kubeconfig for your seed base cluster. Must have basic auth authentification.                                                                                                                                                                                                                                                                                       |                                                                                 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `cluster.networks`   | CIDRs                  | The CIDRs of your seed cluster. See <a href="#landscapecluster">landscape.cluster</a> for more information.                                                                                                                                                                                                                                                             |                                                                                 |                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |

Here a list of configurations can be given. The setup will create one cloudprofile and seed per entry. Currently, you will have to provide the cluster you want to use as a seed - in future, the setup will be able to create a shoot and configure that shoot as a seed. The `type` should match the type of the underlying cluster.

The first entry of the `landscape.iaas` list is special:
- It has to exist - the list needs at least one entry.
- Don't specify the `cluster` node for it - it will configure your base cluster as seed.
  - Its `type` should match the one of your base cluster.

See the [advanced documentation](docs/extended/iaas.md) for more advanced configuration options and information about Openstack.

#### Shooted Seeds

It's also possible to have the setup create shoots and then configure them as seeds. This has advantages compared to configuring existing clusters as seeds, e.g. you don't have to provide the clusters as they will be created automatically, the shooted seed clusters can leverage the Gardener's autoscaling capabilities, ...

How to configure shooted seeds is explained in the [advanced documentation](docs/extended/iaas.md#shooted-seeds).

#### Credentials

The credentials will be used to give Gardener access to the IaaS layer:
* To create a secret that will be used on the Gardener dashboard to create shoot clusters.
* To allow the control plane of the seed clusters to store the etcd backups of the shoot clusters.

Use the following yaml keys depending on your provider (excerpts):

| <b>AWS</b>                                                                                                        | <b>GCP</b>                                                                                                                                                  |
|:----------------------------------------------------------------------------------------------------------------- |:----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <pre>credentials: <br/>  accessKeyID: ...<br/>  secretAccessKey: ... </pre>                                       | <pre>credentials: <br/>  serviceaccount.json: &#124;<br/>    {</br>      "type": "...",</br>      "project_id": "...",</br>      ...</br>    }</pre>        |
| <b>Azure</b>                                                                                                      | <b>Openstack</b>                                                                                                                                            |
| <pre>credentials:<br/>  clientID: ...<br/>  clientSecret: ...<br/>  subscriptionID: ...<br/>  tenantID: ...</pre> | <pre>credentials:<br/>  username: ...<br/>  password: ...<br/>  tenantName: ...<br/>  domainName: ...<br/>  authURL: ...<br/>  region: ... # DNS only</pre>        |
| <b>Alicloud</b>                                                                                                      | <b>Other</b>                                                                                                                                            |
| <pre>credentials:<br/>  accessKeyID: ...<br/>  accessKeySecret: ...</pre> | <pre></pre> |


The `region` field in the openstack credentials is only evaluated within the `dns` block (as `iaas` and `etcd.backup` have their own region fields, which will be used instead).


### landscape.etcd
```yaml
etcd:
  backup:
    # active: true
    type: <gcs|s3|abs|swift|oss>
    resourceGroup: ...
    region: (( iaas.region ))
    credentials: (( iaas.credentials ))
    # schedule: "0 */24 * * *"          # optional, default: 24h
    # maxBackups: 7                     # optional, default: 7
```
Configuration of what blob storage to use for the etcd key-value store. If your IaaS provider offers a blob storage you can use the same values for `etc.backup.region` and `etc.backup.credentials` as above for `iaas.region` and `iaas.credentials` correspondingly by using the [(( foo ))](https://github.com/mandelsoft/spiff/blob/master/README.md#-foo-) expression of spiff.
If the type of `landscape.iaas[0]` is one of `gcp`, `aws`, `azure`, `alicloud`, or `openstack`, this block can be defaulted - either partly or as a whole - based on values from `landscape.iaas`. The `resourceGroup`, which is necessary for Azure, cannot be defaulted and must be specified. Make sure that the specified `resourceGroup` is empty and unused as deleting the cluster using `sow delete all` deletes this `resourceGroup`.

| Field                  | Type                   | Description                                                                                                                                                                                                                                                                                                                                              | Example             | Iaas Provider Documentation                                                                                                                                                                                                                                                                                                     |
|:---------------------- |:---------------------- |:-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |:------------------- |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `backup.active`        | Boolean                | If set to `false`, deactivates the etcd backup for the virtual cluster etcd. Defaults to `true`.                                                                                                                                                                                                                                                         | `true`              | n.a.                                                                                                                                                                                                                                                                                                                            |
| `backup.type`          | Fixed value            | Type of your blob store. Supported blob stores: `gcs` ([Google Cloud Storage](https://cloud.google.com/storage/)), `s3` ([Amazon S3](https://aws.amazon.com/s3/)), `abs` ([Azure Blob Storage](https://docs.microsoft.com/en-us/azure/storage/blobs/storage-blobs-overview)), `oss` ([Alicloud Object Store](TBD)), and `swift` ([Openstack Swift](https://docs.openstack.org/swift/latest/)). | `gcs`               | n.a.                                                                                                                                                                                                                                                                                                                            |
| `backup.resourceGroup` | IaaS provider specific | Azure specific. Create an Azure blob store first which uses a resource group. Provide the resource group here.                                                                                                                                                                                                                                           | `my-Azure-RG`       | [Azure](https://docs.microsoft.com/en-us/azure/storage/common/storage-quickstart-create-account?tabs=azure-portal) (HowTo)                                                                                                                                                                                                      |
| `backup.region`        | IaaS provider specific | Region of blob storage.                                                                                                                                                                                                                                                                                                                                  | `(( iaas.region ))` | [GCP (overview)](https://cloud.google.com/docs/geography-and-regions), [AWS (overview)](https://docs.aws.amazon.com/general/latest/gr/rande.html)                                                                                                                                                                               |
| `backup.credentials`   | IaaS provider specific | Service account credentials in a provider-specific format.                                                                                                                                                                                                                                                                                               | `(( iaas.creds ))`  | [GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys), [AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html#id_users_service_accounts), [Azure](https://docs.microsoft.com/en-us/rest/api/storageservices/authorization-for-the-azure-storage-services) |


### landscape.dns
```yaml
dns:
  type: <google-clouddns|aws-route53|azure-dns|openstack-designate|cloudflare-dns|infoblox-dns>
  credentials:
```
Configuration for the Domain Name Service (DNS) provider. If your IaaS provider also offers a DNS service you can use the same values for `dns.credentials` as for `iaas.creds` above by using the [(( foo ))](https://github.com/mandelsoft/spiff/blob/master/README.md#-foo-) expression of spiff. If they belong to another account (or to another IaaS provider) the appropriate credentials (and their type) have to be configured.
Similar to `landscape.etcd`, this block - and parts of it - are optional if the type of `landscape.iaas[0]` is one of `gcp`, `aws`, `azure`, `alicloud`, or `openstack`. Missing values will be derived from `landscape.iaas`.

| Field         | Type                   | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         | Example                  | IaaS Provider Documentation                                                                                                                                                                                                                                                                                            |
|:------------- |:---------------------- |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |:------------------------ |:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `type`        | Fixed value            | Your DNS provider. Supported providers: `google-clouddns` ([Google Cloud DNS](https://cloud.google.com/dns/docs/)), `aws-route53` ([Amazon Route 53](https://aws.amazon.com/route53/)), `alicloud-dns` ([Alicloud DNS](TBD)), `azure-dns` ([Azure DNS](https://azure.microsoft.com/de-de/services/dns/)), `openstack-designate` ([Openstack Designate](https://docs.openstack.org/designate/latest/)), `cloudflare-dns` ([Cloudflare DNS](https://www.cloudflare.com/dns/)), and `infoblox-dns` ([Infoblox DNS](https://www.infoblox.com/products/dns/)). | `google-clouddns`        | n.a.                                                                                                                                                                                                                                                                                                                   |
| `credentials` | IaaS provider specific | Service account credentials in a provider-specific format (see above).                                                                                                                                                                                                                                                                                                                                                                                                                                              | `(( iaas.credentials ))` | [GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys), [AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html#id_users_service_accounts), [Azure](https://docs.microsoft.com/en-us/azure/azure-stack/user/azure-stack-create-service-principals) |

#### Cloudflare Credentials

The credentials to use Cloudflare DNS consist of a single key `apiToken`, containing your API token.

#### Infoblox Credentials and Configuration

For Infoblox DNS, you have to specify `USERNAME`, `PASSWORD`, and `HOST` in the `credentials` node. For a complete list of optional credentials keys see [here](https://github.com/gardener/external-dns-management/tree/master/docs/infoblox#create-secret-with-infoblox-credentials)

### landscape.identity
```yaml
identity:
  users:
    - email:
      username:
      password:
    - email:
      username:
      hash:
```

Configures the identity provider that allows access to the Gardener dashboard. The easiest method is to provide a list of `users`, each containing `email`, `username`, and either a clear-text `password` or a bcrypted `hash` of the password.
You can then login into the dashboard using one of the specified email/password combinations.

### landscape.ingress
```yaml
ingress:
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"  # example for internal loadbalancers on aws
    ...
```
You can add annotations for the ingress controller load balancer service. This can be used for example to deploy an internal load balancer on your cloud provider (see the example for aws above).

### landscape.cert-manager

```yaml
  cert-manager:
    email:                                   
    server: <live|staging|self-signed|url>
    privateKey: # optional
```

The setup deploys a [cert-manager](https://github.com/jetstack/cert-manager) to provide a certificate for the Gardener dashboard, which can be configured here.

The entire `landscape.cert-manager` block is optional.

If not specified, `landscape.cert-manager.server` defaults to `self-signed`. This means, that a selfs-signed CA will be created, which is used by the cert-manager (using a [CA issuer](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-ca.html)) to sign the certificate. Since the CA is not publicly trusted, your webbrowser will show a 'untrusted certificate' warning when accessing the dashboard.
The `landscape.cert-manager.email` field is not evaluated in `self-signed` mode.

If set to `live`, the cert-manager will use the [letsencrypt](https://letsencrypt.org/) ACME server to get trusted certificates for the dashboard. Beware the [rate limits](https://letsencrypt.org/docs/rate-limits/) of letsencrypt.
Letsencrypt requires an email address and will send information about expiring certificates to that address. If `landscape.cert-manager.email` is not specified, `landscape.identity.users[0].email` will be used. One of the two fields has to be present.

If set to `staging`, the cert-manager will use the letsencrypt staging server. This is for testing purposes mainly. The communication with letsencrypt works exactly as for the `live` case, but the staging server does not produce trusted certificates, so you will still get the browser warning. The rate limits are significantly higher for the staging server, though.

If set to anything else, it is assumed to be the URL of an ACME server and the setup will create an [ACME issuer](https://docs.cert-manager.io/en/latest/tasks/issuers/setup-acme/index.html) for it.

See the [advanced configuration](docs/extended/cert-manager.md) for more configuration options.

If the given email address is already registers at letsencrypt, you can specify the private key of the associated user account with `landscape.cert-manager.privateKey`.

## Uninstall Gardener

1. Run `sow delete -A` to delete all components from your base Kubernetes cluster in inverse order.

1. During the deletion, the corresponding contents in directories `gen`, `export`, and `state` in your `landscape` directory are deleted automatically as well.

## Most Important Commands and Directories

### Commands

These are the most important `sow` commands for deploying and deleting components:

| Command                     | Use                                                                                                     |
|:--------------------------- |:------------------------------------------------------------------------------------------------------- |
| `sow <component>`           | Same as `sow deploy <component>`.                                                                       |
| `sow delete <component>`    | Deletes a single component                                                                              |
| `sow delete -A`             | Deletes all components in the inverse order                                                             |
| `sow delete all`            | Same as `sow delete -A`                                                                                 |
| `sow delete -a <component>` | Deletes a component and all components that depend on it (including transitive dependencies)            |
| `sow deploy <component>`    | Deploys a single component. The deployment will fail if the dependencies have not been deployed before. |
| `sow deploy -A`             | Deploys all components in the order specified by `sow order -A`                                         |
| `sow deploy -An`            | Deploys all components that are not deployed yet                                                        |
| `sow deploy all`            | Same as `sow deploy -A`                                                                                 |
| `sow deploy -a <component>` | Deploys a component and all of its dependencies                                                         |
| `sow help`                  | Displays a command overview for sow                                                                     |
| `sow order -a <component>`  | Displays all dependencies of a given component (in the order they should be deployed in)                |
| `sow order -A`              | Displays the order in which all components can be deployed                                              |
| `sow url`                   | Displays the URL for the Gardener dashboard (after a successful installation)                           |

### Directories
After using sow to deploy the components, you will notice that there are new directories inside your landscape directory:

| Directory | Use                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                |
|:--------- |:---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `gen`     | Temporary files that are created during the deployment of components, for example, generated manifests.                                                                                                                                                                                                                                                                                                                                                                                                                            |
| `export`  | Allows communication (exports and imports) between components. It also contains the kubeconfig for the virtual cluster that handles the Gardener resources.                                                                                                                                                                                                                                                                                                                                                                        |
| `state`   | Important state information of the components is stored here, for example, the terraform state and generated certificates. It is crucial that this directory is not deleted while the landscape is active. While the contents of the *export* and *gen* directorys will be overwritten when a component is deployed again, the contents of *state* will be reused instead. In some cases, it is necessary to delete the state of a component before deploying it again, for example if you want to create new certificates for it. |
