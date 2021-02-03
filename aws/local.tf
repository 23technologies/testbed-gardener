#kubeconfig_ip

resource "local_file" "kubeconfig" {
    filename = ".kubeconfig"
    provisioner "local-exec" {
      command = "../tools/retry-command --wait 30 --retries 30 -- scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ${var.ssh_key} ${module.kubernetes.ssh_user}@${module.kubernetes.public_ip}:${module.kubernetes.kubeconfig_ip} kubeconfig"
    }
    depends_on = [module.kubernetes]
    
}
