#!/usr/bin/env bash

MASTER_ADDRESS=${1:-"127.0.0.1"}
SERVICE_CLUSTER_IP_RANGE=${3:-"10.10.10.0/24"}

cat <<EOF >/opt/kubernetes/cfg/kube-controller-manager
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=4"
KUBE_MASTER="--master=${MASTER_ADDRESS}:8080"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE}"
KUBE_CLUSTER_NAME="--cluster-name=kubernetes"
KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE="--root-ca-file=/opt/kubernetes/ssl/ca.pem"
KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE="--service-account-private-key-file=/opt/kubernetes/ssl/ca-key.key"
KUBE_CONTROLLER_MANAGER_CLUSTER_SIGNING_CERT_FILE="--cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem"
KUBE_CONTROLLER_MANAGER_CLUSTER_SIGNING_KEY_FILE="--cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem"
KUBE_LEADER_ELECT="--leader-elect=true"
EOF

KUBE_CONTROLLER_MANAGER_OPTS="  \${KUBE_LOGTOSTDERR} \\
                                \${KUBE_LOG_LEVEL}   \\
                                \${KUBE_MASTER}      \\
                                \${KUBE_CONTROLLER_MANAGER_ROOT_CA_FILE} \\
                                \${KUBE_CONTROLLER_MANAGER_SERVICE_ACCOUNT_PRIVATE_KEY_FILE}\\
                                \${KUBE_SERVICE_ADDRESSES}  \\
                                \${KUBE_CLUSTER_NAME}   \\
                                \${KUBE_CONTROLLER_MANAGER_CLUSTER_SIGNING_CERT_FILE}   \\
                                \${KUBE_CONTROLLER_MANAGER_CLUSTER_SIGNING_KEY_FILE}    \\
                                \${KUBE_LEADER_ELECT}"

cat <<EOF >/usr/lib/systemd/system/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-controller-manager
ExecStart=/opt/kubernetes/bin/kube-controller-manager ${KUBE_CONTROLLER_MANAGER_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-controller-manager
systemctl restart kube-controller-manager
