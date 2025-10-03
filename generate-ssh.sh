#!/bin/bash

# Check if ~/.ssh directory exists, create if not
if [ ! -d ~/.ssh ]; then
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh
fi

# Check for existing SSH public keys (id_rsa.pub or *.pub)
pub_keys=$(ls ~/.ssh/*.pub 2>/dev/null)

if [ -n "$pub_keys" ]; then
    echo "Existing SSH public key(s) found:"
    for key in $pub_keys; do
        echo "Content of $key:"
        cat "$key"
        echo ""
    done
else
    echo "No SSH key found, generating new key..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -q
    echo "New SSH public key generated:"
    cat ~/.ssh/id_rsa.pub
fi