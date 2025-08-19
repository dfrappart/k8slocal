#!/bin/sh

echo "Creating new certificate and key files..."
mkdir -p ../cert

cp ./k8scilium1.ext ../cert/k8scilium1.ext

cd ../cert

CANAME=Teknews-RootCA

MYCERT=k8scilium1


# generate aes encrypted private key
openssl genrsa -aes256 -out $CANAME.key 4096

# create certificate, 1826 days = 5 years

# ... or you provide common name, country etc. via:
openssl req -x509 -new -nodes -key $CANAME.key -sha256 -days 1826 -out $CANAME.crt -subj '/CN=teknews CA/C=FR/ST=Urithiru/L=Urithiru/O=teknews/OU=teknews'

openssl req -new -nodes -out $MYCERT.csr -newkey rsa:4096 -keyout $MYCERT.key -subj '/CN=teknews CA/C=FR/ST=Urithiru/L=Urithiru/O=teknews/OU=teknews'

openssl x509 -req -in $MYCERT.csr -CA $CANAME.crt -CAkey $CANAME.key -CAcreateserial -out $MYCERT.crt -days 730 -sha256 -extfile $MYCERT.ext