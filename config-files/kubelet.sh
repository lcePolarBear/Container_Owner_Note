#!/usr/bin/env bash

MASTER_ADDRESS=${1:-"192.168.10.110"}
NODE_ADDRESS=${2:-"192.168.10.141"}
DNS_SERVER_IP=${3:-"10.10.10.2"}
DNS_DOMAIN=${4:-"cluster.local"}
KUBECONFIG_DIR=${KUBECONFIG_DIR:-/opt/kubernetes/cfg}

cat <<EOF >/opt/kubernetes/cfg/kubelet
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=4"
NODE_ADDRESS="--address=${NODE_ADDRESS}"
NODE_HOSTNAME="--hostname-override=${NODE_ADDRESS}"
KUBELET_KUBECONFIG="--kubeconfig=${KUBECONFIG_DIR}/kubelet.kubeconfig"
KUBELET_BOOTSTRAP="--experimental-bootstrap-kubeconfig=${KUBECONFIG_DIR}/bootstrap.kubeconfig"
KUBELET_CERT="--cert-dir=/opt/kubernetes/ssl"
KUBE_ALLOW_PRIV="--allow-privileged=true"
KUBELET__DNS_IP="--cluster-dns=${DNS_SERVER_IP}"
KUBELET_DNS_DOMAIN="--cluster-domain=${DNS_DOMAIN}"
KUBELET_SWAP="--fail-swap-on=false"
KUBELET_POD="--pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google-comtainers/pause-amd64:3.0"
KUBELET_ARGS=""
EOF

KUBELET_OPTS="      \${KUBE_LOGTOSTDERR}     \\
                    \${KUBE_LOG_LEVEL}       \\
                    \${NODE_ADDRESS}         \\
                    \${NODE_HOSTNAME}        \\
                    \${KUBELET_KUBECONFIG}   \\
                    \${KUBE_ALLOW_PRIV}      \\
                    \${KUBELET__DNS_IP}      \\
                    \${KUBELET_DNS_DOMAIN}   \\
                    \${KUBELET_BOOTSTRAP}    \\
                    \${KUBELET_SWAP}         \\
                    \${KUBELET_POD}          \\
                    \${KUBELET_CERT}         \\
                    \$KUBELET_ARGS"

cat <<EOF >/usr/lib/systemd/system/kubelet.service
[Unit]
Description=Kubernetes Kubelet
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kubelet
ExecStart=/opt/kubernetes/bin/kubelet ${KUBELET_OPTS}
Restart=on-failure
KillMode=process
RestartSec=15s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kubelet
systemctl restart kubelet