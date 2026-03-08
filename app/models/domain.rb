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
    self.dkim_selector ||= "mail"
  end
  
  def dkim_record_name
    "#{dkim_selector}._domainkey"
  end

  def dkim_record_value
    "v=DKIM1; k=rsa; p=#{dkim_public_key}"
  end
  
  def spf_record_value
    "v=spf1 include:mail.enkimail.com ~all" 
  end

  def verification_record_name
    "@"
  end

  def verification_record_value
    "enkimail-verification=#{verification_token}"
  end

  def export_dkim_key
    return unless verified?

    # Usamos una ruta configurable para el volumen compartido
    base_dir = ENV.fetch("OPENDKIM_DATA_PATH", Rails.root.join("config", "dkim_tables"))
    directory = Pathname.new(base_dir)
    keys_directory = directory.join("keys")
    
    # Creamos la estructura base
    FileUtils.mkdir_p(keys_directory) unless Dir.exist?(keys_directory)

    # 1. Exportar llave privada con permisos de lectura
    key_file = keys_directory.join("#{name}.private")
    File.write(key_file, dkim_private_key)
    File.chmod(0644, key_file) # Permitir que OpenDKIM la lea
    
    # Función auxiliar mejorada
    ensure_is_file = ->(path) do
      system("rm -rf #{path}") if Dir.exist?(path)
      FileUtils.touch(path) unless File.exist?(path)
      File.chmod(0644, path)
    end

    # 2. Actualizar KeyTable
    key_table_path = directory.join("KeyTable")
    ensure_is_file.call(key_table_path)
    key_line = "#{dkim_selector}._domainkey.#{name} #{name}:#{dkim_selector}:/etc/opendkim/keys/#{name}.private"
    lines = File.readlines(key_table_path).map(&:strip) rescue []
    File.open(key_table_path, "a") { |f| f.puts(key_line) } unless lines.include?(key_line)

    # 3. Actualizar SigningTable
    signing_table_path = directory.join("SigningTable")
    ensure_is_file.call(signing_table_path)
    signing_line = "*@#{name} #{dkim_selector}._domainkey.#{name}"
    lines = File.readlines(signing_table_path).map(&:strip) rescue []
    File.open(signing_table_path, "a") { |f| f.puts(signing_line) } unless lines.include?(signing_line)

    # 4. Actualizar TrustedHosts
    trusted_hosts_path = directory.join("TrustedHosts")
    ensure_is_file.call(trusted_hosts_path)
    default_hosts = ["127.0.0.1", "localhost", "172.16.0.0/12", "192.168.0.0/16", "10.0.0.0/8", "0.0.0.0/0"]
    current_hosts = File.readlines(trusted_hosts_path).map(&:strip) rescue []
    File.open(trusted_hosts_path, "a") do |f|
      (default_hosts + [name]).each do |host|
        f.puts(host) unless current_hosts.include?(host)
      end
    end

    # 5. Generar opendkim.conf robusto para sobrescribir cualquier basura previa
    conf_path = directory.join("opendkim.conf")
    conf_content = <<~CONF
      Syslog          yes
      UMask           002
      Canonicalization    relaxed/simple
      Mode                s
      SubDomains          no
      Socket              inet:12301@localhost
      PidFile             /var/run/opendkim/opendkim.pid

      KeyTable            file:/etc/opendkim/KeyTable
      SigningTable        refile:/etc/opendkim/SigningTable
      ExternalIgnoreList  file:/etc/opendkim/TrustedHosts
      InternalHosts       file:/etc/opendkim/TrustedHosts
    CONF
    File.write(conf_path, conf_content)
    File.chmod(0644, conf_path)
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
