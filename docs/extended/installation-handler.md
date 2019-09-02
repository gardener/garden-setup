# Advanced Configuration Options: The Installation Handler

The `sow` tool allows to define installation handlers. An installation handler is basically a script that will be called before (with argument `prepare`) and after (with argument `finalize`) each call to `sow`.

Garden-setup contains one pre-defined installation handler ([here](../../bin/installation-handler)), which can do the following things:
- During the `finalize` step, it will tar each folder in `state` and `export`, base64-encode the result and put it into a kubernetes secret.
- During the `prepare` step, it will fetch all secrets from a given namespace with a certain label and extract their contents to the `state` and `export` folders, respectively.

This stores the state in your cluster and thus saves you from the necessity to preserve the disk of the machine from which you run `sow`. It is mainly useful if you are running garden-setup remotely or in some kind of pipeline where having to persist the disk is annoying. If you run `sow` from your own machine and persist the disk anyway, you most probably won't use this installation handler, as it also comes at a cost: creating and fetching secrets from the cluster significantly slows down each `sow` command.

> Do not switch on the installation handler on a garden-setup instance that already has state. The installation handler ignores and overwrites state on the disk and only takes into account what is stored in the secrets.

To configure it, use the following snippet in your acre.yaml file:
```yaml
meta:
  installationHandler:
    path: crop/bin/installation-handler
    config:
      kubeconfig: ./kubeconfig
      # namespace: garden-setup-state
      # backupLocation: (( env( "ROOT" ) ))
```

- `path` contains the path to the installation handler script, either absolute or relative to the `ROOT` directory.
- `config.kubeconfig` contains the path to the kubeconfig for the cluster you want to store your secrets into, similarly either absolute or relative to `ROOT`. Note that this can be the cluster you deploy the Gardener to, but it doesn't have to be.
- `config.namespace` is the namespace where the secrets will be deployed to. This field is optional and it defaults to `garden-setup-state`. The namespace manifest will be reapplied during every `finalize` step and the installation handler will create and delete secrets (with a certain label) in there, so be careful when modifying that namespace or the secrets within. Best practise: don't use that namespace for anything else. Do NOT delete the namespace as long as any secrets are in there!
- `config.backupLocation` specifies the directory where to store the manifests. See below for an explanation. 

## Error Handling

If an error occurs during the `prepare` step, neither the `sow` command, nor the `finalize` step will be executed.

During the `finalize` step, the installation handler first creates two manifest files in the specified backup location - one for the contents of the `state` folder and one for `export` - and then tries to apply the manifests to the cluster. If that fails for whatever reason, it will be retried a few times with a few seconds between each try. If it succeeds, the manifest files will be deleted. If not, the installation handler will tell you which file you will have to apply manually to the cluster and also print that file's content to the console.

> IMPORTANT: You have to apply these files before your next call to sow, otherwise that sow call will run with an inconsistent state!

## Files

A short overview over the files produced by the installation handler:

During `prepare`, the installation handler downloads the state from the cluster. To prevent mixing with locally saved state, it will rename the local `state` and `export` folders by appending `.bak`. Existing folders with the `.bak` suffix will be overwritten. The local folders are not deleted afterwards.

> The installation handler believes the state stored in the secrets to be the truth. Local state will be ignored/overwritten (except for the `gen` folder).

As mentioned above, the installation handler also creates manifest files in the specified backup location (`ROOT` by default). These manifest files are deleted after they have been successfully applied, so usually they only exist during the `finalize` step. In case of an error, the file in question won't be deleted and you have to delete it manually after applying it to the cluster. The backup files contain a timestamp in their name, so they won't overwrite each other.