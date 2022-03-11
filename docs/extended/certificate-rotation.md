# How to Rotate the Base Cluster Certificates

## Introduction

This guide outlines how to rotate the certificates of the garden base cluster
by using `sow` and Gardener reconciliation mechanisms.
Use this guide if you need to rotate your base cluster's certificates. It
does not cover the rotation of subsequent resources like Shoot or Seed CAs.

This guide assumes you have followed the installation steps outlined in the
`readme.md` of this repository and have used the described directory structure.

This guide further assumes that the state in your landscape repository is
in sync with your live garden installation and everything is currently healthy.
If the above is not the case, first ensure it is.

## How it works in a Nutshell

The garden base cluster certificates for the virtual garden are all created by
`sow`. That's why rotating them means we need to remove some folders from the
`landscape` repo and re-deploy with sow.

## Steps

1. Backup the following folders

    ```shell
    export/etcd/cluster
    export/kube-apiserver
    export/gardener/virtual
    export/gardener/runtime
    export/gardencontent/seeds/soils

    state/etcd/cluster
    state/kube-apiserver
    state/gardener/virtual
    state/gardener/runtime
    state/gardencontent/seeds/soils
    ```

2. From your vGarden backup the `Project` definitions unless you already
   deploy them in a GitOps fashion and can easily recreate them:
   `kubectl get project -A -oyaml > projects.yaml`

   The reason is that the `members` will be reset to the default by the
   `sow` rollout.

3. Then delete all the original folders (`gen` can always be recreated):

    ```shell
    #!/bin/bash

    set -e -o pipefail

    rm -rf export/etcd/cluster
    rm -rf export/kube-apiserver
    rm -rf export/gardener/virtual
    rm -rf export/gardener/runtime
    rm -rf export/gardencontent/seeds/soils

    rm -rf gen/etcd/cluster
    rm -rf gen/kube-apiserver
    rm -rf gen/gardener/virtual
    rm -rf gen/gardener/runtime
    rm -rf gen/gardencontent/seeds/soils

    rm -rf state/etcd/cluster
    rm -rf state/kube-apiserver
    rm -rf state/gardener/virtual
    rm -rf state/gardener/runtime
    rm -rf state/gardencontent/seeds/soils
    ```

4. Then redeploy with `sow` from with the landscape repository:

   ```shell
   sow deploy -A
   ```

   This will get stuck at the `gardener/runtime` when waiting for the
   gardener-apiserver to become ready, so cancel it with CTRL-C.
5. To unlock the progress, delete the following items:
    1. Open a new terminal and use the newly created kubeconfig from
       `export/kube-apiserver/kubeconfig`:
       `export KUBECONFIG=./export/kube-apiserver/kubeconfig`
    2. Then, in the vGarden, remove all secrets of type
       `kubernetes.io/service-account-token` as they are invalid anyway now.
       They will be recreated immediately by the api server
    3. Then re-run `sow deploy gardener/virtual gardener/runtime` this will
       read out all the new tokens from the virtual garden and deploy them to the
       base cluster so the control plane components start working again.
       You might have to restart some pods in the `garden` namespace to get
       this going faster or at all.
6. Delete `kubectl -n garden delete secret gardenlet-kubeconfig` on the base
   cluster (GKE), then restart the gardenlet
7. Run `sow deploy gardener/extensions gardencontent/gardenproject gardencontent/seeds/soils dashboard`
8. Now for every ShootedSeed, do the following:
   1. Login to the ShootedSeed cluster
   2. Delete the `gardenlet-kubeconfig` secret:
      `kubectl -n garden delete secret gardenlet-kubeconfig`
   3. Login to the base cluster again and restart the gardenlet:
      `kubectl -n garden rollout restart deploy gardenlet`
   4. That should recreate the gardenlet-kubeconfig secret and enables a
      restart of the gardenlet
9. Finally reapply your garden projects to the vGarden to provide everybody
   access permissions again
