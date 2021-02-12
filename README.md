# testbed-gardener

A virtual testbed environment for [Gardener](https://gardener.cloud).

You can watch a asciinema-demo [here](https://asciinema.org/a/390554).

## Required software

* Terraform must be installed (https://learn.hashicorp.com/tutorials/terraform/install-cli)
* ``terraform/clouds.yaml`` and ``terraform/secure.yaml`` files must be created
  (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)
* ospurge is required for project-cleanup (be careful):
``python3 -m pip install git+https://git.openstack.org/openstack/ospurge``

## Configuration
All relevant steps happen in the folder terraform

Copy ``secure.yaml.sample`` to ``secure.yaml`` and ``clouds.yaml.sample`` to ``clouds.yaml``
and fill in the correct credentials for your openstack-cloud.

Adjust variables in environment/standard.tfvars to suit your needs.

## Build up Gardener

**make sure that no other testbed is already in the project.**

``make create`` creates the testbed:

1. creates all relevant openstack resources, networks, securitygroups, dns-zones, VMs
2. creates kubernetes cluster with RKE on the VMs
3. deploys gardener, the gardener dashboard and a gardener-seed in the cluster
4. Installs keycloak and attaches it to gardener-dashboard

At the end of a successful deployment, the URL, email and password for the login will be displayed.

## Teardown Gardener
#### Nice and slow
* Delete all Clusters inside gardener (via the dashboard or the API)
* ``make `` and ``sow burndown -A`` in folder ``landscape``
* ``make clean``
#### quick and rough
``make purge``

