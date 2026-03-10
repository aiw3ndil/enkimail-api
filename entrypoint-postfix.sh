#!/bin/bash
set -e

echo "--------------------------------------------------------"
echo "EnkiMail Aggressive OpenDKIM Configuration starting..."
echo "--------------------------------------------------------"

# 1. Delete standard/pre-existing config files that might be used instead of ours
# This is "extremely aggressive" as requested.
rm -f /etc/opendkim.conf
rm -f /etc/default/opendkim

# 2. Fix DKIM key permissions before starting
if [ -d "/etc/opendkim" ]; then
  echo "Applying permissions to /etc/opendkim..."
  # Ensure the directory is accessible
  chmod 755 /etc/opendkim
  chown opendkim:opendkim /etc/opendkim || true
  
  if [ -d "/etc/opendkim/keys" ]; then
    find /etc/opendkim/keys -type d -exec chmod 755 {} \;
    find /etc/opendkim/keys -name "*.private" -type f -exec chmod 640 {} \;
    chown -R opendkim:opendkim /etc/opendkim/keys || true
  fi
fi

# 3. Patch the main startup script (/root/run) OBLIGATORIAMENTE
# We replace any attempt to start opendkim with our forced command.
if [ -f /root/run ]; then
    echo "Aggressively patching /root/run to force opendkim config..."
    
    # Remove any existing opendkim start lines to avoid conflicts
    # We look for anything that looks like an opendkim start command
    sed -i '/opendkim/d' /root/run
    
    # Insert our forced start command after the shebang or at the beginning of the setup
    # We run it in background (&) so it doesn't block postfix startup
    # We use -f (foreground) with & so it's supervised by the & 
    # but actually -u opendkim -x config is enough.
    echo "/usr/sbin/opendkim -u opendkim -x /etc/opendkim/opendkim.conf &" >> /root/run
    
    echo "Patching complete. /root/run now contains forced OpenDKIM start."
fi

# Execute the original command (usually /root/run)
exec "$@"
