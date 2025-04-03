#!/bin/sh
# Run bootc qcow image
set -eux

MYDIR=$(dirname $0)
IMAGE=tmp/output/qcow2/disk.qcow2
PORT=2201
PRIVKEY=$MYDIR/id_test
SSH="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o CheckHostIP=no -i $PRIVKEY -p $PORT root@localhost"

chmod go-rw $PRIVKEY

qemu-system-x86_64 -enable-kvm -cpu host -smp 2 -display none -m 8192 -device virtio-rng-pci -serial stdio -drive file=$IMAGE,if=virtio -snapshot -net nic,model=virtio -net user,hostfwd=tcp::$PORT-:22 &

# wait until it responds
for retry in $(seq 10); do
    timeout 5 $SSH true && break
    sleep 5
done

# smoke test that it's running our image
PKGS=$($SSH rpm -qa '*cockpit*')
echo "$PKGS" | grep -q cockpit-system

# shut down
$SSH poweroff
wait
