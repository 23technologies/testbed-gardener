# Makefile

CONSOLE = mgmt
ENVIRONMENT = gx-scs-staging
OPENSTACK = openstack
USERNAME = ubuntu

RESOURCE = openstack_networking_floatingip_v2.main_floating_ip
STATE = errored.tfstate

NEED_OSCLOUD := $(shell test -z "$$OS_PASSWORD" -a -z "$$OS_CLOUD" && echo 1 || echo 0)
ifeq ($(NEED_OSCLOUD),1)
  export OS_CLOUD=$(ENVIRONMENT)
endif

ifneq (,$(wildcard ./minio.env))
  include minio.env
endif

init:
	@if [ ! -d .terraform/plugins ]; then terraform init; fi

	@terraform workspace select ${ENVIRONMENT} || terraform workspace new ${ENVIRONMENT}

attach: init
	@terraform import -var-file="environment-$(ENVIRONMENT).tfvars" $(RESOURCE) $(PARAMS)

detach: init
	@terraform state rm $(RESOURCE) $(PARAMS)

state-push: init
	@terraform state push $(STATE)

dry-run: init
	@terraform plan -var-file="environment-$(ENVIRONMENT).tfvars" $(PARAMS)

create: init
	@touch .deploy.$(ENVIRONMENT)
	@terraform apply -auto-approve -var-file="environment-$(ENVIRONMENT).tfvars"

show: init
	@terraform show

clean: init
	@terraform destroy -auto-approve -var-file="environment-$(ENVIRONMENT).tfvars" $(PARAMS)
	@rm -f .deploy.$(ENVIRONMENT) .MGMT_ADDRESS.$(ENVIRONMENT)
	@rm -f .id_rsa.$(ENVIRONMENT)
	@terraform workspace select default
	@terraform workspace delete $(ENVIRONMENT)

purge:
	@echo "Warning, going to delete ALL resources in $(ENVIRONMENT), even those that have not been created by the testbed."
	@read -p "Continue? (y/n) " -r; \
        if [[ ! $$REPLY =~ ^[Yy] ]]; \
        then \
			exit 1; \
        fi
	@ospurge --purge-own-project --os-cloud $(ENVIRONMENT) --verbose
	@rm -f .deploy.$(ENVIRONMENT) .MGMT_ADDRESS.$(ENVIRONMENT)
	@rm -f .id_rsa.$(ENVIRONMENT)
	@terraform workspace select default
	@terraform workspace delete -force $(ENVIRONMENT) 
	@openstack keypair delete garden-cluster-$(ENVIRONMENT)
	@ospurge --purge-own-project --os-cloud $(ENVIRONMENT) --verbose

purge-ssh-keys:
	for i in `openstack --os-cloud $(ENVIROMENT) keypair list -c Name -f value`; do openstack keypair delete $$i; done

list: init
	@terraform state list

ssh: .MGMT_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.MGMT_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -o IdentitiesOnly=yes -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MGMT_ADDRESS

deploy: .MGMT_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.MGMT_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MGMT_ADDRESS "bash deploy.sh"

sshuttle: .MGMT_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.MGMT_ADDRESS.$(ENVIRONMENT); \
	sshuttle --ssh-cmd "ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) " -r $(USERNAME)@$$MGMT_ADDRESS 10.40.0.0/16

console: .deploy.$(ENVIRONMENT)
	@$(OPENSTACK) console log show garden-cluster-$(CONSOLE)

.deploy.$(ENVIRONMENT): init
	@STAT=$$(terraform state list); \
	if test -n "$$STAT"; then touch .deploy.$(ENVIRONMENT); else echo "use make deploy"; exit 1; fi

.MGMT_ADDRESS.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@MGMT_ADDRESS=$$(terraform output mgmt_address); \
	echo "MGMT_ADDRESS=$$MGMT_ADDRESS" > $@;

.id_rsa.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@PRIVATE_KEY=$$(terraform output private_key); \
	echo "$$PRIVATE_KEY" > $@; \
        chmod 0600 $@

watch: .id_rsa.$(ENVIRONMENT) .MGMT_ADDRESS.$(ENVIRONMENT)
	@source ./.MGMT_ADDRESS.$(ENVIRONMENT); \
	DISP=0; \
	if test "$$COLORTERM" = "1"; then \
	  GREEN=$$(echo -e "\e[0;32m"); GREENBOLD=$$(echo -e "\e[1;32m"); BOLD=$$(echo -e "\e[0;1m"); RED=$$(echo -e "\e[0;31m"); YELLOW=$$(echo -e "\e[0;33m"); NORM=$$(echo -e "\e[0;0m"); \
	fi; \
	while true; do \
		LEN=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MGMT_ADDRESS sudo wc -l /var/log/cloud-init-output.log 2>/dev/null); \
		LEN=$${LEN%% *}; \
		if test -n "$$LEN" -a "$$LEN" != "$$DISP"; then \
		  OUT=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MGMT_ADDRESS sudo tail -n $$((LEN-DISP)) /var/log/cloud-init-output.log 2>/dev/null); \
		  echo -e "$$OUT" | sed -e "s/^\(TASK.*\)$$/$$BOLD\1$$NORM/" -e "s/^\(PLAY.*\)$$/$$GREEN\1$$NORM/" -e "s/^\(The system is finally up.*\)$$/$$GREENBOLD\1$$NORM/" -e "s/\(FAILED\)/$$RED\1$$NORM/g" -e "s/\(failed=[1-9][0-9]*\|unreachable=[1-9][0-9]*\)/$$RED\1$$NORM/g" -e "s/\(warn\|WARN\|RETRYING\)/$$YELLOW\1$$NORM/" -e "s/\(ok:\|ok=[0-9]*\)/$$GREEN\1$$NORM/"; \
		  if echo "$$OUT" | grep '^The system is finally up' >/dev/null 2>&1; then break; fi; \
		  DISP=$$LEN; \
		  sleep 5; \
		fi; \
	done;
	#@$(OPENSTACK) server list

openstack: init
	@$(OPENSTACK)

dashboard: .MGMT_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.MGMT_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MGMT_ADDRESS "pkill -f 'kubectl proxy'"; \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MGMT_ADDRESS "kubectl -n kubernetes-dashboard describe secret"; \
	echo http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy; \
	ssh -L 8001:localhost:8001 -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$MGMT_ADDRESS "kubectl proxy"

login: ssh
log: console
tunnel: sshuttle

PHONY: clean purge console attach detach sshuttle ssh dry-run list deploy watch openstack create log login dashboard 
