#!/bin/bash

# Default values for parameters
SERVER_ONLY=true
CLIENT_ONLY=true
NUM_CLIENTS=
VPN_SERVER_IP=
VPN_SERVER_PORT=
BUCKET_NAME=

# Parse named parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --clients) NUM_CLIENTS="$2"; shift ;;
        --server_ip) VPN_SERVER_IP="$2"; shift ;;
        --server_port) VPN_SERVER_PORT="$2"; shift ;;
        --bucket_name) BUCKET_NAME="$2"; shift ;;
        --server-only) CLIENT_ONLY=false  ;;
        --client-only) SERVER_ONLY=false ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate required parameters if needed
if [[ "$CLIENT_ONLY" == true && -z "$NUM_CLIENTS" ]]; then
    echo "Error: Number of clients (--clients) must be specified when using --client-only."
    exit 1
fi

if [ -z "$NUM_CLIENTS" ] || [ -z "$VPN_SERVER_IP" ] || [ -z "$VPN_SERVER_PORT" ] || [ -z "$BUCKET_NAME" ]; then
    echo "Usage: $0 --clients <number_of_clients> --server_ip <OpenVPN_server_IP> --server_port <OpenVPN_server_port> --bucket_name <GCS_bucket_name> [--server-only | --client-only]"
    exit 1
fi

# Directory where the script and configuration files are located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install OpenVPN and Easy-RSA
install_dependencies() {
    apt-get update
    apt-get install -y openvpn easy-rsa

    if ! command -v gsutil &> /dev/null; then
        echo "gsutil not found, installing Google Cloud SDK..."
        curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
        sudo apt-get update && sudo apt-get install google-cloud-cli
    fi    

}

# Set up the Easy-RSA environment
setup_easy_rsa() {
    # setup easy-rsa staging area
    mkdir ~/openvpn-ca
    cd ~/openvpn-ca

    local easy_rsa_dir=~/openvpn-ca/easy-rsa
    # Check if easy-rsa directory exists, skip setup if it does

    if [ -d "$easy_rsa_dir" ]; then
        echo "Easy-RSA directory already exists. Skipping setup."
        return
    fi

    # create rsa dir
    make-cadir easy-rsa
    cd easy-rsa
    # init easy-rsa
    ./easyrsa init-pki
    build_ca
}

# Build the CA
build_ca() {
    # create CA and server certs using easy-rsa
    echo "open-vpn-server" | ./easyrsa build-ca nopass
}

# Generate server certificates (including server.conf)
build_server_certificates() {
    cd ~/openvpn-ca/easy-rsa
    # Read server.conf from external file
    cp "$SCRIPT_DIR/server.conf" /etc/openvpn/server/server.conf

    # create server certs using easy-rsa
    ./easyrsa build-server-full server nopass
    openvpn --genkey --secret ta.key
    ./easyrsa gen-dh

    # copy server files to OpenVPN directory
    mkdir -p /etc/openvpn/easy-rsa
    cp pki/ca.crt pki/private/server.key pki/issued/server.crt pki/dh.pem /etc/openvpn/easy-rsa/
    cp ta.key /etc/openvpn/server/
}


# Build client.conf and certificate files
build_client_certificates() {
    local clientname=$1

    cd ~/openvpn-ca/easy-rsa
    # create client files
    mkdir -p /etc/openvpn/client
    mkdir -p /etc/openvpn/client/client$clientname

    # copy client conf
    cat "$SCRIPT_DIR/client.conf" | \
        sed "s/clientname/$clientname/g" | \
        sed "s/VPNServerIp/$VPN_SERVER_IP/g" | \
        sed "s/VPNServerPort/$VPN_SERVER_PORT/g" > /etc/openvpn/client/client$clientname/client.conf
    
    # build client certs
    cd ~/openvpn-ca
    cd easy-rsa
    ./easyrsa build-client-full client$clientname nopass

    # copy client certs to the server
    cp pki/ca.crt pki/private/client$clientname.key pki/issued/client$clientname.crt ta.key /etc/openvpn/client/client$clientname/
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
    sed -n '/BEGIN CERTIFICATE/,/END CERTIFICATE/p' < /etc/openvpn/client/client$clientname/client$clientname.crt >> $clientovpnpath
    echo "</cert>" >> $clientovpnpath
    echo "<key>" >> $clientovpnpath
    sed -n '/BEGIN PRIVATE KEY/,/END PRIVATE KEY/p' < /etc/openvpn/client/client$clientname/client$clientname.key >> $clientovpnpath
    echo "</key>" >> $clientovpnpath
    echo "<tls-auth>" >> $clientovpnpath
    sed -n '/BEGIN OpenVPN Static key V1/,/END OpenVPN Static key V1/p' < /etc/openvpn/client/client$clientname/ta.key >> $clientovpnpath
    echo "</tls-auth>" >> $clientovpnpath

    # Upload the .ovpn file to the Cloud Storage bucket
    gsutil cp $clientovpnpath gs://$BUCKET_NAME/clients/client$clientname.ovpn    
}

# Main function to execute all steps
main() {

    # Validate numerical parameters
    if ! [[ "$NUM_CLIENTS" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: Number of clients must be a positive integer."
        exit 1
    fi

    if ! [[ "$VPN_SERVER_PORT" =~ ^[1-9][0-9]*$ ]]; then
        echo "Error: VPN server port must be a positive integer."
        exit 1
    fi

    install_dependencies
    setup_easy_rsa

    # Execute server setup if --server-only or no specific option is provided
    if [[ "$SERVER_ONLY" == true ]]; then
        build_server_certificates
    fi

    # Execute client setup if --client-only or no specific option is provided
    if [[ "$CLIENT_ONLY" == true ]]; then
        for i in $(seq 1 $NUM_CLIENTS); do
            # Generate a unique client identifier
            client_uuid=$(uuidgen | cut -d'-' -f1)

            build_client_certificates "-${client_uuid}"
            create_ovpn_files "-${client_uuid}"
        done
    fi    

    echo "OpenVPN server and client files have been created, server.conf and client.conf have been configured, and .ovpn files have been generated."
}

# Execute the main function
main
