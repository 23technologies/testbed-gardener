# testbed-gardener-openstack

A virtual testbed environment for [Gardener](https://gardener.cloud).

The necessary Kubernetes cluster for the seed is built with [K3s](https://k3s.io)
on OpenStack instances previously provided by Terraform.

A documentation with the individual steps can be found in the repository
[gardener/garden-setup](https://github.com/gardener/garden-setup).

## Limitations

* The DNS integration is currently missing. Therefore the existing floating IP address
  ``213.131.230.153`` must currently be used for the primary node. ``*.gardener.okeanos.xyz``
  resolve to this address.
* Because of the missing DNS integration and the missing S3 Terraform backend integration
  only a single testbed can be used in a project.

## Preparations

* Terraform must be installed (https://learn.hashicorp.com/tutorials/terraform/install-cli)
* ``terraform/clouds.yaml`` and ``terraform/secure.yaml`` files must be created
  (https://docs.openstack.org/python-openstackclient/latest/configuration/index.html#clouds-yaml)
* ``terraform/files/gx-scs/credentials.yaml`` file must be created

## Usage

**Before use, make sure that no other testbed is already in the project.**

* ``make attach PARAMS=da1a42e3-8705-4d24-94f7-3f5001ad0521``
* ``make create``
* ``make deploy`` (or: ``make login`` followed by ``bash deploy.sh``)
* ``make detach``
* ``make clean``
