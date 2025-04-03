#!/bin/sh
# Create bootc derivative container image, and build a qcow2 out of it
set -eux

MYDIR=$(dirname $0)
PRIVKEY=$MYDIR/id_test
PUBKEY=${PRIVKEY}.pub
OCI_TAG=localhost/bootc:latest

podman build -f - -t $OCI_TAG <<EOF
FROM quay.io/centos-bootc/centos-bootc:stream9

RUN dnf install -y cockpit && dnf clean all
EOF

rm -rf tmp
mkdir -p tmp/output

cat <<EOF > tmp/bib.config.json
{
    "blueprint": {
        "customizations": {
            "user": [
                {"name": "root", "password": "foobar", "key": "$(cat $PUBKEY)"},
                {"name": "admin", "password": "foobar", "key": "$(cat $PUBKEY)", "groups": ["wheel"]}
            ]
        }
    }
}
EOF

podman run --rm -i --privileged --security-opt=label=type:unconfined_t \
    --volume=/var/lib/containers/storage:/var/lib/containers/storage \
    --volume=./tmp/bib.config.json:/config.json \
    --volume=./tmp/output:/output \
    quay.io/centos-bootc/bootc-image-builder:latest \
    --type=qcow2 --config=/config.json \
    $OCI_TAG

# clean up the now obsolete podman images
# sudo podman rmi --all

# we want more space
qemu-img resize -f qcow2 tmp/output/qcow2/disk.qcow2 +20G
