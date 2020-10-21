# Makefile

CONSOLE = seed
ENVIRONMENT = gx-scs
OPENSTACK = openstack
USERNAME = ubuntu

RESOURCE = openstack_networking_floatingip_v2.primary_floating_ip
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
	@rm -f .deploy.$(ENVIRONMENT) .SEED_ADDRESS.$(ENVIRONMENT)
	@rm -f .id_rsa.$(ENVIRONMENT)
	@terraform workspace select default
	@terraform workspace delete $(ENVIRONMENT)

list: init
	@terraform state list

ssh: .SEED_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.SEED_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$SEED_ADDRESS

deploy: .SEED_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.SEED_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$SEED_ADDRESS "bash deploy.sh"

sshuttle: .SEED_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.SEED_ADDRESS.$(ENVIRONMENT); \
	sshuttle --ssh-cmd "ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) " -r $(USERNAME)@$$SEED_ADDRESS 10.43.0.0/16

console: .deploy.$(ENVIRONMENT)
	@$(OPENSTACK) console log show gardener-$(CONSOLE)

.deploy.$(ENVIRONMENT): init
	@STAT=$$(terraform state list); \
	if test -n "$$STAT"; then touch .deploy.$(ENVIRONMENT); else echo "use make deploy"; exit 1; fi

.SEED_ADDRESS.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@SEED_ADDRESS=$$(terraform output seed_address); \
	echo "SEED_ADDRESS=$$SEED_ADDRESS" > $@;

.id_rsa.$(ENVIRONMENT): .deploy.$(ENVIRONMENT)
	@PRIVATE_KEY=$$(terraform output private_key); \
	echo "$$PRIVATE_KEY" > $@; \
        chmod 0600 $@

watch: .id_rsa.$(ENVIRONMENT) .SEED_ADDRESS.$(ENVIRONMENT)
	@source ./.SEED_ADDRESS.$(ENVIRONMENT); \
	DISP=0; \
	if test "$$COLORTERM" = "1"; then \
	  GREEN=$$(echo -e "\e[0;32m"); GREENBOLD=$$(echo -e "\e[1;32m"); BOLD=$$(echo -e "\e[0;1m"); RED=$$(echo -e "\e[0;31m"); YELLOW=$$(echo -e "\e[0;33m"); NORM=$$(echo -e "\e[0;0m"); \
	fi; \
	while true; do \
		LEN=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) ubuntu@$$SEED_ADDRESS sudo wc -l /var/log/cloud-init-output.log 2>/dev/null); \
		LEN=$${LEN%% *}; \
		if test -n "$$LEN" -a "$$LEN" != "$$DISP"; then \
		  OUT=$$(ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) ubuntu@$$SEED_ADDRESS sudo tail -n $$((LEN-DISP)) /var/log/cloud-init-output.log 2>/dev/null); \
		  echo -e "$$OUT" | sed -e "s/^\(TASK.*\)$$/$$BOLD\1$$NORM/" -e "s/^\(PLAY.*\)$$/$$GREEN\1$$NORM/" -e "s/^\(The system is finally up.*\)$$/$$GREENBOLD\1$$NORM/" -e "s/\(FAILED\)/$$RED\1$$NORM/g" -e "s/\(failed=[1-9][0-9]*\|unreachable=[1-9][0-9]*\)/$$RED\1$$NORM/g" -e "s/\(warn\|WARN\|RETRYING\)/$$YELLOW\1$$NORM/" -e "s/\(ok:\|ok=[0-9]*\)/$$GREEN\1$$NORM/"; \
		  if echo "$$OUT" | grep '^The system is finally up' >/dev/null 2>&1; then break; fi; \
		  DISP=$$LEN; \
		  sleep 5; \
		fi; \
	done;
	#@$(OPENSTACK) server list

openstack: init
	@$(OPENSTACK)

dashboard: .SEED_ADDRESS.$(ENVIRONMENT) .id_rsa.$(ENVIRONMENT)
	@source ./.SEED_ADDRESS.$(ENVIRONMENT); \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$SEED_ADDRESS "pkill -f 'kubectl proxy'"; \
	ssh -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$SEED_ADDRESS "kubectl -n kubernetes-dashboard describe secret"; \
	echo http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy; \
	ssh -L 8001:localhost:8001 -o StrictHostKeyChecking=no -i .id_rsa.$(ENVIRONMENT) $(USERNAME)@$$SEED_ADDRESS "kubectl proxy"

login: ssh
log: console
tunnel: sshuttle

PHONY: clean console attach detach sshuttle ssh dry-run list deploy watch openstack create log login dashboard