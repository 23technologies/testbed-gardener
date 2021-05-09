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
All relevant steps happen in the ./terraform folder

Copy ``secure.yaml.sample`` to ``secure.yaml`` and ``clouds.yaml.sample`` to ``clouds.yaml``
and fill in the correct credentials for your openstack-cloud.

Adjust variables in environment/standard.tfvars to suit your needs.

## Build up Gardener

**make sure that no other testbed is already in the project.**

``make create`` creates the testbed:

1. creates management VM on the openstack (including networks, secgroups, ...)
2. creates bootstrap cluster via kind
3. creates production-cluster via cluster-api
4. deploys the external openstack-cloud-controller-manager
5. deploys gardener (including dashboard and seed)

At the end of a successful deployment, the URL, email and password for the login will be displayed.

## Teardown Gardener
#### Nice and slow
* Delete all Clusters inside gardener (via the dashboard or the API)
* ``make `` and ``sow burndown -A`` in folder ``landscape``
* ``make clean``
#### quick and rough
``make purge``

