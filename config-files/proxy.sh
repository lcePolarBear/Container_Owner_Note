#!/usr/bin/env bash

MASTER_ADDRESS=${1:-"192.168.10.110"}
NODE_ADDRESS=${2:-"192.168.10.141"}

cat <<EOF >/opt/kubernetes/cfg/kube-proxy
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=4"
NODE_HOSTNAME="--hostname-override=${NODE_ADDRESS}"
KUBE_MASTER="--master=http://${MASTER_ADDRESS}:8080"
EOF

KUBE_PROXY_OPTS="   \${KUBE_LOGTOSTDERR} \\
                    \${KUBE_LOG_LEVEL}   \\
                    \${NODE_HOSTNAME}    \\
                    \${KUBE_MASTER}"

cat <<EOF >/usr/lib/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-proxy
ExecStart=/opt/kubernetes/bin/kube-proxy ${KUBE_PROXY_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-proxy
systemctl restart kube-proxy
