# Installation of Gardener base cluster on vSphere Tanzu Kubernetes Cluster (TKC)

*Note*: Support for TKC as base cluster is still in alpha and a moving target.

To use a TKC cluster (guest cluster) for the installation of Gardener, some steps are needed for preparation. Please take also a look at [vSphere / NSX-T Preparation for Gardener Extension](https://github.com/gardener/gardener-extension-provider-vsphere/blob/master/docs/prepare-vsphere.md) for preparing a seed cluster for running the **Provider vSphere** Extension.

After creating a TKC cluster, perform these steps:

1. Create a default storage class

   On the base cluster it is expected, that there is a default storage class. For this purpose create another storage class named `default-class` resembling the existing storage class managed by the supervisor cluster (same parameters etc.) and add the default-class annotation:

   ```bash
   kubectl annotate storageclass default-class storageclass.kubernetes.io/is-default-class=true
   ```

2. Deploy `ClusterRoleBinding`s for `PodSecurityPolicy`

    Tanzu Kubernetes Grid Service provisions Tanzu Kubernetes clusters with the PodSecurityPolicy Admission Controller enabled, see [Using Pod Security Policies with Tanzu Kubernetes Clusters](https://docs.vmware.com/en/VMware-vSphere/7.0/vmware-vsphere-with-tanzu/GUID-CD033D1D-BAD2-41C4-A46F-647A560BAEAB.html).

    The easierst solution is to add `ClusterRoleBindings` to disable the PSP restrictions for authenticated users.

    ```bash
    cat << EOF | kubectl apply -f -
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      annotations:
        gardener.cloud/description: |
          Allow all authenticated users to use the privileged PSP.
          The subject field is configured via .spec.kubernetes.allowPrivilegedContainers flag on the Shoot resource.
      name: gardener.cloud:psp:privileged
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      #name: gardener.cloud:psp:privileged
      name: psp:vmware-system-privileged
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:authenticated
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      annotations:
        gardener.cloud/description: |
          Allow all authenticated users to use the unprivileged PSP.
      name: gardener.cloud:psp:unprivileged
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      #name: gardener.cloud:psp:unprivileged
      name: psp:vmware-system-restricted
    subjects:
    - apiGroup: rbac.authorization.k8s.io
      kind: Group
      name: system:authenticated
    EOF
    ```
