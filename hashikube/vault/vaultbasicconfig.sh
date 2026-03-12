#!/bin/sh

# Requires vault CLI to be installed and VAULT_ADDR env variable set, and to be authenticated with sufficient privileges, very probably with token authentcation.

# Enable vault userpass authentication

vault auth enable userpass

# Enable kv secret engine v2 at /hashikube/secrets

vault secrets enable -version 2 -path /hashikube/secrets kv

vault secret tune -description "HashiKube Secrets Engine" /hashikube/secrets

# Create policy for terraform user

vault policy write admin-policy ./vault/admin-policy.hcl

# Create terraform user for terraform

# vault write auth/userpass/users/terraform password=$userpassword policies=