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

  def export_dkim_key
    return unless verified?

    begin
      base_dir = ENV['OPENDKIM_DATA_PATH'] || Rails.root.join("config", "opendkim")
      directory = Pathname.new(base_dir)
      keys_directory = directory.join("keys")
      
      FileUtils.mkdir_p(keys_directory) unless Dir.exist?(keys_directory)

      # 1. Exportar llave privada
      key_file = keys_directory.join("#{name}.private")
      File.write(key_file, dkim_private_key)
      File.chmod(0644, key_file)
      
      # Función auxiliar para asegurar que la ruta sea un archivo
      ensure_file = ->(path) do
        system("rm -rf #{path}") if Dir.exist?(path)
        FileUtils.touch(path) unless File.exist?(path)
        File.chmod(0644, path)
      end

      # 2. KeyTable
      path = directory.join("KeyTable")
      ensure_file.call(path)
      line = "#{dkim_selector}._domainkey.#{name} #{name}:#{dkim_selector}:/etc/opendkim/keys/#{name}.private"
      lines = File.readlines(path).map(&:strip).reject(&:empty?) rescue []
      lines << line unless lines.include?(line)
      File.write(path, lines.join("\n") + "\n")

      # 3. SigningTable
      path = directory.join("SigningTable")
      ensure_file.call(path)
      line = "*@#{name} #{dkim_selector}._domainkey.#{name}"
      lines = File.readlines(path).map(&:strip).reject(&:empty?) rescue []
      lines << line unless lines.include?(line)
      File.write(path, lines.join("\n") + "\n")

      # 4. TrustedHosts
      path = directory.join("TrustedHosts")
      ensure_file.call(path)
      hosts_to_add = ["127.0.0.1", "localhost", "172.16.0.0/12", "192.168.0.0/16", "10.0.0.0/8", "0.0.0.0/0", name]
      existing = File.readlines(path).map(&:strip).reject(&:empty?) rescue []
      (hosts_to_add - existing).each { |h| existing << h }
      File.write(path, existing.join("\n") + "\n")
      
      Rails.logger.info "DKIM keys exported successfully for #{name}"
    rescue => e
      Rails.logger.error "Failed to export DKIM keys for #{name}: #{e.message}"
      puts "ERROR: Failed to export DKIM keys for #{name}: #{e.message}"
    end
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
