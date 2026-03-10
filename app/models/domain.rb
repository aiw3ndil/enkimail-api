class Domain < ApplicationRecord
  belongs_to :user

  enum status: { pending: 0, verified: 1, failed: 2 }

  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}\z/i }
  validate :check_domain_limit, on: :create
  
  before_create :generate_dkim_keys
  before_create :set_default_selector
  before_create :generate_verification_token

  after_save :export_dkim_key, if: :saved_change_to_status?

  def generate_dkim_keys
    return if dkim_private_key.present? && dkim_public_key.present?

    key = OpenSSL::PKey::RSA.new(2048)
    self.dkim_private_key = key.to_pem
    self.dkim_public_key = key.public_key.to_pem.gsub("-----BEGIN PUBLIC KEY-----", "").gsub("-----END PUBLIC KEY-----", "").gsub("\n", "")
  end

  def set_default_selector
    self.dkim_selector ||= "enki"
  end
  
  def dkim_record_name
    "#{dkim_selector}._domainkey"
  end

  def dkim_record_value
    "v=DKIM1; k=rsa; p=#{dkim_public_key}"
  end

  def dkim_record_value_split
    # Split public key into chunks of 255 characters for DNS TXT records
    chunks = dkim_public_key.scan(/.{1,255}/)
    "\"v=DKIM1; k=rsa; p=#{chunks.join('" "')}\""
  end
  
  def spf_record_value
    "v=spf1 ip4:54.37.230.86 include:mx.ovh.com -all"
  end

  def verification_record_name
    "@"
  end

  def verification_record_value
    "enkimail-verification=#{verification_token}"
  end

  # Instance method: writes this domain's private key to disk, then
  # re-generates ALL shared config files from the current DB state.
  def export_dkim_key
    return unless verified?

    begin
      base_dir = ENV['OPENDKIM_DATA_PATH'] || Rails.root.join("config", "opendkim")
      directory = Pathname.new(base_dir)
      keys_directory = directory.join("keys", name)
      FileUtils.mkdir_p(keys_directory)

      # 1. Write private key (mwader/postfix-relay format: keys/<domain>/<selector>.private)
      key_file = keys_directory.join("#{dkim_selector}.private")
      File.write(key_file, dkim_private_key)
      File.chmod(0644, key_file)

      # 2. Regenerate all shared config files from DB, so we never accumulate stale entries
      Domain.regenerate_opendkim_config(base_dir)

      Rails.logger.info "DKIM keys exported successfully for #{name}"
    rescue => e
      Rails.logger.error "Failed to export DKIM keys for #{name}: #{e.message}"
    end
  end

  # Class method: regenerates KeyTable, SigningTable, TrustedHosts and opendkim.conf
  # by reading ALL verified domains from the DB. Call this after any domain change.
  def self.regenerate_opendkim_config(base_dir = nil)
    base_dir ||= ENV['OPENDKIM_DATA_PATH'] || Rails.root.join("config", "opendkim")
    directory = Pathname.new(base_dir)
    FileUtils.mkdir_p(directory)

    domains = Domain.verified.to_a
    return if domains.empty?

    # --- KeyTable ---
    # Format: selector._domainkey.domain  domain:selector:/path/to/key
    key_table_lines = domains.map do |d|
      "#{d.dkim_selector}._domainkey.#{d.name} #{d.name}:#{d.dkim_selector}:/etc/opendkim/keys/#{d.name}/#{d.dkim_selector}.private"
    end
    File.write(directory.join("KeyTable"), key_table_lines.join("\n") + "\n")
    File.chmod(0644, directory.join("KeyTable"))

    # --- SigningTable ---
    # Format: *@domain  selector._domainkey.domain  (wildcard for all subaddresses)
    signing_table_lines = domains.map do |d|
      "*@#{d.name} #{d.dkim_selector}._domainkey.#{d.name}"
    end
    File.write(directory.join("SigningTable"), signing_table_lines.join("\n") + "\n")
    File.chmod(0644, directory.join("SigningTable"))

    # --- TrustedHosts ---
    base_hosts = ["127.0.0.1", "localhost", "172.16.0.0/12", "192.168.0.0/16", "10.0.0.0/8"]
    domain_hosts = domains.map(&:name)
    all_hosts = (base_hosts + domain_hosts).uniq
    File.write(directory.join("TrustedHosts"), all_hosts.join("\n") + "\n")
    File.chmod(0644, directory.join("TrustedHosts"))

    # --- opendkim.conf ---
    # Always overwrite so it stays up-to-date with current selector
    conf_content = <<~CONF
      Syslog                  yes
      UMask                   002
      Socket                  inet:12301@localhost
      KeyTable                /etc/opendkim/KeyTable
      SigningTable            refile:/etc/opendkim/SigningTable
      ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
      InternalHosts           refile:/etc/opendkim/TrustedHosts
      Canonicalization        relaxed/simple
      Mode                    sv
      SubDomains              no
      OversignHeaders         From
    CONF
    File.write(directory.join("opendkim.conf"), conf_content)
    File.chmod(0644, directory.join("opendkim.conf"))

    Rails.logger.info "OpenDKIM config regenerated for #{domains.size} domain(s)"
  rescue => e
    Rails.logger.error "Failed to regenerate OpenDKIM config: #{e.message}"
  end

  def dns_instructions
    {
      verification: {
        type: "TXT",
        host: "@",
        value: verification_record_value
      },
      spf: {
        type: "TXT",
        host: "@",
        value: spf_record_value
      },
      dkim: {
        type: "TXT",
        host: "#{dkim_selector}._domainkey",
        value: dkim_record_value
      }
    }
  end

  private

  def generate_verification_token
    self.verification_token = "enkiverify-#{SecureRandom.hex(16)}"
  end

  def check_domain_limit
    limit = user&.pro? ? 10 : 1
    if user && user.domains.count >= limit
      errors.add(:base, "#{user.role.capitalize} plan is limited to #{limit} Domain(s). Upgrade to Pro to add more.")
    end
  end
end
