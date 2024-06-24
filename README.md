# OpenVPN Setup

This repository contains a bash script to set up an OpenVPN server and generate client configuration files. The script accepts parameters for the number of clients, the OpenVPN server IP, and the OpenVPN server port.

Additionally, the repository includes Terraform configurations to automate the setup of the required GCP resources including a VM instance, a service account, firewall rules, and a Cloud Storage bucket.


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

## OpenVPN Setup

All the OpenVPN setup steps are taken care of by the VM script during Terraform instance creation.

Run the following script with the required parameters if you need to `recreate` the OpenVPN server or Client configuration files:

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

NOTE: `SERVER_IP` is the reserved static IP thats assigned to the VM instance in the terraform step.

## Start OpenVPN Server manually for testing

```sh
openvpn --config server.conf
```

After the server is running, use the ovpn files for any of the clients to connect and establish a VPN tunnel with the server.

#### MAX Concurrent Connections

Modify the `max-clients` parameter in the `server.conf` file to limit the maximum number of conncurrent connections to the VPN server.

E.g.
```
max-clients 100 # Limit server to a maximum of n concurrent clients.
```

### Notes
Ensure that all configuration files are in the same directory as `setup_openvpn.sh` before running the script.
