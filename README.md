# Install Gardener on your Kubernetes Landscape

Gardener uses Kubernetes to manage Kubernetes clusters. This documentation describes how to install Gardener on an existing Kubernetes cluster of your IaaS provider.
> Where reference is made in this document to the *base cluster*, we are actually referring to the existing cluster where you will install Gardener. This helps to distinguish them from the clusters that you will create after the installation using Gardener. Once it's installed, it is also referred to as *garden cluster*. Whenever you create clusters, Gardener will create *seed clusters* and *shoot clusters*. In this documentation we will only cover the installation of clusters in one region of one IaaS provider. More information: [Architecture](https://gardener.cloud/030-architecture/).

## Prerequisites

* The installation was tested on Linux and MacOS
* You need to have the following tools installed:
  * [Docker](https://docs.docker.com/install/)
  * [git](https://git-scm.com/downloads)
  * [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
* You need a *base cluster*. Currently, the installation tools supports to install Gardener on the following Kubernetes clusters:
  * [Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-cluster) on Google Cloud Platform (GCP)
  * [Elastic Container Service for Kubernetes (EKS)](https://docs.aws.amazon.com/eks/) or [Kubernetes Operations (kops)](https://github.com/kubernetes/kops) on Amazon Web Services (AWS)
  * [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/) on Microsoft Azure
* Your base cluster needs at least 4 nodes with a size of 8GB for each node
* You need a service account for the virtual machine instance of your IaaS provider where your Kubernetes version runs
* You need to have permissions to access your base cluster's private key
* You are connected to your Kubernetes cluster (environment variable `KUBECONFIG` is set)
  * [Viewing kubeconfig (GKE)](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#viewing_kubeconfig)
  * [Create a kubeconfig for Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/create-kubeconfig.html)
  * [Use Azure role-based access controls to define access to the Kubernetes configuration file in Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/control-kubeconfig-access)

## Procedure

1. Clone the `sow` repository and build a Docker image that contains the command line tool [sow](https://github.com/gardener/sow) and all tools `sow` requires. Once the image is built and you have added the path to our [wrapper script](https://github.com/gardener/sow/blame/master/docker/bin/sow) to your `PATH` variable you can call `sow` on the command line.

    ```bash
    # setup for calling sow via the wrapper
    git clone "https://github.com/gardener/sow"
    cd sow
    make # will build and tag the image
    export PATH=$PATH:$PWD/docker/bin
    ```

    > The wrapper script starts `sow` in a Docker container, executes the sow command with the given arguments, and then exits and removes the container again. The script also mounts parts of your file system into that container to allow `sow` to persist the state in directory `landscape` which you will create in the next step.

1. Create a directory for your Gardener landscape and clone this repository into a subdirectory called `crop`:

    ```bash
    mkdir landscape
    cd landscape
    git clone "https://github.com/gardener/garden-setup" crop
    ```

1. In your landscape folder, create a configuration file called `acre.yaml`. The structure of the configuration file is described [below](#configuration-file-acreyaml).

    > Do not use file `acre.yaml` in folder `crop`. This file is used internally by the installation tool.

1. If you created the base cluster using GKE you need to convert your `KUBECONFIG` to one that uses basic authentication with Google-specific configuration parameters:

    1. Set your `KUBECONFIG` environment variable to a file that does not exist. Do *not* use the one specified in your acre.yaml file.

    1. Download the GKE kubeconfig:

        ```bash
        gcloud container clusters get-credentials <your_cluster> --zone <your_zone> --project <your_project>
        ```

    1. Call `crop/bin/convertkubeconfig 3.1`. When asked for credentials, enter the ones that the GKE dashboard shows when clicking on `show credentials`.

    This will create a kubeconfig that uses basic auth. It will be created at the path specified in your `acre.yaml` file.

1. Open a second terminal window and enter the following command to watch the progress of the Gardener installation:

    ```bash
    watch -d kubectl -n garden get pods,ingress,sts,svc
    ```

1. In your first terminal window, use the following command to deploy Gardener on your base cluster:

    ```bash
    sow deploy -A
    ```

`sow` now starts to install Gardener in your base cluster. The installation can take about 30 minutes. `sow` prints out status messages to the terminal window so that you can check the state of the installation. The other terminal window will show the newly created Kubernetes resources after a while and if their deployment was successful (their status should be `Running`). Finally, the Gardener dashboard is deployed. The last status message before `sow` exits is something like this:
```bash
===================================================================
Dashboard URL -> https://gardener.ingress.<value of `landscape.cluster.domain`>
===================================================================
generating exports
*** species dashboard deployed
```  

More information: [Most Important Commands and Directories](#most-important-commands-and-directories)

## Configuration File acre.yaml

This file will be evaluated using `spiff`, a dynamic templating language for yaml files. For example, this simplifies the specification of field values that are used multiple times in the yaml file. For more information, see the [spiff repository](https://github.com/mandelsoft/spiff/blob/master/README.md).

<pre>
landscape:
  <a href="#landscapename">name</a>: &lt;URL-friendly name&gt;                       # Gardener managed k8s landscape name

  <a href="#landscapecluster">cluster</a>:                                          # Information about your base cluster
    kubeconfig: &lt;relative path + filename&gt;          # Path to your `kubeconfig` file, rel. to folder `landscape`
    domain: &lt;prefix&gt;.&lt;cluster domain&gt;               # Unique basis domain for DNS entries
    iaas: &lt;gcp|aws|azure&gt;                           # iaas provider (coming soon: openstack|alicloud)
    region: &lt;major region&gt;-&lt;minor region&gt;           # Example: europe-west1

  <a href="#landscapenetworks">networks</a>:                                         # <a target="_blank" rel="noopener noreferrer" href="https://en.wikipedia.org/wiki/Classless_Inter-Domain_Routing">CIDR IP ranges</a> of base cluster
    nodes: &lt;CIDR IP range&gt;                                  
    pods: &lt;CIDR IP range&gt;                                   
    services: &lt;CIDR IP range&gt;                             

  <a href="#landscapeiaas">iaas</a>:
    region: &lt;major region&gt;-&lt;minor region&gt;      # region that Gardener will use for seed clusters
    zones:
      - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # Example: europe-west1-b
      - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # Example: europe-west1-c     
      - &lt;major region&gt;-&lt;minor region&gt;-&lt;zone&gt;   # Example: europe-west1-d
    credentials:                               # credentials to get access to the seed cluster through service account

  <a href="#landscapeetcd">etcd</a>:
    backup:
      type: &lt;gcs|s3&gt;                    # type of blob storage
      region: (( iaas.region ))         # region of blob storage (default: same as above)
      credentials: (( iaas.creds ))     # credentials for the blob storage's IaaS provider (default: same as above)

  <a href="#landscapedns">dns</a>:
    type: &lt;google-clouddns|aws-route53&gt;       # dns provider
    hostedZoneID:                             # hosted zone id for chosen domain
    credentials:                              # credentials for the dns provider

  <a href="#landscapeidentity">identity</a>:
    users:
      - email:                                # email (used for Gardener dashboard login)
        username:                             # username (displayed in Gardener dashboard)
        password:                             # clear-text password (used for Gardener dashboard login)
      - email:                                # see above
        username:                             # see above
        hash:                                 # bcrypted hash of password, see above
</pre>


### landscape.name
```yaml
landscape:
  name: <URL-friendly name>                       # Gardener managed k8s landscape name
```
Arbitrary name for your landscape. Will partly be used for naming of resources, for example, the etcd buckets.

### landscape.cluster
```yaml
cluster:                                            # Information about your base cluster
  kubeconfig: <relative path + filename>            # Path to your `kubeconfig` file, relative to folder `landscape`   
  domain: <prefix>.<cluster domain>                 # Unique basis domain for DNS entries
  iaas: <gcp|aws|azure>                             # IaaS provider (coming soon: openstack|alicloud)
  region: <major region>-<minor region>             # Example: europe-west1
```

Information about your base cluster, where the Gardener will be deployed on.

| Field | Type | Description | Example |
|:------|:--------|:--------|:--------|
|`kubeconfig`|File path| Path to your kubeconfig, relative to your landscape folder. It is recommended to create a kubeconfig file in your landscape folder to be able to sync all files relevant for your installation with a git repository.| `./kubeconfig` |
|`domain`| Unique name| Basis domain for DNS entries. As a best practice, use an individual prefix together with the cluster domain of your base cluster.|`vedge.gcp.dev.k8s.jacksgrocerystore.com`|
|`iaas`| Fixed value | IaaS provider you would like to install Gardener on. | `gcp` |
|`region`|IaaS provider specific| Region where your Kubernetes base cluster is deployed. | `europe-west1` (GCP)|

### landscape.networks
```yaml
networks:                                 # CIDR IP ranges of base cluster
  nodes: <CIDR IP range>                                  
  pods: <CIDR IP range>                                   
  services: <CIDR IP range>
```
CIDR ranges of your base cluster.

Finding out CIDR ranges of your cluster is not trivial. For example, GKE only tells you a "pod address range" which is actually a combination of pod and service CIDR. However, since the `kubernetes` service typically has the first IP of the service IP range and most methods to get a kubernetes cluster tell you at least something about the CIDRs, it is usually possible to find out the CIDRs with a little bit of educated guessing.

### landscape.iaas
```yaml
iaas:
  region: <major region>-<minor region>             # region that Gardener will use for seed clusters
  zones:
    - <major region>-<minor region>-<zone>          # Example: europe-west1-b
    - <major region>-<minor region>-<zone>          # Example: europe-west1-c     
    - <major region>-<minor region>-<zone>          # Example: europe-west1-d
  credentials:                                      # credentials to get access to the seed cluster through service account
```
Contains the information where Gardener will create seed clusters. By default, the *initial* seed component will create a seed resource using your base cluster as seed cluster.

| Field | Type | Description | Example |Iaas Provider Documentation |
|:------|:--------|:--------|:--------|:--------|
|`region`|IaaS provider specific|Region where Gardener will create seed clusters and shoot clusters. | `europe-west1`|[GCP (HowTo)](https://cloud.google.com/kubernetes-engine/docs/how-to/managing-clusters#viewing_your_clusters), [GCP (overview)](https://cloud.google.com/docs/geography-and-regions); [AWS (HowTo)](https://docs.aws.amazon.com/cli/latest/reference/eks/describe-cluster.html), [AWS (Overview)](https://docs.aws.amazon.com/general/latest/gr/rande.html)|
|`zones`|IaaS provider specific|Zones where Gardener will create seed clusters and shoot clusters. |`europe-west1-b`|[GCP (HowTo)](https://cloud.google.com/kubernetes-engine/docs/how-to/managing-clusters#viewing_your_clusters), [GCP (overview)](https://cloud.google.com/docs/geography-and-regions); [AWS (HowTo)](https://docs.aws.amazon.com/cli/latest/reference/eks/describe-cluster.html), [AWS (Overview)](https://docs.aws.amazon.com/general/latest/gr/rande.html)|
|`creds`|IaaS provider specific|Service account credentials in a provider-specific format. | `serviceaccount.json: { <credentials> }` (GCP) | [GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys), [AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html#id_users_service_accounts)|

The service account credentials will be used to give Gardener access to your base cluster:
* To create a secret that will be used on the Gardener dashboard to create shoot clusters.
* The control plane of the seed clusters will use this secret to store the etcd backups of the shoot clusters.

### landscape.etcd
```yaml
etcd:
  backup:
    type: <gcs|s3>                    # type of blob storage
    region: (( iaas.region ))         # region of blob storage (default: same as above)
    credentials: (( iaas.creds ))     # credentials for the blob storage's IaaS provider (default: same as above)
```
Configuration of what blob storage to use for the etcd key-value store. If your IaaS provider offers a blob storage you can use the same values for `etc.backup.region` and `etc.backup.credentials` as above for `iaas.region` and `iaas.credentials` correspondingly by using the [(( foo ))](https://github.com/mandelsoft/spiff/blob/master/README.md#-foo-) expression of spiff.

| Field | Type | Description | Example&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Iaas Provider Documentation |
|:------|:--------|:--------|:--------|:---------|
|`backup.type`|Fixed value| Type of your blob store. Supported blob stores: `gcs` ([Google Cloud Storage](https://cloud.google.com/storage/)), and `s3` ([Amazon S3](https://aws.amazon.com/s3/)).|`gcs`|n.a.|
|`backup.region`|IaaS provider specific|Region of blob storage. |`(( iaas.region ))` |[GCP (overview)](https://cloud.google.com/docs/geography-and-regions), [AWS (overview)](https://docs.aws.amazon.com/general/latest/gr/rande.html)|
|`backup.credentials`|IaaS provider specific|Service account credentials in a provider-specific format. |`(( iaas.creds ))` |[GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys), [AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html#id_users_service_accounts)|


### landscape.dns
```yaml
dns:
  type: <google-clouddns|aws-route53>       # dns provider
  hostedZoneID:                             # hosted zone id for chosen domain
  credentials:                              # credentials for the dns provider
```
Configuration for the Domain Name Service (DNS) provider. If your IaaS provider offers a DNS you can use the same values for `dns.credentials` as for `iaas.creds` above by using the [(( foo ))](https://github.com/mandelsoft/spiff/blob/master/README.md#-foo-) expression of spiff.

| Field | Type | Description | Example |IaaS Provider Documentation
|:------|:--------|:--------|:--------|:------------|
|`type`|Fixed value|Your DNS provider. Supported providers: `google-clouddns` ([Google Cloud DNS](https://cloud.google.com/dns/docs/)), and `aws_route53` ([Amazon Route 53](https://aws.amazon.com/route53/)).|`google-clouddns`|n.a.|
|`hostendZoneID`| k8s domain| The domain of your base cluster (replace dots with dashes).|`gcp.dev.k8s.jacksgrocerystore.com`|[GCP](https://cloud.google.com/sdk/gcloud/reference/dns/managed-zones/list), [AWS](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/ListInfoOnHostedZone.html)|
|`credentials`|IaaS provider specific|Service account credentials in a provider-specific format.|`(( iaas.creds ))`|[GCP](https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys), [AWS](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users.html#id_users_service_accounts)|


### landscape.identity
```yaml
identity:
  users:
    - email:                                # email (used for Gardener dashboard login)
      username:                             # username (displayed in Gardener dashboard)
      password:                             # clear-text password (used for Gardener dashboard login)
    - email:                                # see above
      username:                             # see above
      hash:                                 # bcrypted hash of password, see above
```

Configures the identity provider that allows access to the Gardener dashboard. The easiest method is to provide a list of `users`, each containing `email`, `username`, and either a clear-text `password` or a bcrypted `hash` of the password.
You can then login into the dashboard using one of the specified email/password combinations.

## Most Important Commands and Directories

### Commands

These are the most important `sow` commands for deploying and deleting components:

| Command&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp; &nbsp; &nbsp; &nbsp; &nbsp; &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | Use              |
|:------------------------------|:-----------------|
| `sow help`| Displays a command overview for sow |
| `sow order -a <component>` | Displays all dependencies of a given component (in the order they should be deployed in) |
| `sow deploy -a <component>` | Deploys a component and all of its dependencies |
| `sow delete -a <component>` | Deletes a component and all components that depend on it (including transitive dependencies) |
|`sow deploy <component>`|Deploys a single component. The deployment will fail if the dependencies have not been deployed before. |
|`sow <component>`| Same as `sow deploy <component>`.|
|`sow delete <component>`|Deletes a single component|
|`sow order -A`|Displays the order in which all components can be deployed|
|`sow deploy -A`|Deploys all components in the order specified by `sow order -A`|
|`sow delete -A`|Deletes all components in the inverse order|

### Directories
After using sow to deploy the components, you will notice that there are new directories inside your landscape folder:

| Directory               | Use              |
|:------------------------|:-----------------|
| `gen`| Temporary files that are created during the deployment of components, e.g. generated manifests. |
| `export` | Allows communication (exports and imports) between components.It also contains the kubeconfig for the virtual cluster that handles the Gardener resources. |
| `state` | Important state information of the components is stored here, e.g. the terraform state and generated certificates. It is crucial that this directory is not deleted while the landscape is active. While the contents of the *export* and *gen* folders will be overwritten when a component is deployed again, the contents of *state* will be reused instead. In some cases, it is necessary to delete the state of a component before deploying it again, for example if you want to create new certificates for it.|

#### Deleting Directories
The `gen` directory can be safely deleted at any time, except *during* the deployment of a component.
Best practise is to delete all of the directories *after* tearing a landscape down *before* setting it up anew and - in case of `export` and `state` - **only** then. Although sometimes it might be necessary to delete the state/export of a specific component in order to redeploy it.
