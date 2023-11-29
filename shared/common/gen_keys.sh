# Generating a CA Certificate
pki --gen --type ed25519 --outform pem > strongswanKey.pem
pki --self --ca --lifetime 3652 --in strongswanKey.pem \
           --dn "C=CH, O=strongSwan, CN=strongSwan Root CA" \
           --outform pem > strongswanCert.pem
pki --print --in strongswanCert.pem

# Generating an End Entity Certificate
pki --gen --type ed25519 --outform pem > moonKey.pem
pki --req --type priv --in moonKey.pem \
          --dn "C=CH, O=strongswan, CN=moon.strongswan.org" \
          --san moon.strongswan.org --outform pem > moonReq.pem
pki --issue --cacert strongswanCert.pem --cakey strongswanKey.pem \
            --type pkcs10 --in moonReq.pem --serial 01 --lifetime 1826 \
            --outform pem > moonCert.pem
pki --print --in moonCert.pem

pki --gen --type ed25519 --outform pem > sunKey.pem
pki --req --type priv --in sunKey.pem \
          --dn "C=CH, O=strongswan, CN=sun.strongswan.org" \
          --san sun.strongswan.org --outform pem > sunReq.pem
pki --issue --cacert strongswanCert.pem --cakey strongswanKey.pem \
            --type pkcs10 --in sunReq.pem --serial 01 --lifetime 1826 \
            --outform pem > sunCert.pem
pki --print --in sunCert.pem
