# CloudStack Multinode Private Cloud with HAProxy Backup Failover

## Computer Engineering Cloud Course Final Exam - 4/6/2026 Reference

![Apache CloudStack](https://img.shields.io/badge/Apache%20CloudStack-4.22-orange?style=for-the-badge)
![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04%20Noble-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![KVM](https://img.shields.io/badge/KVM-QEMU%20%2B%20libvirt-1f6feb?style=for-the-badge)
![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![NFS](https://img.shields.io/badge/NFS-Primary%20%2B%20Secondary-2ea44f?style=for-the-badge)
![HAProxy](https://img.shields.io/badge/HAProxy-Gateway%20%2B%20Failover-0a66c2?style=for-the-badge&logo=haproxy&logoColor=white)
![Cloudflare Tunnel](https://img.shields.io/badge/Cloudflare%20Tunnel-No%20Port%20Forwarding-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)
![React](https://img.shields.io/badge/SICS-React%20%2B%20Vite-61DAFB?style=for-the-badge&logo=react&logoColor=black)

This is the final reference guide for a multinode CloudStack private cloud project: the main host runs the Management Server and local KVM node, a remote device runs an additional KVM node, and the SICS application runs on two CloudStack VMs behind HAProxy gateway and backup failover. It covers the actual configuration, commands, final state, debugging notes, SICS Website deployment, Cloudflare Tunnel, and Wi-Fi migration procedures.

> [!IMPORTANT]
> This setup was intentionally built for a course lab with temporary constraints: the uplink still uses Wi-Fi and dummy bridges. For production deployment, use physical Ethernet NICs, proper network segmentation, strict firewalling, credential rotation, and appropriate monitoring.

> [!CAUTION]
> This document records several lab credentials so they are not forgotten. Do not commit it to a public repository before removing passwords, tokens, private key paths, and internal hostnames.

## Project Focus

The main focus of this project is to build a multinode private cloud based on Apache CloudStack and prove that an application workload can run redundantly on two different VMs:

```text
Primary backend: CloudStack VM on the remote KVM node, 172.16.20.52
Backup backend:  CloudStack VM on the local KVM node, 172.16.10.101
Gateway:         HAProxy on the main host, port 80
Public access:   Cloudflare Tunnel to HAProxy, without router port forwarding
Failover mode:   HAProxy health check, remote primary down -> local backup active
```

With this framing, the main host acts as the management node and first KVM node, not as the final architectural boundary. The main value of the setup is the combination of multinode CloudStack, dual VM workload placement, HAProxy backup failover, and Cloudflare Tunnel for public access.


---

## Table of Contents

- [CloudStack Multinode Private Cloud with HAProxy Backup Failover](#cloudstack-multinode-private-cloud-with-haproxy-backup-failover)
  - [Computer Engineering Cloud Course Final Exam - 4/6/2026 Reference](#computer-engineering-cloud-course-final-exam---462026-reference)
  - [Project Focus](#project-focus)
  - [Target State](#target-state)
  - [Screenshot Checklist](#screenshot-checklist)
  - [Quick Access](#quick-access)
  - [Credential Reference](#credential-reference)
  - [Architecture](#architecture)
  - [Host Inventory](#host-inventory)
  - [Network Inventory](#network-inventory)
  - [Service Inventory](#service-inventory)
  - [Part 1 - Local Management and KVM Node Setup](#part-1---local-management-and-kvm-node-setup)
  - [Part 2 - CloudStack Provisioning](#part-2---cloudstack-provisioning)
  - [Part 3 - Remote KVM Agent Setup](#part-3---remote-kvm-agent-setup)
  - [Part 4 - RemoteWiFiZone Final Fix](#part-4---remotewifizone-final-fix)
  - [Part 5 - SICS Website Deployment](#part-5---sics-website-deployment)
  - [Part 6 - HAProxy Gateway and Failover](#part-6---haproxy-gateway-and-failover)
  - [Part 7 - Cloudflare Tunnel](#part-7---cloudflare-tunnel)
  - [Part 8 - Moving Between Wi-Fi Networks](#part-8---moving-between-wi-fi-networks)
  - [Part 9 - Verification Playbook](#part-9---verification-playbook)
  - [Part 10 - Troubleshooting Log](#part-10---troubleshooting-log)
  - [Appendix A - Important Files](#appendix-a---important-files)
  - [Appendix B - Migration to Ethernet](#appendix-b---migration-to-ethernet)

---

## Target State

Achieved target state:

```text
CloudStack runs as a multinode private cloud.
The main host acts as the Management Server and local KVM node.
The remote device acts as an additional KVM node in RemoteWiFiZone.
SICS Website runs redundantly on two CloudStack VMs.
HAProxy on the main host acts as the gateway/load balancer with backup failover.
Cloudflare Tunnel replaces router port forwarding.
SSH to hosts and VMs is accessible through Cloudflare Tunnel.
```

Final status as of 2026-06-04:

```text
CloudStack Management: active
CloudStack local agent: active
CloudStack remote agent: active
MySQL: active
NFS: active
HAProxy: active
cloudflared: active/enabled
Public website: https://sics.daffahub.com/
Active website backend: remote-cloudstack
```

---

## Screenshots Checklist (Proof of Work)

### CloudStack Dashboard  ✅

#### 1. Cloudstack Login Screen (Accessed from Internet)

- From PC
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/9d75a875-077a-40e6-a0cb-ecbdca9cd5bd" />

- From Smartphone
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/796d0ce6-230b-443a-86cc-7e3687e45628" />

#### 2. Cloudstack Dashboard Overview
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/a7c7d516-ee31-41a2-9223-aadb0bf5301d" />

#### 3. Cloudstack Zone List
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/a301604c-81db-439a-bfc3-2451881ef415" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/cf038f68-8ddd-4e4a-b748-adc675cf54e4" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/82d7708e-710c-4fbe-9de3-8eb59358bf40" />



#### 4. Cloudstack Host List
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/6b5be31a-0a62-4832-8b95-92abcbce85b3" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/c85ba67c-f675-45c3-bb09-c656483dfe0b" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/619c0684-f26a-4f84-a266-525b471afddd" />


#### 5. Cloudstack System VM List
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/d4d6f829-266c-4bed-a11d-000cac6fa56f" />

#### 6. Cloudstack Instance List
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/3c27890a-ff04-48cf-b6c3-614b30ab9abd" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/61379393-6f08-4e1d-9e9a-c2f505c1908d" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/2554fa0d-6f00-4653-a4a7-adf68af7b1ac" />

#### 7. Cloudstack Template for Deployment List
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/7f3a247c-d4e7-4f8f-8a70-9d3c1acbcb64" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/48b5e93c-8c8b-4465-850b-67b9effdcf89" />

#### 8. Cloudstack Network List
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/f9dd24ff-86a7-46b3-9a6c-f501f95d8c8e" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/0e87cbbd-1a8e-467f-ace3-83a590dbb735" />
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/d8ba3f2a-5380-44dc-8f54-e3de429dcc54" />



### Cloudflare Dashboard  ✅

#### 1. Cloudstack Tunnel Overview
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/d5c157d3-57fa-487f-bc11-c3b70ff887d8" />

#### 2. Cloudstack Active Connector
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/b2927ed8-3868-457f-90dd-cdeed6d53f2a" />

#### 3. Cloudstack DNS Config
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/93533bb3-478c-46e8-bb34-4ec319c14d26" />




### Website and SSH Verification  ✅

#### 1. Website Accessed From Internet

- On PC
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/73d9ce34-ce79-447c-8072-7cf08ee76981" />

- On Smartphone
<img width="720" height="1600" alt="image" src="https://github.com/user-attachments/assets/989b6162-1f1a-437c-95a7-bbcf2f35b825" />

- Resource Usage Log on Cloudstack
<img width="2560" height="1600" alt="image" src="https://github.com/user-attachments/assets/60a385dc-0785-4f7a-8eeb-8f59c389ba9d" />

#### 2. SSH using public domain
<img width="2560" height="1598" alt="image" src="https://github.com/user-attachments/assets/b8ce067d-dbb2-4eb3-a948-0281a6c33f29" />
<img width="2560" height="1598" alt="image" src="https://github.com/user-attachments/assets/fa801f94-1c91-4608-b1f9-5409bc18c7ba" />




### Host Terminal Evidence  ✅

#### 1. Active Services
<img width="689" height="363" alt="image" src="https://github.com/user-attachments/assets/cb03f869-c4a7-483d-b55e-8a3f9920b8d8" />

#### 2. Remote Virsh List
<img width="1097" height="229" alt="image" src="https://github.com/user-attachments/assets/44e2eaf3-2a7c-417a-be0e-1e2f73a4287f" />

#### 3. Cloudflared Logs
<img width="2411" height="250" alt="image" src="https://github.com/user-attachments/assets/deac4677-77d7-4e92-8fad-2c7c4df318bd" />



---

## Quick Access

### CloudStack UI

```text
Local UI: http://127.0.0.1:8080/client
LAN UI:   http://192.168.1.3:8080/client
Login:    admin / password
```

> IP LAN can change when moving between Wi-Fi networks. See [Part 8 - Moving Between Wi-Fi Networks](#part-8---moving-between-wi-fi-networks).

### SICS Website

```text
Public website: https://sics.daffahub.com/
Local HAProxy:  http://127.0.0.1/
LAN HAProxy:    http://192.168.1.3/
Primary VM:     http://172.16.20.52/
Backup VM:      http://172.16.10.101/
```

Expected header when the primary backend is healthy:

```text
X-SICS-Node: remote-cloudstack
```

Expected header when the primary backend is down and HAProxy fails over:

```text
X-SICS-Node: local
```

### SSH Through Cloudflare Tunnel

Clients outside the network need `cloudflared` and the following config in `~/.ssh/config`:

```sshconfig
Host ssh-device0.daffahub.com ssh-device2.daffahub.com ssh-vm-backup.daffahub.com ssh-vm-main.daffahub.com
  ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
```

If the `cloudflared` path is different on your laptop, check it with:

```bash
command -v cloudflared
```

---

## Credential Reference

> [!WARNING]
> These are lab credentials. Do not publish them. Change the passwords if this setup is used on any network you do not fully control.

### CloudStack

```text
URL:      http://127.0.0.1:8080/client
Username: admin
Password: password
```

### Primary Host / Device0

```text
Cloudflare hostname: ssh-device0.daffahub.com
Internal target:     localhost:22
Local hostname:      cloudstack-lab.local
Username:            daffa
Password:            daffa
SSH command:         ssh daffa@ssh-device0.daffahub.com
```

### Remote Host / Device2

```text
Cloudflare hostname: ssh-device2.daffahub.com
Internal target:     192.168.1.10:22
Local hostname:      cloudstack-agent2.local
Username:            mate
Password:            dio12345
SSH command:         ssh mate@ssh-device2.daffahub.com
```

### VM Backup / Local CloudStack VM

```text
Cloudflare hostname: ssh-vm-backup.daffahub.com
Internal target:     172.16.10.101:22
VM name:             sics-web-local
Username:            ubuntu
Password:            none, SSH key only
SSH key:             /home/daffa/.ssh/sics_cloudstack_ed25519
SSH command:         ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@ssh-vm-backup.daffahub.com
```

### VM Main / Remote CloudStack VM

```text
Cloudflare hostname: ssh-vm-main.daffahub.com
Internal target:     172.16.20.52:22
VM name:             sics-web-remote-cloudstack
Username:            ubuntu
Password:            none, SSH key only
SSH key:             /home/daffa/.ssh/sics_cloudstack_ed25519
SSH command:         ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@ssh-vm-main.daffahub.com
```

### Cloudflare

```text
Tunnel ID:     1217df2a-b56d-4f30-93de-4a0a24bcda3a
Connector ID:  c634b3b8-2a81-4d65-b210-e6a327e06388
Service unit:  cloudflared.service
Token:         not documented, credential secret
```

---

## Architecture

### High-Level Topology

```text
Internet
  |
  v
Cloudflare
  |
  v
Cloudflare Tunnel
  |
  v
cloudflared on cloudstack-lab.local
  |
  +-- sics.daffahub.com          -> HAProxy localhost:80
  +-- ssh-device0.daffahub.com   -> SSH localhost:22
  +-- ssh-device2.daffahub.com   -> SSH 192.168.1.10:22
  +-- ssh-vm-backup.daffahub.com -> SSH 172.16.10.101:22
  +-- ssh-vm-main.daffahub.com   -> SSH 172.16.20.52:22
```

### Website Path

```text
https://sics.daffahub.com/
  -> Cloudflare edge
  -> cloudflared tunnel connector
  -> HAProxy on cloudstack-lab.local:80
  -> primary: 172.16.20.52:80  sics-web-remote-cloudstack
  -> backup:  172.16.10.101:80 sics-web-local
```

### CloudStack Zones

```text
CloudStack Management Server
  |
  +-- LabZone
  |     +-- Host: cloudstack-lab.local
  |     +-- Bridge: cloudbr0 172.16.10.1/24
  |     +-- VM: sics-web-local 172.16.10.101
  |
  +-- RemoteWiFiZone
        +-- Host: cloudstack-agent2.local
        +-- Bridge: cloudbr0 172.16.20.1/24
        +-- VM: sics-web-remote-cloudstack 172.16.20.52
```

### Why Wi-Fi Uses NAT and Dummy Bridge

Wi-Fi client mode generally cannot act as a normal layer-2 bridge for KVM guest traffic. The lab workaround is:

```text
Wi-Fi uplink
  -> host bridge cloudbr0 with private subnet
  -> NAT outbound traffic
  -> dummy NIC ethcs0 attached to cloudbr0 so CloudStack KVM network checks pass
```

This is acceptable for a lab demonstration, but Ethernet should replace it for serious workloads.

---

## Host Inventory

### Primary Host

```text
Hostname: cloudstack-lab.local
OS: Ubuntu 24.04.4 LTS Noble
Kernel: 6.17.0-29-generic x86_64
RAM: 31 GiB
Root disk: 491G
Wi-Fi interface: wlp128s20f3
Current Wi-Fi IP used in final setup: 192.168.1.3/24
Old Wi-Fi IP during initial setup: 192.168.1.7/24
Ethernet: enp131s0, not used yet
CloudStack Management: 4.22.0.1
CloudStack Agent/KVM: 4.22.0.1
```

### Remote Host

```text
Hostname: cloudstack-agent2.local
SSH: mate@192.168.1.10
OS: Linux Mint 21.3 Virginia, Ubuntu Jammy base
Kernel: 5.15 series
Wi-Fi interface: wlo1
Wi-Fi IP: 192.168.1.10/24
CloudStack Agent: 4.22.1.0
KVM/libvirt: installed
Bridge: cloudbr0 172.16.20.1/24
Dummy slave: ethcs0
```

### VM Inventory

```text
VM name: sics-web-local
Role: backup website backend
Zone: LabZone
Instance: i-2-4-VM
IP: 172.16.10.101
SSH user: ubuntu
Web root: /var/www/sics
Header: X-SICS-Node: local

VM name: sics-web-remote-cloudstack
Role: primary website backend
Zone: RemoteWiFiZone
Instance: i-2-10-VM
IP: 172.16.20.52
SSH user: ubuntu
Web root: /var/www/sics
Header: X-SICS-Node: remote-cloudstack
```

---

## Network Inventory

### Local Lab Network

```text
Bridge: cloudbr0
Bridge IP: 172.16.10.1/24
Dummy NIC: ethcs0
Pod/management range: 172.16.10.10 - 172.16.10.20
Guest range: 172.16.10.50 - 172.16.10.200
Gateway: 172.16.10.1
NAT uplink: wlp128s20f3
```

### Remote Lab Network

```text
Remote Wi-Fi IP: 192.168.1.10/24
Remote bridge: cloudbr0
Remote bridge IP: 172.16.20.1/24
Remote dummy NIC: ethcs0
Guest range: 172.16.20.50 - 172.16.20.100
Gateway: 172.16.20.1
NAT uplink: wlo1
Route on management host: 172.16.20.0/24 via 192.168.1.10 dev wlp128s20f3
```

### Cloudflare Public Hostnames

```text
sics.daffahub.com          -> http://localhost:80
ssh-device0.daffahub.com   -> ssh://localhost:22
ssh-device2.daffahub.com   -> ssh://192.168.1.10:22
ssh-vm-backup.daffahub.com -> ssh://172.16.10.101:22
ssh-vm-main.daffahub.com   -> ssh://172.16.20.52:22
```

---

## Service Inventory

### Local Host Services

```bash
systemctl is-active mysql
systemctl is-active cloudstack-management
systemctl is-active cloudstack-agent
systemctl is-active nfs-kernel-server
systemctl is-active haproxy
systemctl is-active cloudflared
systemctl is-active cloudstack-lab-nat.service
```

Expected:

```text
active
active
active
active
active
active
active
```

### Remote Host Services

```bash
sshpass -p dio12345 ssh -o StrictHostKeyChecking=no mate@192.168.1.10 \
  'systemctl is-active cloudstack-agent cloudstack-remote-vm-nat libvirtd ssh'
```

Expected:

```text
active
active
active
active
```

---

## Part 1 - Local Management and KVM Node Setup

### 1. Hostname

```bash
hostnamectl set-hostname cloudstack-lab.local
```

`/etc/hosts`:

```text
127.0.1.1 cloudstack-lab.local cloudstack-lab
```

### 2. Repository and Packages

CloudStack 4.22 repository for Ubuntu Noble:

```bash
echo "deb https://download.cloudstack.org/ubuntu noble 4.22" \
  > /etc/apt/sources.list.d/cloudstack.list
wget -O - https://download.cloudstack.org/release.asc \
  > /etc/apt/trusted.gpg.d/cloudstack.asc
apt update
```

Packages installed:

```bash
apt install -y \
  chrony mysql-server nfs-kernel-server \
  cloudstack-management cloudstack-agent \
  openssh-server curl bridge-utils
```

`iptables-persistent` was not used because it conflicted with `ufw`. NAT is persisted by a custom systemd service.

### 3. MySQL Configuration

`/etc/mysql/conf.d/cloudstack.cnf`:

```ini
[mysqld]
server_id=1
innodb_rollback_on_timeout=1
innodb_lock_wait_timeout=600
max_connections=350
log_bin=mysql-bin
binlog_format=ROW
```

Restart MySQL:

```bash
systemctl restart mysql
```

Deploy CloudStack database:

```bash
cloudstack-setup-databases cloud:CloudDBPass123@localhost \
  --deploy-as=root \
  -e file \
  -m MgmtKey123 \
  -k DBKey123 \
  -i 127.0.0.1
```

Setup management server:

```bash
cloudstack-setup-management
```

Initial management IP was corrected from loopback to Wi-Fi IP:

```bash
sed -i 's/^cluster.node.IP=.*/cluster.node.IP=192.168.1.7/' \
  /etc/cloudstack/management/db.properties

mysql --protocol=socket -uroot -e \
  "UPDATE cloud.mshost SET service_ip='192.168.1.7' WHERE service_ip='127.0.0.1';"

systemctl restart cloudstack-management
```

Later, after moving Wi-Fi, the final management IP became `192.168.1.3`.

### 4. NFS Primary and Secondary Storage

Create directories:

```bash
mkdir -p /export/primary /export/secondary /mnt/secondary
chown -R nobody:nogroup /export/primary /export/secondary
```

`/etc/exports`:

```text
/export/primary *(rw,async,no_root_squash,no_subtree_check)
/export/secondary *(rw,async,no_root_squash,no_subtree_check)
```

Apply and mount secondary storage:

```bash
exportfs -a
systemctl restart nfs-kernel-server
mount -t nfs 127.0.0.1:/export/secondary /mnt/secondary
```

Seed SystemVM template:

```bash
/usr/share/cloudstack-common/scripts/storage/secondary/cloud-install-sys-tmplt \
  -m /mnt/secondary \
  -u http://download.cloudstack.org/systemvm/4.22/systemvmtemplate-4.22.0-x86_64-kvm.qcow2.bz2 \
  -h kvm \
  -F
```

Template path observed:

```text
/mnt/secondary/template/tmpl/1/3/8d275f0e-ec7f-469c-a5e8-ccb7ed890434.qcow2
```

### 5. Local Bridge and NAT

Create bridge with NetworkManager:

```bash
nmcli con add type bridge ifname cloudbr0 con-name cloudbr0 \
  ipv4.method manual ipv4.addresses 172.16.10.1/24 \
  ipv6.method disabled

nmcli con mod cloudbr0 \
  bridge.stp no \
  bridge.forward-delay 0 \
  connection.autoconnect yes

nmcli con up cloudbr0
```

Enable forwarding:

```bash
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-cloudstack-lab.conf
sysctl --system
```

`/usr/local/sbin/cloudstack-lab-nat.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

UPLINK="wlp128s20f3"
BRIDGE="cloudbr0"
SUBNET="172.16.10.0/24"

iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE

iptables -C FORWARD -i "$BRIDGE" -o "$UPLINK" -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i "$BRIDGE" -o "$UPLINK" -j ACCEPT

iptables -C FORWARD -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null || \
  iptables -A FORWARD -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT
```

`cloudstack-lab-nat.service`:

```ini
[Unit]
Description=CloudStack lab NAT rules
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/cloudstack-lab-nat.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

Enable:

```bash
chmod +x /usr/local/sbin/cloudstack-lab-nat.sh
systemctl daemon-reload
systemctl enable --now cloudstack-lab-nat.service
```

### 6. Dummy NIC Workaround for Wi-Fi Bridge

CloudStack KVM checks failed when `cloudbr0` had no slave interface:

```text
Can not find network: cloudbr0
```

Workaround:

```bash
ip link add ethcs0 type dummy
ip link set ethcs0 master cloudbr0
ip link set ethcs0 up
ip link set cloudbr0 up
```

Persistent NetworkManager config:

```bash
nmcli con add type dummy ifname ethcs0 con-name cloudbr0-ethcs0 \
  ipv4.method disabled ipv6.method disabled

nmcli con mod cloudbr0-ethcs0 \
  connection.master cloudbr0 \
  connection.slave-type bridge \
  connection.autoconnect yes

nmcli con up cloudbr0-ethcs0
```

After this, restarting `cloudstack-agent` moved the host from `Alert` to `Up`.

### 7. Local Agent Configuration

`/etc/cloudstack/agent/agent.properties` initially contained:

```properties
host=192.168.1.7
private.network.device=cloudbr0
guest.network.device=cloudbr0
public.network.device=cloudbr0
network.bridge.type=native
```

After Wi-Fi migration, `host` was updated to:

```properties
host=192.168.1.3
```

### 8. Sudoers for CloudStack Add Host

CloudStack uses SSH to execute setup commands on the host. A restricted sudoers file was created:

`/etc/sudoers.d/cloudstack-dafta-lab`:

```text
daffa ALL=(root) NOPASSWD: /usr/share/cloudstack-common/scripts/util/keystore-setup, /usr/share/cloudstack-common/scripts/util/keystore-cert-import, /usr/bin/cloudstack-setup-agent, /usr/bin/systemctl restart cloudstack-agent, /usr/bin/systemctl stop cloudstack-agent, /usr/bin/systemctl start cloudstack-agent, /usr/bin/systemctl enable cloudstack-agent
```

Validate:

```bash
visudo -cf /etc/sudoers.d/cloudstack-dafta-lab
```

---

## Part 2 - CloudStack Provisioning

### API Login Pattern

```bash
COOKIE=/home/daffa/.cloudstack-cookie
SESSION=$(curl -sS -c "$COOKIE" -b "$COOKIE" -X POST \
  'http://127.0.0.1:8080/client/api' \
  --data 'command=login&username=admin&password=password&domain=/&response=json' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["loginresponse"]["sessionkey"])')
```

### Local Zone Resources

```text
Zone: LabZone
Network type: Basic
Security groups: enabled
Physical network: physnet-cloudbr0
Traffic labels: Management/Guest/Public -> cloudbr0
Pod: Pod1
Pod management range: 172.16.10.10 - 172.16.10.20
Cluster: Cluster1
Hypervisor: KVM
Cluster type: CloudManaged
Host: cloudstack-lab.local
Shared guest network: cloudbr0
Guest IP range: 172.16.10.50 - 172.16.10.200
Primary storage: nfs://172.16.10.1/export/primary
Secondary image store: nfs://172.16.10.1/export/secondary
```

### Create Primary Storage

```bash
curl -sS -b "$COOKIE" -X POST 'http://127.0.0.1:8080/client/api' \
  --data-urlencode command=createStoragePool \
  --data-urlencode response=json \
  --data-urlencode sessionkey="$SESSION" \
  --data-urlencode zoneid=d24709c1-77a5-4adf-88cf-3c9066d6f64c \
  --data-urlencode podid=7513fe9d-cac8-41c0-ba2a-45f66ced45ea \
  --data-urlencode clusterid=88a4a849-4ec2-40d0-969d-9656782f79ee \
  --data-urlencode name=primary-nfs \
  --data-urlencode provider=NetworkFilesystem \
  --data-urlencode scope=CLUSTER \
  --data-urlencode hypervisor=KVM \
  --data-urlencode url=nfs://172.16.10.1/export/primary
```

### Add Secondary Image Store

```bash
curl -sS -b "$COOKIE" -X POST 'http://127.0.0.1:8080/client/api' \
  --data-urlencode command=addImageStore \
  --data-urlencode response=json \
  --data-urlencode sessionkey="$SESSION" \
  --data-urlencode zoneid=d24709c1-77a5-4adf-88cf-3c9066d6f64c \
  --data-urlencode name=secondary-nfs \
  --data-urlencode provider=NFS \
  --data-urlencode url=nfs://172.16.10.1/export/secondary
```

### Enable Zone

```bash
curl -sS -b "$COOKIE" -X POST 'http://127.0.0.1:8080/client/api' \
  --data-urlencode command=updateZone \
  --data-urlencode response=json \
  --data-urlencode sessionkey="$SESSION" \
  --data-urlencode id=d24709c1-77a5-4adf-88cf-3c9066d6f64c \
  --data-urlencode allocationstate=Enabled
```

### Local Zone Final Evidence

```text
Zone LabZone: Enabled, Basic
Host cloudstack-lab.local: Up, KVM, 172.16.10.1
Primary storage primary-nfs: Up
Secondary image store secondary-nfs: nfs://172.16.10.1/export/secondary
SystemVM Template KVM: Download Complete, isready=true
```

---

## Part 3 - Remote KVM Agent Setup

### 1. Remote Audit

Initial audit commands:

```bash
hostname
hostname -f
lsb_release -a
uname -a
ip -br addr
ip route show default
free -h
df -h /
egrep -c '(vmx|svm)' /proc/cpuinfo
systemctl is-active NetworkManager systemd-networkd libvirtd cloudstack-agent || true
dpkg -l cloudstack-agent qemu-kvm libvirt-daemon-system bridge-utils || true
sudo -n true
```

Key findings:

```text
Linux Mint 21.3, Ubuntu Jammy base
wlo1 = 192.168.1.10/24
virtualization flags = 16
RAM = 7.4 GiB
root disk free about 40 GiB
NetworkManager active
cloudstack-agent not installed initially
sudo required interactive password
```

### 2. Hostname and Repository

```bash
hostnamectl set-hostname cloudstack-agent2.local
```

`/etc/hosts`:

```text
127.0.1.1 cloudstack-agent2.local cloudstack-agent2
```

CloudStack repository for Jammy because Linux Mint 21.3 is Jammy-based:

```bash
install -d -m 0755 /etc/apt/keyrings
wget -O /etc/apt/keyrings/cloudstack.asc https://download.cloudstack.org/release.asc
cat >/etc/apt/sources.list.d/cloudstack.list <<'EOF_REMOTE_REPO'
deb [signed-by=/etc/apt/keyrings/cloudstack.asc] https://download.cloudstack.org/ubuntu jammy 4.22
EOF_REMOTE_REPO
apt-get update
```

A Linux Mint mirror sync error appeared during `apt-get update`, but CloudStack and Ubuntu repositories were still usable.

### 3. Install KVM and CloudStack Agent

```bash
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  chrony cloudstack-agent openssh-server bridge-utils \
  qemu-kvm libvirt-daemon-system libvirt-clients nfs-common
```

### 4. Remote Bridge for Wi-Fi Lab

```bash
systemctl stop cloudstack-agent || true

nmcli con add type bridge ifname cloudbr0 con-name cloudbr0 \
  ipv4.method manual ipv4.addresses 172.16.20.1/24 \
  ipv6.method disabled

nmcli con mod cloudbr0 \
  bridge.stp no \
  bridge.forward-delay 0 \
  connection.autoconnect yes

nmcli con up cloudbr0

nmcli con add type dummy ifname ethcs0 con-name cloudbr0-ethcs0 \
  ipv4.method disabled ipv6.method disabled

nmcli con mod cloudbr0-ethcs0 \
  connection.master cloudbr0 \
  connection.slave-type bridge \
  connection.autoconnect yes

nmcli con up cloudbr0-ethcs0
ip link set cloudbr0 up
```

Expected remote network state:

```text
wlo1     UP  192.168.1.10/24
cloudbr0 UP  172.16.20.1/24
cloudbr0 bridge slave: ethcs0
```

### 5. Remote Sudoers for Add Host

`/etc/sudoers.d/cloudstack-mate-lab`:

```text
mate ALL=(root) NOPASSWD: /usr/share/cloudstack-common/scripts/util/keystore-setup, /usr/share/cloudstack-common/scripts/util/keystore-cert-import, /usr/bin/cloudstack-setup-agent, /usr/bin/systemctl restart cloudstack-agent, /usr/bin/systemctl stop cloudstack-agent, /usr/bin/systemctl start cloudstack-agent, /usr/bin/systemctl enable cloudstack-agent
```

Validate:

```bash
visudo -cf /etc/sudoers.d/cloudstack-mate-lab
```

### 6. Linux Mint Detection Patch

`cloudstack-setup-agent` failed because CloudStack did not recognize `Linuxmint`:

```text
cloudutils.utilities.UnknownSystemException: Linuxmint
```

Patched file:

```text
/usr/lib/python3/dist-packages/cloudutils/utilities.py
```

Backup:

```bash
cp /usr/lib/python3/dist-packages/cloudutils/utilities.py \
   /usr/lib/python3/dist-packages/cloudutils/utilities.py.bak-cloudstack-linuxmint
```

Patch logic:

```python
if "Debian" in distributor or "Ubuntu" in distributor or "Linuxmint" in distributor:
    self.distro = "Ubuntu"
    self.arch = bash("uname -m").getStdout()
else:
    raise UnknownSystemException(distributor)
```

Validate:

```bash
python3 -m py_compile /usr/lib/python3/dist-packages/cloudutils/utilities.py
```

### 7. Remote Agent Setup Command

After fixing management IP, `cloudstack-setup-agent` used:

```bash
cloudstack-setup-agent -a \
  -m 192.168.1.3 \
  -z 1 \
  -p 2 \
  -c 3 \
  -g 8f337c97-3339-3d70-9388-3bd28ddb6588 \
  -s \
  --pubNic=cloudbr0 \
  --prvNic=cloudbr0 \
  --guestNic=cloudbr0 \
  --hypervisor=kvm
```

This early setup was later superseded by the final `RemoteWiFiZone` design.

---

## Part 4 - RemoteWiFiZone Final Fix

### Problem

Remote host was initially attempted in the same Basic Zone as local host. That was inconsistent because:

```text
Local guest network: 172.16.10.0/24
Remote bridge network: 172.16.20.0/24
```

A temporary Pod2 attempt made remote `cloudbr0` carry two IPs:

```text
172.16.20.1/24
172.16.10.1/24
```

CloudStack also rejected a second guest network in one Basic Zone:

```text
Can't have more than one Guest network in zone with network type Basic
```

### Final Design

Remote host moved to a dedicated Basic Zone:

```text
Zone: RemoteWiFiZone
Zone ID: 915eed4f-1d40-4a51-b0f3-13b0a5acf0e2
Physical network: physnet-remote-cloudbr0
Physical network ID: 2c941bd8-953e-471c-ad2f-5f824e3b0943
Pod: RemotePod-172-16-20
Pod ID: 61d95f79-face-4263-b774-01cb7c3f0fb9
Cluster: RemoteWiFiCluster
Cluster ID: 5c1315e1-b1da-430e-b870-e5a6aa4c4e15
Guest network: cloudbr0-remote
Guest network ID: dcc959a0-57a6-4889-a03d-06ad4c931321
Guest range: 172.16.20.50 - 172.16.20.100
Gateway: 172.16.20.1
Remote host ID: 4de3b358-0606-4291-a595-90330e8e41a7
```

Final remote bridge:

```text
wlo1:     192.168.1.10/24
cloudbr0: 172.16.20.1/24
ethcs0:   dummy bridge slave for cloudbr0
```

Final remote agent properties:

```properties
host=192.168.1.3@static
zone=2
pod=3
cluster=4
guid=8f337c97-3339-3d70-9388-3bd28ddb6588
private.network.device=cloudbr0
guest.network.device=cloudbr0
public.network.device=cloudbr0
```

### Route from Management Host to Remote VM Subnet

```bash
sudo ip route replace 172.16.20.0/24 via 192.168.1.10 dev wlp128s20f3
```

Verify:

```bash
ip route get 172.16.20.52
```

Expected:

```text
172.16.20.52 via 192.168.1.10 dev wlp128s20f3 src 192.168.1.3
```

### Remote NAT Service

Remote service:

```text
Service: cloudstack-remote-vm-nat.service
Script: /usr/local/sbin/cloudstack-remote-vm-nat.sh
```

Final script:

```bash
#!/usr/bin/env bash
set -euo pipefail

UPLINK="wlo1"
BRIDGE="cloudbr0"
SUBNET="172.16.20.0/24"
GATEWAY="172.16.20.1/24"
MGMT_IP="192.168.1.3"
MGMT_TO_GUEST="192.168.1.3"

ip addr show dev "$BRIDGE" | grep -q "172.16.20.1/24" || ip addr add "$GATEWAY" dev "$BRIDGE"
sysctl -w net.ipv4.ip_forward=1 >/dev/null

iptables -t nat -C POSTROUTING -s "$SUBNET" -d "$MGMT_IP" -j RETURN 2>/dev/null || \
  iptables -t nat -I POSTROUTING 1 -s "$SUBNET" -d "$MGMT_IP" -j RETURN

iptables -t nat -C POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE 2>/dev/null || \
  iptables -t nat -A POSTROUTING -s "$SUBNET" -o "$UPLINK" -j MASQUERADE

while iptables -D FORWARD -i "$BRIDGE" -o "$UPLINK" -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i "$UPLINK" -o "$BRIDGE" -s "$MGMT_TO_GUEST" -d "$SUBNET" -j ACCEPT 2>/dev/null; do :; done
while iptables -D FORWARD -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT 2>/dev/null; do :; done

iptables -I FORWARD 1 -i "$UPLINK" -o "$BRIDGE" -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -I FORWARD 1 -i "$UPLINK" -o "$BRIDGE" -s "$MGMT_TO_GUEST" -d "$SUBNET" -j ACCEPT
iptables -I FORWARD 1 -i "$BRIDGE" -o "$UPLINK" -j ACCEPT
```

Important NAT rules:

```text
POSTROUTING -s 172.16.20.0/24 -d 192.168.1.3/32 -j RETURN
POSTROUTING -s 172.16.20.0/24 -o wlo1 -j MASQUERADE
FORWARD -i cloudbr0 -o wlo1 -j ACCEPT
FORWARD -s 192.168.1.3/32 -d 172.16.20.0/24 -i wlo1 -o cloudbr0 -j ACCEPT
FORWARD -i wlo1 -o cloudbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

The NAT exemption is required. Without it, System VM agents connected from `192.168.1.10` instead of their `172.16.20.x` addresses, causing:

```text
Certificate ownership verification failed
```

### Remote System VM Local Storage

Remote zone only had local storage, so System VM creation required:

```bash
updateConfiguration \
  name=system.vm.use.local.storage \
  value=true \
  zoneid=915eed4f-1d40-4a51-b0f3-13b0a5acf0e2
```

Final remote system VMs:

```text
v-8-VM: consoleproxy, RemoteWiFiZone, Running, agentstate Up
s-9-VM: secondarystoragevm, RemoteWiFiZone, Running, agentstate Up
r-11-VM: virtual router, RemoteWiFiZone, Running, guest IP 172.16.20.53
```

---

## Part 5 - SICS Website Deployment

### Source Repository

```text
Repo: /home/daffa/SICS-Website
App: apps/website
Stack: React + Vite static build
Build output: /home/daffa/SICS-Website/apps/website/dist
```

Build:

```bash
cd /home/daffa/SICS-Website
/usr/local/bin/pnpm install
/usr/local/bin/pnpm build:website
```

### Templates

Local template:

```text
Name: Ubuntu 22.04 cloudimg SICS v2
ID: 6d545bdd-612b-4f6c-875a-d1ad68e97be3
Zone: LabZone
Status: Download Complete
Hypervisor: KVM
SSH key enabled: true
```

Remote template:

```text
Name: Ubuntu 22.04 cloudimg SICS remote
ID: 2e22ff25-9744-4ad3-9db8-55f62b7cdce5
Zone: RemoteWiFiZone
Status: Download Complete
Hypervisor: KVM
SSH key enabled: true
```

SSH keypair:

```text
CloudStack keypair: sics-cloudstack-key
Private key: /home/daffa/.ssh/sics_cloudstack_ed25519
Default user: ubuntu
```

Service offering:

```text
Name: SICS Local 1CPU 1GB
ID: 1bbc72f5-55f5-41f2-8bd5-9928628471bf
Storage: local
CPU: 1 core
RAM: 1024 MB
```

### Local VM Backend

```text
Name/display: sics-web-local
VM ID: 502c4e95-d5a1-4d55-b685-a001942f05f4
Instance name: i-2-4-VM
State: Running
Host: cloudstack-lab.local
IP: 172.16.10.101
Role: backup backend
```

Inside VM:

```text
Nginx: active
Document root: /var/www/sics
Health check: /healthz
Header node: X-SICS-Node: local
SSH: ubuntu@172.16.10.101
```

Verify:

```bash
curl -I http://172.16.10.101/
curl -I http://172.16.10.101/healthz
ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@172.16.10.101 \
  'systemctl is-active nginx && hostname -f && ip -br addr'
```

### Remote VM Backend

```text
Name/display: sics-web-remote-cloudstack
VM ID: 95f524f0-d75d-4ab3-9f52-83d49d647b66
Instance name: i-2-10-VM
State: Running
Zone: RemoteWiFiZone
Host: cloudstack-agent2.local
IP: 172.16.20.52
Role: primary backend
```

Inside VM:

```text
Nginx: active
Document root: /var/www/sics
Health check: /healthz
Header node: X-SICS-Node: remote-cloudstack
SSH: ubuntu@172.16.20.52
```

Verify:

```bash
curl -I http://172.16.20.52/
curl -I http://172.16.20.52/healthz
ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@172.16.20.52 \
  'systemctl is-active nginx && hostname -f && ip -br addr'
```

### Temporary Backend Removed

A temporary fallback once used Nginx directly on remote host:

```text
192.168.1.10:30080
```

Final HAProxy no longer uses that host backend. It uses only CloudStack VMs.

---

## Part 6 - HAProxy Gateway and Failover

### Purpose

HAProxy on the host main machine is the website gateway. It keeps the public entrypoint stable while switching between CloudStack VM backends.

```text
Frontend: *:80
Health check: GET /healthz
Primary backend: 172.16.20.52:80
Backup backend: 172.16.10.101:80
```

### Backend Config

Core backend in `/etc/haproxy/haproxy.cfg`:

```text
backend sics_backends
    option httpchk GET /healthz
    http-check expect status 200
    default-server inter 2s fall 2 rise 1
    server sics_remote 172.16.20.52:80 check
    server sics_local 172.16.10.101:80 check backup
```

Validate and reload:

```bash
haproxy -c -f /etc/haproxy/haproxy.cfg
systemctl reload haproxy
systemctl is-active haproxy
```

### Normal Access Test

```bash
curl -I http://127.0.0.1/
curl -I http://192.168.1.3/
```

Expected when remote backend is healthy:

```text
HTTP/1.1 200 OK
X-SICS-Node: remote-cloudstack
```

### Failover Test

```bash
ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@172.16.20.52 \
  'sudo systemctl stop nginx'

sleep 5
curl -I http://127.0.0.1/

ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@172.16.20.52 \
  'sudo systemctl start nginx'

sleep 5
curl -I http://127.0.0.1/
```

Observed result:

```text
Remote stopped: X-SICS-Node: local
Remote started: X-SICS-Node: remote-cloudstack
```

> [!NOTE]
> This is automatic failover with a short health-check delay. It is not a formal production zero-downtime guarantee for every in-flight request.

---

## Part 7 - Cloudflare Tunnel

### Why Cloudflare Tunnel

Router port forwarding was not available/reliable, and public IP access timed out from the host. Cloudflare Tunnel solves this by creating an outbound connection from `cloudflared` to Cloudflare.

```text
No router port forwarding required.
Works behind CGNAT as long as outbound Internet works.
Keeps website and SSH reachable through Cloudflare hostnames.
```

### cloudflared Installation

```bash
sudo mkdir -p --mode=0755 /usr/share/keyrings
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg \
  | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null

echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared any main" \
  | sudo tee /etc/apt/sources.list.d/cloudflared.list

sudo apt-get update
sudo apt-get install -y cloudflared
cloudflared --version
```

Installed version:

```text
cloudflared version 2026.5.2
Binary used by service: /usr/bin/cloudflared
Binary in user shell: /usr/local/bin/cloudflared
```

### Dashboard-Managed Tunnel

The connector was installed with the Cloudflare Dashboard token:

```bash
sudo cloudflared service install <CLOUDFLARE_TOKEN>
sudo systemctl enable --now cloudflared
```

Token is not stored in this guide.

Service:

```text
Unit: /etc/systemd/system/cloudflared.service
ExecStart: /usr/bin/cloudflared --no-autoupdate tunnel run --token <REDACTED>
State: active
Enabled: yes
Tunnel ID: 1217df2a-b56d-4f30-93de-4a0a24bcda3a
Connector ID: c634b3b8-2a81-4d65-b210-e6a327e06388
Protocol: quic
```

Validate:

```bash
systemctl is-active cloudflared
systemctl status cloudflared --no-pager -l
journalctl -u cloudflared -n 80 --no-pager
```

Healthy log patterns:

```text
CONNECTIVITY PRE-CHECKS: PASS
Cloudflare API: PASS
Registered tunnel connection
protocol=quic
```

### Public Hostnames

Actual dashboard routes:

```text
sics.daffahub.com          -> http://localhost:80
ssh-device0.daffahub.com   -> ssh://localhost:22
ssh-device2.daffahub.com   -> ssh://192.168.1.10:22
ssh-vm-backup.daffahub.com -> ssh://172.16.10.101:22
ssh-vm-main.daffahub.com   -> ssh://172.16.20.52:22
```

### Public Website Validation

```bash
curl -sSI --max-time 15 https://sics.daffahub.com/
```

Observed:

```text
HTTP/2 200
server: cloudflare
x-sics-node: remote-cloudstack
cf-cache-status: DYNAMIC
```

### Public SSH Validation

Commands tested:

```bash
sshpass -p daffa ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/cloudflare_known_hosts \
  -o ConnectTimeout=20 \
  -o ProxyCommand='/usr/local/bin/cloudflared access ssh --hostname %h' \
  daffa@ssh-device0.daffahub.com \
  'echo ssh-device0-ok'

sshpass -p dio12345 ssh \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/cloudflare_known_hosts \
  -o ConnectTimeout=20 \
  -o ProxyCommand='/usr/local/bin/cloudflared access ssh --hostname %h' \
  mate@ssh-device2.daffahub.com \
  'echo ssh-device2-ok'

ssh \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/cloudflare_known_hosts \
  -o ConnectTimeout=20 \
  -o ProxyCommand='/usr/local/bin/cloudflared access ssh --hostname %h' \
  -i /home/daffa/.ssh/sics_cloudstack_ed25519 \
  ubuntu@ssh-vm-backup.daffahub.com \
  'echo ssh-vm-backup-ok'

ssh \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=no \
  -o UserKnownHostsFile=/tmp/cloudflare_known_hosts \
  -o ConnectTimeout=20 \
  -o ProxyCommand='/usr/local/bin/cloudflared access ssh --hostname %h' \
  -i /home/daffa/.ssh/sics_cloudstack_ed25519 \
  ubuntu@ssh-vm-main.daffahub.com \
  'echo ssh-vm-main-ok'
```

Observed:

```text
ssh-device0-ok
ssh-device2-ok
ssh-vm-backup-ok
ssh-vm-main-ok
```

> [!IMPORTANT]
> During local tests, SSH via Cloudflare did not prompt a Cloudflare Access browser login. If SSH must be private, configure Cloudflare Access Application and policy for the SSH hostnames so only approved email accounts can connect.

### Client SSH Config Template

```sshconfig
Host ssh-device0.daffahub.com ssh-device2.daffahub.com ssh-vm-backup.daffahub.com ssh-vm-main.daffahub.com
  ProxyCommand /usr/local/bin/cloudflared access ssh --hostname %h
```


### Cloudflare Browser SSH Access

Cloudflare Tunnel was also used for browser-based SSH access. This allows SSH access from any browser without installing `cloudflared` on the client device.

Browser SSH target hostnames:

```text
ssh-device0.daffahub.com   -> SSH localhost:22
ssh-device2.daffahub.com   -> SSH 192.168.1.10:22
ssh-vm-backup.daffahub.com -> SSH 172.16.10.101:22
ssh-vm-main.daffahub.com   -> SSH 172.16.20.52:22
````

Browser access URLs:

```text
https://ssh-device0.daffahub.com
https://ssh-device2.daffahub.com
https://ssh-vm-backup.daffahub.com
https://ssh-vm-main.daffahub.com
```

Cloudflare Zero Trust configuration:

```text
Zero Trust Dashboard
-> Access
-> Applications
-> Self-hosted application
-> Domain: each SSH hostname
-> Enable browser-rendered SSH
-> Add Access policy for allowed users
```

> [!IMPORTANT]
> Browser SSH is different from terminal SSH through `cloudflared access ssh`. Terminal SSH still needs the client-side `ProxyCommand`. Browser SSH only needs a web browser, but it must be enabled through Cloudflare Access Application settings.

#### Browser SSH Login Users

```text
ssh-device0.daffahub.com:
  Username: daffa
  Authentication: password

ssh-device2.daffahub.com:
  Username: mate
  Authentication: password

ssh-vm-backup.daffahub.com:
  Username: ubuntu
  Authentication: password enabled for browser SSH

ssh-vm-main.daffahub.com:
  Username: ubuntu
  Authentication: password enabled for browser SSH
```

#### VM SSH Password Login Adjustment

The CloudStack Ubuntu VMs originally used SSH key-only login:

```text
User: ubuntu
SSH key: /home/daffa/.ssh/sics_cloudstack_ed25519
```

For browser-based SSH testing, password login was enabled on both VM backends.

VM backup:

```bash
ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@172.16.10.101
```

VM main:

```bash
ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@172.16.20.52
```

Commands applied inside each VM:

```bash
sudo passwd ubuntu

sudo rm -f /etc/ssh/sshd_config.d/99-cloudflare-browser-ssh.conf

sudo tee /etc/ssh/sshd_config.d/00-cloudflare-browser-ssh.conf >/dev/null <<'EOF'
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
EOF

sudo sshd -t
sudo systemctl restart ssh
```

Validation inside each VM:

```bash
sudo sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication'
```

Expected result:

```text
pubkeyauthentication yes
passwordauthentication yes
kbdinteractiveauthentication yes
```

Reason for using `00-cloudflare-browser-ssh.conf`:

```text
Ubuntu cloud images may include /etc/ssh/sshd_config.d/60-cloudimg-settings.conf
with PasswordAuthentication no. In this lab, the effective sshd config still showed
passwordauthentication no when the override file was named 99-cloudflare-browser-ssh.conf.
Using 00-cloudflare-browser-ssh.conf made the intended setting effective.
```

Password SSH test from the main host:

```bash
ssh -o PubkeyAuthentication=no \
  -o PreferredAuthentications=password \
  ubuntu@172.16.10.101
```

```bash
ssh -o PubkeyAuthentication=no \
  -o PreferredAuthentications=password \
  ubuntu@172.16.20.52
```

Expected browser SSH result:

```text
ssh-device0.daffahub.com   -> login as daffa
ssh-device2.daffahub.com   -> login as mate
ssh-vm-backup.daffahub.com -> login as ubuntu
ssh-vm-main.daffahub.com   -> login as ubuntu
```

> [!WARNING]
> Password-based SSH was enabled only to make browser SSH practical for the lab demonstration. For a more secure setup, use Cloudflare Access policies, rotate lab passwords, restrict allowed emails, and consider Cloudflare short-lived SSH certificates instead of long-lived passwords.

````

Kalau mau insert lewat command langsung ke `README.md`, pakai ini:

```bash
python3 - <<'PY'
from pathlib import Path

p = Path("README.md")
s = p.read_text()

section = r'''
### Cloudflare Browser SSH Access

Cloudflare Tunnel was also used for browser-based SSH access. This allows SSH access from any browser without installing `cloudflared` on the client device.

Browser SSH target hostnames:

```text
ssh-device0.daffahub.com   -> SSH localhost:22
ssh-device2.daffahub.com   -> SSH 192.168.1.10:22
ssh-vm-backup.daffahub.com -> SSH 172.16.10.101:22
ssh-vm-main.daffahub.com   -> SSH 172.16.20.52:22
````

Browser access URLs:

```text
https://ssh-device0.daffahub.com
https://ssh-device2.daffahub.com
https://ssh-vm-backup.daffahub.com
https://ssh-vm-main.daffahub.com
```

Cloudflare Zero Trust configuration:

```text
Zero Trust Dashboard
-> Access
-> Applications
-> Self-hosted application
-> Domain: each SSH hostname
-> Enable browser-rendered SSH
-> Add Access policy for allowed users
```

> [!IMPORTANT]
> Browser SSH is different from terminal SSH through `cloudflared access ssh`. Terminal SSH still needs the client-side `ProxyCommand`. Browser SSH only needs a web browser, but it must be enabled through Cloudflare Access Application settings.

#### Browser SSH Login Users

```text
ssh-device0.daffahub.com:
  Username: daffa
  Authentication: password

ssh-device2.daffahub.com:
  Username: mate
  Authentication: password

ssh-vm-backup.daffahub.com:
  Username: ubuntu
  Authentication: password enabled for browser SSH

ssh-vm-main.daffahub.com:
  Username: ubuntu
  Authentication: password enabled for browser SSH
```

#### VM SSH Password Login Adjustment

The CloudStack Ubuntu VMs originally used SSH key-only login:

```text
User: ubuntu
SSH key: /home/daffa/.ssh/sics_cloudstack_ed25519
```

For browser-based SSH testing, password login was enabled on both VM backends.

Commands applied inside each VM:

```bash
sudo passwd ubuntu

sudo rm -f /etc/ssh/sshd_config.d/99-cloudflare-browser-ssh.conf

sudo tee /etc/ssh/sshd_config.d/00-cloudflare-browser-ssh.conf >/dev/null <<'EOF'
PasswordAuthentication yes
KbdInteractiveAuthentication yes
PubkeyAuthentication yes
PermitRootLogin no
EOF

sudo sshd -t
sudo systemctl restart ssh
```

Validation inside each VM:

```bash
sudo sshd -T | grep -E 'passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication'
```

Expected result:

```text
pubkeyauthentication yes
passwordauthentication yes
kbdinteractiveauthentication yes
```

> [!WARNING]
> Password-based SSH was enabled only to make browser SSH practical for the lab demonstration. For a more secure setup, use Cloudflare Access policies, rotate lab passwords, restrict allowed emails, and consider Cloudflare short-lived SSH certificates instead of long-lived passwords.
> '''



### Locally-Managed Template

A template was created for optional local YAML management:

```text
/home/daffa/cloudflared-sics-config-template.yml
```

Content:

```yaml
tunnel: <TUNNEL_UUID>
credentials-file: /home/daffa/.cloudflared/<TUNNEL_UUID>.json

ingress:
  - hostname: sics.<DOMAIN>
    service: http://localhost:80

  - hostname: ssh-lab.<DOMAIN>
    service: ssh://localhost:22

  - hostname: ssh-agent2.<DOMAIN>
    service: ssh://192.168.1.10:22

  - hostname: ssh-vm-local.<DOMAIN>
    service: ssh://172.16.10.101:22

  - hostname: ssh-vm-remote.<DOMAIN>
    service: ssh://172.16.20.52:22

  - service: http_status:404
```

---

## Part 8 - Moving Between Wi-Fi Networks

### What Usually Changes

When the host moves from home to campus or back, the Wi-Fi IP may change. This setup has two categories:

```text
Cloudflare Tunnel: usually does not need changes.
CloudStack internal management/agent routing: may need changes.
```

Cloudflare does not need public IP updates because `cloudflared` connects outbound.

### Check Current Wi-Fi State

```bash
ip -br addr
ip route get 1.1.1.1
```

Previous observed Wi-Fi IPs:

```text
Home initial: 192.168.1.7/24
Campus: 10.10.48.103/18
Home final: 192.168.1.3/24
```

### Update Local Management IP

```bash
NEWIP=<NEW_WIFI_IP>

sudo sed -i "s/^cluster.node.IP=.*/cluster.node.IP=$NEWIP/" \
  /etc/cloudstack/management/db.properties

sudo mysql --protocol=socket -uroot -e \
  "UPDATE cloud.mshost SET service_ip='$NEWIP';"

sudo mysql --protocol=socket -uroot -e \
  "UPDATE cloud.configuration SET value='$NEWIP' WHERE name='host';"

sudo sed -i "s/^host=.*/host=$NEWIP/" \
  /etc/cloudstack/agent/agent.properties

sudo systemctl restart cloudstack-management cloudstack-agent
```

### Update Remote Agent Management Target

```bash
NEWIP=<NEW_MAIN_HOST_WIFI_IP>

sshpass -p dio12345 ssh -o StrictHostKeyChecking=no \
  mate@<NEW_REMOTE_IP> \
  "echo dio12345 | sudo -S -p '' sed -i 's/^host=.*/host=$NEWIP@static/' /etc/cloudstack/agent/agent.properties && \
   echo dio12345 | sudo -S -p '' systemctl restart cloudstack-agent"
```

### Update Route to Remote VM Subnet

If remote device IP changes:

```bash
sudo ip route replace 172.16.20.0/24 via <NEW_REMOTE_IP> dev <MAIN_HOST_WIFI_INTERFACE>
```

Current home setup:

```bash
sudo ip route replace 172.16.20.0/24 via 192.168.1.10 dev wlp128s20f3
```

### Update Remote NAT Management Exemption

```bash
NEWIP=<NEW_MAIN_HOST_WIFI_IP>

sshpass -p dio12345 ssh -o StrictHostKeyChecking=no \
  mate@<NEW_REMOTE_IP> \
  "echo dio12345 | sudo -S -p '' sed -i \"s/^MGMT_IP=.*/MGMT_IP=\\\"$NEWIP\\\"/\" /usr/local/sbin/cloudstack-remote-vm-nat.sh && \
   echo dio12345 | sudo -S -p '' sed -i \"s/^MGMT_TO_GUEST=.*/MGMT_TO_GUEST=\\\"$NEWIP\\\"/\" /usr/local/sbin/cloudstack-remote-vm-nat.sh && \
   echo dio12345 | sudo -S -p '' systemctl restart cloudstack-remote-vm-nat.service"
```

### If SSL Certificate Fails After Moving Wi-Fi

Symptoms:

```text
cloudstack-lab.local Disconnected
SSL Handshake failed
certificate_unknown
Certificate ownership verification failed
Alternative Names: old IP
```

Logs:

```bash
tail -n 80 /var/log/cloudstack/agent/agent.log | \
  grep -E "Connecting to host|Connected to|SSL|Handshake|certificate_unknown|Startup Response|Ready|ERROR|WARN"

tail -n 100 /var/log/cloudstack/management/management-server.log | \
  grep -E "SSL|Certificate|AgentConnected|AgentDisconnected|Certificate ownership|Alternative Names"
```

Regenerate agent certificate:

```bash
PROPS=/etc/cloudstack/agent/agent.properties
KS=/etc/cloudstack/agent/cloud.jks
PASS=$(grep '^keystore.passphrase=' "$PROPS" | cut -d= -f2-)
CSR=/etc/cloudstack/agent/cloud.csr
CERT=/etc/cloudstack/agent/cloud.crt
CACERT=/etc/cloudstack/agent/cloud.ca.crt
KEY=/etc/cloudstack/agent/cloud.key

/usr/share/cloudstack-common/scripts/util/keystore-setup \
  "$PROPS" "$KS" "$PASS" 365 "$CSR" \
  >/tmp/cloudstack-new-csr.out
```

Issue certificate via CloudStack API:

```bash
COOKIE=/tmp/cloudstack-cert-cookie
SESSION=$(curl -sS -c "$COOKIE" -b "$COOKIE" -X POST \
  'http://127.0.0.1:8080/client/api' \
  --data 'command=login&username=admin&password=password&domain=/&response=json' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["loginresponse"]["sessionkey"])')

RESP=$(curl -sS -b "$COOKIE" -X POST 'http://127.0.0.1:8080/client/api' \
  --data-urlencode command=issueCertificate \
  --data-urlencode response=json \
  --data-urlencode sessionkey="$SESSION" \
  --data-urlencode csr@"$CSR")
```

Then import the returned certificate using CloudStack keystore import utility and restart the agent.

### What Does Not Change When Moving Wi-Fi

```text
Local bridge cloudbr0 remains 172.16.10.1/24.
Local VM sics-web-local remains 172.16.10.101 unless rebuilt.
Remote bridge cloudbr0 remains 172.16.20.1/24.
Remote VM sics-web-remote-cloudstack remains 172.16.20.52 unless rebuilt.
HAProxy backend remains unchanged if VM IPs remain unchanged.
Cloudflare public hostnames remain unchanged.
Cloudflare DNS remains unchanged.
Router port forwarding is not needed.
```

---

## Part 9 - Verification Playbook

### Local Services

```bash
systemctl is-active \
  cloudstack-management \
  cloudstack-agent \
  mysql \
  haproxy \
  nfs-kernel-server \
  cloudflared
```

### CloudStack API Audit

```bash
COOKIE=$(mktemp)
SESSION=$(curl -sS -c "$COOKIE" -b "$COOKIE" -X POST \
  'http://127.0.0.1:8080/client/api' \
  --data 'command=login&username=admin&password=password&domain=/&response=json' \
  | python3 -c 'import sys,json; print(json.load(sys.stdin)["loginresponse"]["sessionkey"])')

for cmd in listZones listPods listClusters listHosts listStoragePools listNetworks listVirtualMachines listSystemVms; do
  echo "== $cmd"
  curl -sS -b "$COOKIE" -X POST 'http://127.0.0.1:8080/client/api' \
    --data-urlencode command="$cmd" \
    --data-urlencode listall=true \
    --data-urlencode response=json \
    --data-urlencode sessionkey="$SESSION" \
    | python3 -m json.tool
done
```

### Remote Host Audit

```bash
sshpass -p dio12345 ssh -o StrictHostKeyChecking=no mate@192.168.1.10 '
  hostname -f
  ip -br addr
  ip route
  brctl show
  systemctl is-active cloudstack-agent cloudstack-remote-vm-nat
  echo dio12345 | sudo -S -p "" virsh list --all
  echo dio12345 | sudo -S -p "" iptables -S FORWARD
  echo dio12345 | sudo -S -p "" iptables -t nat -S POSTROUTING
'
```

Expected remote `virsh list --all`:

```text
s-9-VM      running
v-8-VM      running
r-11-VM     running
i-2-10-VM   running
```

### Website and HAProxy

```bash
curl -sSI --max-time 5 http://127.0.0.1/
curl -sSI --max-time 5 http://172.16.20.52/
curl -sSI --max-time 5 http://172.16.10.101/
curl -sSI --max-time 15 https://sics.daffahub.com/
```

Expected public result:

```text
HTTP/2 200
server: cloudflare
x-sics-node: remote-cloudstack
```

### SSH Public Hostnames

```bash
ssh daffa@ssh-device0.daffahub.com
ssh mate@ssh-device2.daffahub.com
ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@ssh-vm-backup.daffahub.com
ssh -i /home/daffa/.ssh/sics_cloudstack_ed25519 ubuntu@ssh-vm-main.daffahub.com
```

### Cloudflare Tunnel

```bash
systemctl is-active cloudflared
systemctl status cloudflared --no-pager -l
journalctl -u cloudflared -n 80 --no-pager
```

---

## Part 10 - Troubleshooting Log

### Package Conflict: iptables-persistent vs ufw

Error:

```text
iptables-persistent : Depends: netfilter-persistent (= 1.0.20) but it is not installable
ufw : Breaks: iptables-persistent but 1.0.20 is to be installed
```

Resolution:

```text
Do not use iptables-persistent.
Use idempotent NAT scripts and systemd oneshot services.
```

### MySQL server_id Must Be Integer

Bad config:

```ini
server_id=source-01
```

Fixed config:

```ini
server_id=1
```

Verify:

```sql
SHOW VARIABLES LIKE 'server_id';
```

### Management IP Was Loopback or Old Wi-Fi IP

Affected places:

```text
/etc/cloudstack/management/db.properties -> cluster.node.IP
cloud.mshost.service_ip
cloud.configuration where name='host'
/etc/cloudstack/agent/agent.properties -> host=
```

Fix:

```bash
NEWIP=192.168.1.3
sed -i "s/^cluster.node.IP=.*/cluster.node.IP=$NEWIP/" /etc/cloudstack/management/db.properties
mysql --protocol=socket -uroot -e "UPDATE cloud.mshost SET service_ip='$NEWIP';"
mysql --protocol=socket -uroot -e "UPDATE cloud.configuration SET value='$NEWIP' WHERE name='host';"
sed -i "s/^host=.*/host=$NEWIP/" /etc/cloudstack/agent/agent.properties
systemctl restart cloudstack-management cloudstack-agent
```

### Host Alert: Can Not Find Network cloudbr0

Symptoms:

```text
Incorrect Network setup on agent
Can not find network: cloudbr0
CheckNetworkAnswer result=false
```

Investigated with:

```bash
tail -n 300 /var/log/cloudstack/management/management-server.log
tail -n 300 /var/log/cloudstack/agent/agent.log
brctl show
ip -br addr show cloudbr0
virsh net-list --all
```

Root cause:

```text
cloudbr0 existed, but did not have a bridge slave interface that CloudStack's KVM network checker accepted.
```

Resolution:

```bash
ip link add ethcs0 type dummy
ip link set ethcs0 master cloudbr0
ip link set ethcs0 up
systemctl restart cloudstack-agent
```

Additional debug used Java bytecode inspection:

```bash
apt install -y openjdk-17-jdk-headless
javap -classpath ... com.cloud.hypervisor.kvm.resource.wrapper.LibvirtCheckNetworkCommandWrapper
javap -classpath ... com.cloud.hypervisor.kvm.resource.LibvirtComputingResource
```

Finding:

```text
CloudStack checks bridge interfaces through matchPifFileInDirectory and interface name patterns.
A dummy name like ethcs0 passes better than cloudbr0-dummy.
```

### Add Host Failed Because sudo Prompt Was Interactive

Resolution:

```text
Create restricted NOPASSWD sudoers entries for only the CloudStack setup commands needed by addHost.
```

Local sudoers:

```text
/etc/sudoers.d/cloudstack-dafta-lab
```

Remote sudoers:

```text
/etc/sudoers.d/cloudstack-mate-lab
```

### createStoragePool Failed When Host Was Alert

Error:

```text
No host up to associate a storage pool with in cluster 1
```

Resolution:

```text
Fix bridge/network check first.
Wait until routing host state becomes Up.
Run createStoragePool again.
```

### Linux Mint UnknownSystemException

Error:

```text
cloudutils.utilities.UnknownSystemException: Linuxmint
```

Resolution:

```text
Patch CloudStack cloudutils utilities.py so Linuxmint is treated as Ubuntu.
```

### Remote System VM Certificate Ownership Failed

Error:

```text
Certificate ownership verification failed
```

Root cause:

```text
Remote VM subnet traffic to management was MASQUERADE'd to 192.168.1.10.
CloudStack expected System VM source identity from 172.16.20.x.
```

Resolution:

```text
Add NAT RETURN before MASQUERADE for destination 192.168.1.3.
```

Rule:

```bash
iptables -t nat -I POSTROUTING 1 -s 172.16.20.0/24 -d 192.168.1.3 -j RETURN
```

### Internet Access by Public IP Timed Out

Observed:

```text
curl http://180.247.57.185/
Connection timed out
```

Likely causes:

```text
No router port forwarding.
No NAT hairpin.
ISP CGNAT.
Router firewall.
```

Resolution used:

```text
Cloudflare Tunnel to HAProxy localhost:80.
```

---

## Appendix A - Important Files

### Local Host

```text
/etc/cloudstack/management/db.properties
/etc/cloudstack/agent/agent.properties
/etc/mysql/conf.d/cloudstack.cnf
/etc/exports
/etc/haproxy/haproxy.cfg
/etc/systemd/system/cloudstack-lab-nat.service
/usr/local/sbin/cloudstack-lab-nat.sh
/etc/systemd/system/cloudflared.service
/home/daffa/cloudflared-sics-config-template.yml
/home/daffa/.ssh/sics_cloudstack_ed25519
/home/daffa/SICS-Website
/home/daffa/cloudstack-setup-run.log
/home/daffa/cloudstack_api_provision.py
```

### Remote Host

```text
/etc/cloudstack/agent/agent.properties
/etc/sudoers.d/cloudstack-mate-lab
/usr/local/sbin/cloudstack-remote-vm-nat.sh
/etc/systemd/system/cloudstack-remote-vm-nat.service
/usr/lib/python3/dist-packages/cloudutils/utilities.py
/usr/lib/python3/dist-packages/cloudutils/utilities.py.bak-cloudstack-linuxmint
/var/log/cloudstack/agent/agent.log
```

### VM Backends

```text
/var/www/sics
/etc/nginx/sites-available/default
/etc/nginx/sites-enabled/default
```

---

## Appendix B - Migration to Ethernet

When `enp131s0` is ready:

1. Decide whether Ethernet will carry CloudStack guest, management, public, or all traffic.
2. Create a real bridge using Ethernet as slave, or move `cloudbr0` to Ethernet.
3. Remove dummy `ethcs0` if the bridge has a real NIC slave.
4. Update CloudStack traffic labels if bridge names change.
5. Remove Wi-Fi NAT if VM networks should be directly reachable on physical LAN.
6. Re-check CloudStack host state and System VM connectivity.
7. Re-test SICS HAProxy and Cloudflare Tunnel.

Suggested validation after migration:

```bash
brctl show
ip -br addr
systemctl restart cloudstack-agent
systemctl is-active cloudstack-agent
curl -I http://127.0.0.1/
curl -I https://sics.daffahub.com/
```

---

## Final State Summary

```text
CloudStack multinode private cloud is operational with local and remote KVM nodes.
Remote KVM host is operational in RemoteWiFiZone.
SICS Website runs on two CloudStack VMs.
HAProxy routes primary traffic to remote VM and fails over to local VM.
Cloudflare Tunnel exposes website and SSH without port forwarding.
Documentation includes commands, configuration, debug notes, credentials, and screenshot placeholders.
```
