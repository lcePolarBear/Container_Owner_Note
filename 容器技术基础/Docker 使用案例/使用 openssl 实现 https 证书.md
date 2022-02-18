__获取 CA 的 ca.key , ca.crt__
* 使用 genrsa 标准命令生成私钥
  ```
  openssl genrsa -out ca.key 4096
  ```
* 再从私钥中提取公钥
    ```
    openssl req -x509 -new -nodes -sha512 -days 3650 \
    -subj "/C=TW/ST=Taipei/L=Taipei/O=example/OU=Personal/CN=chen.com" \
    -key ca.key \
    -out ca.crt
    ```
    - -out filename：将生成的私钥保存至指定的文件中
    - numbits：指定生成私钥的大小
* 这样我们就获得了 CA 的公钥 ca.key 和 CA 的私钥 ca.crt

__获取服务器证书__
* 创建服务器私钥
    ```
    openssl genrsa -out chen.com.key 4096
    ```
* 生成服务器证书签署请求
    ```
    openssl req -sha512 -new \
    -subj "/C=TW/ST=Taipei/L=Taipei/O=example/OU=Personal/CN=chen.com" \
    -key chen.com.key \
    -out chen.com.csr
    ```
* 获取 registry host 的证书
    ```
    cat > v3.ext <<-EOF
    authorityKeyIdentifier=keyid,issuer
    basicConstraints=CA:FALSE
    keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
    extendedKeyUsage = serverAuth 
    subjectAltName = @alt_names

    [alt_names]
    DNS.1=chen.com
    DNS.2=hostname
    EOF
    ```
* 创建服务器私钥
    ```
    openssl x509 -req -sha512 -days 3650 \
    -extfile v3.ext \
    -CA ca.crt -CAkey ca.key -CAcreateserial \
    -in chen.com.csr \
    -out chen.com.crt
    ```
* 这样我们就获得了服务器的公钥 `chen.com.key` 和服务器的私钥 `chen.com.crt`