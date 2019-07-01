# Extended Configuration Options for 'landscape.dashboard'

The `landscape.dashboard` node is entirely optional. There are basically two nodes in it that are evaluated:
- `landscape.dashboard.frontendConfig`
- `landscape.dashboard.gitHub`

The contents of both nodes will be given directly to the [dashboard helm chart](https://github.com/gardener/dashboard/blob/master/charts/gardener-dashboard/values.yaml), so you can overwrite the corresponding default values. 

Please note that `frontendConfig.seedCandidateDeterminationStrategy` can not be overwritten here, as that value is derived from the Gardener. You can overwrite it [here](gardener.md).