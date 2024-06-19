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
    mkdir ~/openvpn-ca
    cd ~/openvpn-ca
}

# Build the CA and generate server and client certificates
build_certificates() {
    make-cadir easy-rsa
    cd easy-rsa
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
    local clientovpnpath="/etc/openvpn/client/client$clientname/client$clientname.ovpn"
    cd /etc/openvpn
    cp /etc/openvpn/client/client$clientname/client.conf $clientovpnpath
    sed -i '/ca / s/^/#/' $clientovpnpath
    sed -i '/cert / s/^/#/' $clientovpnpath
    sed -i '/key / s/^/#/' $clientovpnpath
    echo "key-direction 1" >> $clientovpnpath
    echo "<ca>" >> $clientovpnpath
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' < easy-rsa/ca.crt >> $clientovpnpath
    echo "</ca>" >> $clientovpnpath
    echo "<cert>" >> $clientovpnpath
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' < /etc/openvpn/client//client$clientname/client$clientname.crt >> $clientovpnpath
    echo "</cert>" >> $clientovpnpath
    echo "<key>" >> $clientovpnpath
    sed -n '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/p' < /etc/openvpn/client//client$clientname/client$clientname.key >> $clientovpnpath
    echo "</key>" >> $clientovpnpath
    echo "<tls-auth>" >> $clientovpnpath
    sed -n '/BEGIN OpenVPN Static key V1/,/END OpenVPN Static key V1/p' < /etc/openvpn/client/client$clientname/ta.key >> $clientovpnpath
    echo "</tls-auth>" >> $clientovpnpath
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
        create_ovpn_files $i
    done

    echo "OpenVPN server and client files have been created, server.conf and client.conf have been configured, and .ovpn files have been generated."
}

# Execute the main function
main
