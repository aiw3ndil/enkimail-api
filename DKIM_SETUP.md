# DKIM Configuration Guide

## Overview

This project uses OpenDKIM to sign outgoing emails with DKIM signatures. The DKIM keys are managed by the Rails application and automatically exported to the Postfix container for signing.

## How It Works

### 1. Key Generation
When a domain is created in EnkiMail, the `Domain` model generates a 2048-bit RSA key pair:
- **Private Key**: Stored in the database (encrypted at rest if enabled)
- **Public Key**: Also stored in the database and used to generate DNS records

### 2. Key Export
When a domain is verified, the `export_dkim_key` method:
1. Exports the private key to disk at: `/config/opendkim/keys/{domain}/{selector}.private`
2. Sets secure permissions: `0600` (read/write by owner only)
3. Regenerates OpenDKIM configuration files

### 3. OpenDKIM Configuration Files

The following files are automatically generated in `/config/opendkim/`:

- **KeyTable**: Maps DKIM keys to domains
  ```
  enki._domainkey.truek.xyz truek.xyz:enki:/etc/opendkim/keys/truek.xyz/enki.private
  ```

- **SigningTable**: Maps email addresses to DKIM keys
  ```
  *@truek.xyz enki._domainkey.truek.xyz
  ```

- **TrustedHosts**: Hosts allowed to use this DKIM service
  ```
  127.0.0.1
  localhost
  172.16.0.0/12
  192.168.0.0/16
  10.0.0.0/8
  truek.xyz
  ```

- **opendkim.conf**: Main OpenDKIM configuration

### 4. DNS Records

When a domain is created, the application provides the DNS records needed:

```
Host: enki._domainkey
Type: TXT
Value: v=DKIM1; k=rsa; p={public_key_split_into_255_char_chunks}
```

For OVH (and providers that support split TXT records), the public key is split into chunks of 255 characters:

```
"v=DKIM1; k=rsa; p={chunk1}" "{chunk2}"
```

## Docker Setup

### Dockerfile.postfix
A custom Dockerfile extends `mwader/postfix-relay` to:
1. Ensure DKIM key files have correct permissions (600) before OpenDKIM starts
2. Automatically fix permissions on container startup

### Docker Compose
The `postfix` service:
- Mounts `/config/opendkim` as a volume for persistence
- Sets environment variables for OpenDKIM domains
- Uses the custom Dockerfile

## Security Considerations

1. **Private Key Permissions**: Must be `0600` (read/write by owner only). OpenDKIM enforces this.
2. **Key Ownership**: Files must be owned by the `opendkim` user in the container
3. **Secret Protection**: Private keys in the database should be encrypted using Rails encrypted credentials

## Troubleshooting

### "key data is not secure" Error
This error occurs when the private key file has incorrect permissions.
- Check file permissions: should be `0600`
- Check file ownership: should be `opendkim:opendkim`
- Solution: Run `/usr/local/bin/fix-dkim-perms.sh` in the container

### OpenDKIM Not Signing
1. Verify OpenDKIM is running: `docker exec enkimail-postfix ps aux | grep opendkim`
2. Check if Postfix is configured for milters: `docker exec enkimail-postfix postconf | grep milter`
3. Review logs: `docker logs enkimail-postfix | grep -i dkim`

### DNS Records Not Found
1. Verify the DKIM DNS record is published: `dig enki._domainkey.yourdomain.com TXT`
2. For OVH multi-part records, ensure both chunks are in the same TXT record
3. Wait for DNS propagation (usually 5-30 minutes)

## Adding a New Domain

1. Create domain in the application (API or UI)
2. The application generates DKIM keys
3. Export DNS records from the domain details
4. Add the DKIM TXT record to your DNS provider
5. Verify the domain in the application
6. The application exports the private key and updates OpenDKIM configuration
7. New domains are automatically signed by OpenDKIM

## Testing DKIM Signing

To verify DKIM signing is working:

```bash
# Send a test email through Postfix
cat > /tmp/test.txt << 'EOF'
EHLO test.local
MAIL FROM:<test@yourdomain.com>
RCPT TO:<recipient@example.com>
DATA
From: test@yourdomain.com
To: recipient@example.com
Subject: Test DKIM

Test body
.
QUIT
EOF

nc localhost 2525 < /tmp/test.txt
```

The email should be accepted with status `250 2.0.0 Ok`.

To verify the DKIM signature in the received email, check the headers for:
```
DKIM-Signature: v=1; a=rsa-sha256; c=relaxed/simple; d=yourdomain.com; ...
```
