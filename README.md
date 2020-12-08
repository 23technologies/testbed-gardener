# testbed-gardener

A virtual testbed environment for [Gardener](https://gardener.cloud).

The necessary Kubernetes cluster for the seed is built with [K3s](https://k3s.io)
on OpenStack instances previously provided by Terraform.

A documentation with the individual steps can be found in the repository
[gardener/garden-setup](https://github.com/gardener/garden-setup).

## Limitations

* Because of the missing S3 Terraform backend integration only a single testbed can be used in a project.

## Preparations

* Terraform must be installed (https://learn.hashicorp.com/tutorials/terraform/install-cli)
* ``terraform/clouds.yaml`` and ``terraform/secure.yaml`` files must be created
  (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)
* ``terraform/files/gx-scs/credentials.yaml`` file must be created

## Usage

**Before use, make sure that no other testbed is already in the project.**

### Build up Gardener
* ``make create``
* ``make deploy`` (or: ``make login`` followed by ``bash deploy.sh``)

### Teardown Gardener
* Delete all Clusters inside gardener (via the dashboard or the API)
* ``make login`` and ``sow burndown -A`` in folder ``landscape``
* ``make clean``
