# Makefile

# set the env we used 
ENVIRONMENT = gx-scs
#ENVIRONMENT = gx-citycloud
#ENVIRONMENT = gx-scs
#ENVIRONMENT = gx-citycloud
OPENSTACK = openstack
USERNAME = ubuntu
CONSOLE = capi-mgmtcluster

# check for openstack credentials
NEED_OSCLOUD := $(shell test -z "$$OS_PASSWORD" -a -z "$$OS_CLOUD" && echo 1 || echo 0)
ifeq ($(NEED_OSCLOUD),1)
  export OS_CLOUD=$(ENVIRONMENT)
endif

create:
	@rm -rf k8s-cluster-api-provider
	@git clone https://github.com/SovereignCloudStack/k8s-cluster-api-provider.git
	@cp secure.yaml k8s-cluster-api-provider/terraform/
	@cp clouds.yaml k8s-cluster-api-provider/terraform/
	@cp extension-files/* k8s-cluster-api-provider/terraform/extension/
	@cp environments/environment-$(ENVIRONMENT).tfvars k8s-cluster-api-provider/terraform/extension/variables.tf
	@cd k8s-cluster-api-provider/terraform && make create ENVIRONMENT=$(ENVIRONMENT)

purge:
	@cd k8s-cluster-api-provider/terraform && make purge ENVIRONMENT=$(ENVIRONMENT)
	@rm -rf k8s-cluster-api-provider

ssh:
	@cd k8s-cluster-api-provider/terraform && make ssh ENVIRONMENT=$(ENVIRONMENT)

openstack:
	@$(OPENSTACK)

PHONY: clean console attach detach ssh dry-run list deploy watch openstack create log console login k9s 
