# OpenVPN Setup Script

This repository contains a bash script to set up an OpenVPN server and generate client configuration files. The script accepts parameters for the number of clients, the OpenVPN server IP, and the OpenVPN server port.

## Files Included

- `setup_openvpn.sh`: The main bash script to set up the OpenVPN server and generate client configurations.
- `server.conf`: Configuration file for the OpenVPN server.
- `client.conf`: Template configuration file for OpenVPN clients.

## Description
- setup_openvpn.sh: Installs OpenVPN and Easy-RSA, sets up the Easy-RSA environment, builds the CA, server, and client certificates, copies the necessary files to the OpenVPN directory, and creates configuration files.
- server.conf: Contains the server configuration for OpenVPN.
- client.conf: Template client configuration, updated with the server IP and port during script execution.

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
./setup_openvpn.sh --clients 3 --server_ip 34.46.173.170 --server_port 1194
```

## Start OpenVPN Server

```
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
