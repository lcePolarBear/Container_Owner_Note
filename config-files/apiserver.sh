#!/usr/bin/env bash

MASTER_ADDRESS=${1:-"8.8.8.18"}
ETCD_SERVERS=${2:-"https://8.8.8.18:2379"}
SERVICE_CLUSTER_IP_RANGE=${3:-"10.10.10.0/24"}
ADMISSION_CONTROL=${4:-"NamespaceLifecycle,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota,NodeRestriction"}

cat <<EOF >/opt/kubernetes/cfg/kube-apiserver
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=4"
KUBE_ETCD_SERVERS="--etcd-servers=${ETCD_SERVERS}"
KUBE_ETCD_CAFILE="--etcd-cafile=/opt/kubernetes/ssl/ca.pem"
KUBE_ETCD_CERTFILE="--etcd-certfile=/opt/kubernetes/ssl/server.pem"
KUBE_ETCD_KEYFILE="--etcd-keyfile=/opt/kubernetes/ssl/server-key.pem"
KUBE_API_ADDRESS="--insecure-bind-address=127.0.0.1"
KUBE_API_PORT="--insecure-port=8080"
NODE_PORT="--secure-port=6443"
KUBE_MODE="--authorization-mode=RBAC,Node"
KUBE_HTTPS="--kubelet-https=true"
KUBE_BOOTSTRAP_TOKEN="--enable-bootstrap-token-auth"
KUBE_TOKEN_FILE="--token-auth-file=/opt/kubernetes/cfg/token.csv"
KUBE_SERVICE_PORT="--service-node-port-range=30000-50000"
KUBE_ADVERTISE_ADDR="--advertise-address=${MASTER_ADDRESS}"
KUBE_ALLOW_PRIV="--allow-privileged=true"
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE}"
KUBE_ADMISSION_CONTROL="--admission-control=${ADMISSION_CONTROL}"
KUBE_API_CLIENT_CA_FILE="--client-ca-file=/opt/kubernetes/ssl/ca.pem"
KUBE_API_TLS_CERT_FILE="--tls-cert-file=/opt/kubernetes/ssl/server.pem"
KUBE_API_TLS_PRIVATE_KEY_FILE="--tls-private-key-file=/opt/kubernetes/ssl/server-key.pem"
EOF

KUBE_APISERVER_OPTS="   \${KUBE_LOGTOSTDERR}         \\
                        \${KUBE_LOG_LEVEL}           \\
                        \${KUBE_ETCD_SERVERS}        \\
                        \${KUBE_ETCD_CAFILE}         \\
                        \${KUBE_ETCD_CERTFILE}       \\
                        \${KUBE_ETCD_KEYFILE}        \\
                        \${KUBE_API_ADDRESS}         \\
                        \${KUBE_API_PORT}            \\
                        \${NODE_PORT}                \\
                        \${KUBE_ADVERTISE_ADDR}      \\
                        \${KUBE_ALLOW_PRIV}          \\
                        \${KUBE_SERVICE_ADDRESSES}   \\
                        \${KUBE_ADMISSION_CONTROL}   \\
                        \${KUBE_API_CLIENT_CA_FILE}  \\
                        \${KUBE_API_TLS_CERT_FILE}   \\
                        \${KUBE_API_TLS_PRIVATE_KEY_FILE}  \\
                        \${KUBE_MODE}                \\
                        \${KUBE_HTTPS}               \\
                        \${KUBE_BOOTSTRAP_TOKEN}     \\
                        \${KUBE_TOKEN_FILE}          \\
                        \${KUBE_SERVICE_PORT}"


cat <<EOF >/usr/lib/systemd/system/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/opt/kubernetes/cfg/kube-apiserver
ExecStart=/opt/kubernetes/bin/kube-apiserver ${KUBE_APISERVER_OPTS}
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-apiserver
systemctl restart kube-apiserver
