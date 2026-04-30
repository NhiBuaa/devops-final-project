[k3s_master]
master ansible_host=${master_ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${ssh_key}.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'

[k3s_workers]
%{ for i, ip in worker_ips ~}
worker-${i + 1} ansible_host=${ip} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/${ssh_key}.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
%{ endfor ~}

[k3s_cluster:children]
k3s_master
k3s_workers
