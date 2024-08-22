# OpenVPN Setup

This repository contains a bash script to set up an OpenVPN server and generate client configuration files. The script accepts parameters for the number of clients, the OpenVPN server IP, and the OpenVPN server port.

Additionally, the repository includes Terraform configurations to automate the setup of the required GCP resources including a VM instance, a service account, firewall rules, and a Cloud Storage bucket (to store the client configuration files).

## Files Included

- `setup_openvpn.sh`: The main bash script to set up the OpenVPN server and generate client configurations.
- `server.conf`: Configuration file for the OpenVPN server.
- `client.conf`: Template configuration file for OpenVPN clients.
- `terraform/`: Directory containing Terraform configurations to automate GCP resource setup.

## Description

- `setup_openvpn.sh`: Installs OpenVPN and Easy-RSA, sets up the Easy-RSA environment, builds the CA, server, and client certificates, copies the necessary files to the OpenVPN directory, and creates configuration files.
- `server.conf`: Contains the server configuration for OpenVPN.
- `client.conf`: Template client configuration, updated with the server IP and port during script execution.

## Terraform Setup

The Terraform configuration in this repository automates the setup of the required GCP resources including a VM instance, a service account, firewall rules, and a Cloud Storage bucket.

### Terraform Files

- `main.tf`: Main Terraform configuration file that integrates all modules.
- `variables.tf`: Variables file for Terraform configuration.
- `network/`: Directory containing the network configuration.
  - `network.tf`: VPC network and static IP address setup.
- `firewall/`: Directory containing the firewall configuration.
  - `firewall.tf`: Firewall rule allowing UDP traffic on port 1194.
- `instances/`: Directory containing the VM instance configuration.
  - `instance.tf`: VM instance setup with startup script.
- `service_account/`: Directory containing the service account configuration.
  - `service_account.tf`: Service account setup.
- `storage/`: Directory containing the Cloud Storage bucket configuration.
  - `storage.tf`: Cloud Storage bucket setup with IAM roles.

### Terraform Deployment (Deploy OpenVPN Server)

1. Navigate to the `terraform` directory:

    ```sh
    cd terraform
    ```

2. Initialize Terraform:

    ```sh
    terraform init
    ```

3. Apply the Terraform configuration:

    ```sh
    terraform apply
    ```

4. Follow the prompts to confirm the deployment.

**Note:** Terraform will install all the necessary binaries, create config files and the startup script will also push all the client files to the storage bucket for easy maintainence.

## OpenVPN Setup (Manually)

All the OpenVPN setup steps are taken care by the VM's **startup script** during Terraform instance creation.

Run the following script with the required parameters if you need to `recreate` the OpenVPN server or Client configuration files:

**NOTE:** If you created the OpenVPN server using the `Terraform` module in this repo, then the `setup_openvpn.sh` file will be locacated in this path `/home/root/open-vpn`, use `sudo su` to switch to `root` user before executing the following script.

```sh
./setup_openvpn.sh \
    --clients <number_of_clients> \
    --server_ip <OpenVPN_server_IP> \
    --server_port <OpenVPN_server_port> \
    --bucket_name <GCS_bucket_name> \
    [--server-only | --client-only]
```

**NOTE:** Use `--server-only` to execute server setup only & `--client-only` to execute client setup only, OR omit both the flags to execute both setups sequentially.

### Example (Create both server and client config files)

```sh
./setup_openvpn.sh --clients 3 --server_ip <SERVER_IP> --server_port 1194 --bucket_name open-vpn-storage
```

**NOTE:** `SERVER_IP` is the reserved static IP thats assigned to the VM instance in the terraform step.

**Also Note:** Terraform will install all the necessary binaries, create config files and the startup script will also push all the client files to the storage bucket for easy maintainence.

#### MAX Concurrent Connections

Modify the `max-clients` parameter in the `server.conf` file to limit the maximum number of conncurrent connections to the VPN server.

E.g.
```
max-clients 100 # Limit server to a maximum of n concurrent clients.
```

## OpenVPN service (Ubuntu)

Stoping and Starting OpenVPN server can be handled by `systemctl`.
Note: `server.conf` is already moved to `/etc/openvpn/server/server.conf`. This is the OpenVPN server config used by `systemctl`
```sh
sudo systemctl stop openvpn-server@server.service
sudo systemctl start openvpn-server@server.service 
```

After the server is running, use the ovpn files for any of the clients to connect and establish a VPN tunnel with the server.

## Start OpenVPN Server manually for testing

First stop the openVPN server using the `systemctl` from above, modify the `server.conf` based on your needs and run the following command.

```sh
openvpn --config <path to server.conf>
```

## Check which clients are currently connected to the OpenVPN server

OpenVPN server maintains a connection log file, this file maintains all connection records. The current path is set to `/var/log/openvpn/openvpn-status.log`

For ex, If you connected to the OpenVPN server (with IP `74.15.247.199`), the connection appear in the log file like this:

```
CLIENT_LIST,client-2967ee4e,74.15.247.199:51980,10.9.8.3,,49222,3926,Wed Aug 21 18:12:22 2024,1724263942,UNDEF,0,0
```

## Check OpenVPN Server logs

OpenVPN server logs can be obtained using the following command

```
sudo journalctl -u openvpn-server@server.service -f
```

## Connect to OpenVPN server using the ovpn file from command line

To connect to an OpenVPN server using a .ovpn file on an Ubuntu machine, you will need to have the OpenVPN client installed and then use the .ovpn configuration file to establish the connection. Here’s a step-by-step guide:

**Step 1: Install OpenVPN**

Open your terminal and install the OpenVPN client by running:

```
sudo apt update 
sudo apt install openvpn
```

**Step 2: Locate Your .ovpn File**

Make sure you know where your `.ovpn` file is located on your machine. You might have received this file from your network administrator or downloaded it from a secure location.

**Step 3: Start the OpenVPN Connection**

To start the VPN connection, use the following command in the terminal. You need to replace `/path/to/your/file.ovpn` with the actual path to your `.ovpn` file:

```
sudo openvpn --config /path/to/your/file.ovpn
```
