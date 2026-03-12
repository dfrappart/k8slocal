#!/bin/sh

# Generate CA Key

openssl genrsa -out vault-ca.key 4096

# Generate CA Certificate

openssl req -x509 -new -nodes \
  -key vault-ca.key \
  -sha256 \
  -days 3650 \
  -out vault-ca.crt \
  -subj "/C=Fr/O=Dfitc/CN=Vault-CA"

# Create Vault Private Key

openssl genrsa -out vault.key 4096

# Create hashikube Private Key

openssl genrsa -out hashikube.key 4096

# Generate CSR

openssl req -new \
  -key vault.key \
  -out vault.csr \
  -config vault-openssl.cnf

openssl req -new \
  -key hashikube.key \
  -out hashikube.csr \
  -config hashikube-openssl.cnf

# Sign Certificate with CA

openssl x509 -req \
  -in vault.csr \
  -CA vault-ca.crt \
  -CAkey vault-ca.key \
  -CAcreateserial \
  -out vault.crt \
  -days 825 \
  -sha256 \
  -extensions req_ext \
  -extfile vault-openssl.cnf


openssl x509 -req \
  -in hashikube.csr \
  -CA vault-ca.crt \
  -CAkey vault-ca.key \
  -CAcreateserial \
  -out hashikube.crt \
  -days 825 \
  -sha256 \
  -extensions req_ext \
  -extfile hashikube-openssl.cnf
  
  # Clean up

  mv vault.crt vault.key vault-ca.crt vault-ca.key vault.srl vault.csr vault-ca.srl hashikube.crt hashikube.key hashikube.csr ../cert
