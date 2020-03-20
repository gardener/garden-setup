# Advanced Configuration Options for 'landscape.identity'

The Gardener dashboard uses [dex](https://github.com/dexidp/dex) for identity management. Users can be specified in the `acre.yaml` file in two different ways, which are explained below. It is possible to combine both variants by specifying `landscape.identity.users` and `landscape.identity.connectors`.

#### Privileges

The `dashboard` component deploys two `ClusterRoleBinding`s for privileges (both binding to the `ClusterRole` with the same name, respectively):
- membership in `gardener.cloud:system:project-creation` allows a user to create projects (and thus clusters).
- membership in `gardener.cloud:system:administrators` grants a user operator privileges, providing access to all projects and clusters.
  - :warning: This means that the user also has access to all infrastructure credentials!

Of the variants below,
- variant 1 adds each user to both groups, thus granting admin privileges
- variant 2 doesn't add users to any group, thus granting no privileges

#### Variant 1: hard-coded users
```yaml
  identity:
    users:
      - email: "administrator@example.com"
        username: "Admin"
        password: "myTotallySafePassword#111"
        # hash: instead of a clear-text password, also a bcrypted hash is possible
```
In `landscape.identity.users`, a list of hard-coded users can be specified. They will be able to login into the dashboard using the email and password. 


#### Variant 2: OIDC connector
```yaml
  identity:
    connectors:
      - type: github
        id: github
        name: GitHub
        config:
          clientID: $GITHUB_CLIENT_ID
          clientSecret: $GITHUB_CLIENT_SECRET
          redirectURI: http://example.com/oidc/callback
          orgs:
          - name: my-gardener-users
          teamNameField: slug
```
In addition to providing a list of hard-coded users, it is also possible to connect dex to another identity provider (e.g. GitHub, SAML, ...). The request will then be forwarded and handled by the specified IDP.

For a list of possible connectors and how to configure them, please check the documentation at https://github.com/dexidp/dex/tree/master/Documentation/connectors.
