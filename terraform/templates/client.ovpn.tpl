client
dev tun
proto udp
cipher AES-256-GCM
remote ${endpoint} 443
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
verb 3

pull
route ${vpc_network} ${vpc_netmask}

<ca>
${ca_cert}
</ca>

<cert>
${client_cert}
</cert>

<key>
${client_key}
</key>