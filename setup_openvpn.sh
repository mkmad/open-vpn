#!/bin/bash

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --clients) NUM_CLIENTS="$2"; shift ;;
        --server_ip) VPN_SERVER_IP="$2"; shift ;;
        --server_port) VPN_SERVER_PORT="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

if [ -z "$NUM_CLIENTS" ] || [ -z "$VPN_SERVER_IP" ] || [ -z "$VPN_SERVER_PORT" ]; then
    echo "Usage: $0 --clients <number_of_clients> --server_ip <OpenVPN_server_IP> --server_port <OpenVPN_server_port>"
    exit 1
fi

# Directory where the script and configuration files are located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install OpenVPN and Easy-RSA
install_dependencies() {
    apt-get update
    apt-get install -y openvpn easy-rsa
}

# Set up the Easy-RSA environment
setup_easy_rsa() {
    make-cadir ~/openvpn-ca
    cd ~/openvpn-ca

    # Read vars from external file
    cp "$SCRIPT_DIR/vars" ./vars
}

# Build the CA and generate server and client certificates
build_certificates() {
    source vars
    ./easyrsa init-pki
    ./easyrsa build-ca nopass
    ./easyrsa build-server-full server nopass
    openvpn --genkey --secret ta.key
    ./easyrsa gen-dh

    for i in $(seq 1 $NUM_CLIENTS); do
        ./easyrsa build-client-full client$i nopass
    done
}

# Copy files to OpenVPN directory
copy_files() {
    mkdir -p /etc/openvpn/easy-rsa
    cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem /etc/openvpn/easy-rsa/
    cp ta.key /etc/openvpn/server/
    mkdir -p /etc/openvpn/client
    for i in $(seq 1 $NUM_CLIENTS); do
        mkdir -p /etc/openvpn/client/client$i
        cp pki/ca.crt pki/private/client$i.key pki/issued/client$i.crt ta.key /etc/openvpn/client/client$i/
    done
}

# Create server.conf file
create_server_conf() {
    # Read server.conf from external file
    cp "$SCRIPT_DIR/server.conf" /etc/openvpn/server.conf
}

# Create client.conf files
create_client_conf() {
    local clientname=$1
    cat "$SCRIPT_DIR/client.conf" | sed "s/clientname/$clientname/g" | sed "s/VPNServerIp/$VPN_SERVER_IP/g" | sed "s/VPNServerPort/$VPN_SERVER_PORT/g" > /etc/openvpn/client/client$clientname/client.conf
}

# Create .ovpn files for clients
create_ovpn_files() {
    local clientname=$1
    cd /etc/openvpn
    cp /etc/openvpn/client/client$clientname/client.conf /etc/openvpn/client$clientname.ovpn
    sed -i '/ca / s/^/#/' /etc/openvpn/client$clientname.ovpn
    sed -i '/cert / s/^/#/' /etc/openvpn/client$clientname.ovpn
    sed -i '/key / s/^/#/' /etc/openvpn/client$clientname.ovpn
    echo "key-direction 1" >> /etc/openvpn/client$clientname.ovpn
    echo "<ca>" >> /etc/openvpn/client$clientname.ovpn
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' < easy-rsa/ca.crt >> /etc/openvpn/client$clientname.ovpn
    echo "</ca>" >> /etc/openvpn/client$clientname.ovpn
    echo "<cert>" >> /etc/openvpn/client$clientname.ovpn
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' < easy-rsa/issued/$clientname.crt >> /etc/openvpn/client$clientname.ovpn
    echo "</cert>" >> /etc/openvpn/client$clientname.ovpn
    echo "<key>" >> /etc/openvpn/client$clientname.ovpn
    sed -n '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/p' < easy-rsa/private/$clientname.key >> /etc/openvpn/client$clientname.ovpn
    echo "</key>" >> /etc/openvpn/client$clientname.ovpn
    echo "<tls-auth>" >> /etc/openvpn/client$clientname.ovpn
    sed -n '/BEGIN OpenVPN Static key V1/,/END OpenVPN Static key V1/p' < server/ta.key >> /etc/openvpn/client$clientname.ovpn
    echo "</tls-auth>" >> /etc/openvpn/client$clientname.ovpn
}

# Main function to execute all steps
main() {
    install_dependencies
    setup_easy_rsa
    build_certificates
    copy_files
    create_server_conf

    for i in $(seq 1 $NUM_CLIENTS); do
        create_client_conf $i
        create_ovpn_files client$i
    done

    echo "OpenVPN server and client files have been created, server.conf and client.conf have been configured, and .ovpn files have been generated."
}

# Execute the main function
main
