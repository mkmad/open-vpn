# OpenVPN Setup Script

This repository contains a bash script to set up an OpenVPN server and generate client configuration files. The script accepts parameters for the number of clients, the OpenVPN server IP, and the OpenVPN server port.

## Files Included

- `setup_openvpn.sh`: The main bash script to set up the OpenVPN server and generate client configurations.
- `server.conf`: Configuration file for the OpenVPN server.
- `client.conf`: Template configuration file for OpenVPN clients.
- `vars`: Easy-RSA configuration file.

## Usage

1. Clone the repository:

    ```sh
    git clone https://github.com/yourusername/openvpn-setup.git
    cd openvpn-setup
    ```

2. Ensure the necessary permissions for the script:

    ```sh
    chmod +x setup_openvpn.sh
    ```

3. Run the script with the required parameters:

    ```sh
    ./setup_openvpn.sh --clients <number_of_clients> --server_ip <OpenVPN_server_IP> --server_port <OpenVPN_server_port>
    ```

## Example

```sh
./setup_openvpn.sh --clients 3 --server_ip 192.168.1.1 --server_port 1194
```

## Description
- setup_openvpn.sh: Installs OpenVPN and Easy-RSA, sets up the Easy-RSA environment, builds the CA, server, and client certificates, copies the necessary files to the OpenVPN directory, and creates configuration files.
- server.conf: Contains the server configuration for OpenVPN.
- client.conf: Template client configuration, updated with the server IP and port during script execution.
- vars: Contains Easy-RSA configuration options.

### Notes
Ensure that all configuration files are in the same directory as `setup_openvpn.sh` before running the script.
