# Advanced Configuration Options for 'landscape.gardener'

### Seed Candidate Determination Strategy
`landscape.gardener.seedCandidateDeterminationStrategy` has two possible values: `SameRegion` (default) and `MinimalDistance`. In the first case, shoots can only be created in regions where a seed exists and only those regions will show up in the dashboard. In the latter case, shoots can be created in any region listed in the cloudprofile and the geographically closest seed will be used.


### Network Policies
If `landscape.gardener.network-policies.active` is set to `true`, garden-setup will deploy network policies into the `garden` namespace. Currently, these are only egress rules for the 'virtual' kube-apiserver and the Gardener dashboard, other components or incoming traffic are not affected for now.

The default for `landscape.gardener.network-policies.active` is `false`, because the network policies have been shown to cause problems in some environments. It is planned to enable the policies by default, though, once the problems have been solved.