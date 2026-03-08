class Domain < ApplicationRecord
  belongs_to :user

  enum status: { pending: 0, verified: 1, failed: 2 }

  validates :name, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}\z/i }
  validate :check_domain_limit, on: :create
  
  before_create :generate_dkim_keys
  before_create :set_default_selector
  before_create :generate_verification_token

  def generate_dkim_keys
    return if dkim_private_key.present? && dkim_public_key.present?

    key = OpenSSL::PKey::RSA.new(2048)
    self.dkim_private_key = key.to_pem
    
    # Extract public key in the format needed for DNS TXT record
    # v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQ...
    
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
  
  def spf_record_value
    "v=spf1 include:mail.enkimail.com ~all" 
  end

  def verification_record_name
    "@"
  end

  def verification_record_value
    "enkimail-verification=#{verification_token}"
  end

  after_save :export_dkim_key, if: :saved_change_to_status?

  def export_dkim_key
    return unless verified?

    directory = Rails.root.join("config", "opendkim", "keys")
    FileUtils.mkdir_p(directory) unless Dir.exist?(directory)

    # El formato que espera postfix-relay suele ser /etc/opendkim/keys/dominio.private
    File.write(File.join(directory, "#{name}.private"), dkim_private_key)
    
    # También necesitamos actualizar un archivo que liste los dominios si el contenedor lo requiere
    # Esto dependerá de cómo el contenedor mwader/postfix-relay procese los archivos.
  end

  private

  def generate_verification_token
    self.verification_token = "enkiverify-#{SecureRandom.hex(16)}"
  end

  def check_domain_limit
    limit = user.pro? ? 10 : 1
    if user.domains.count >= limit
      errors.add(:base, "#{user.role.capitalize} plan is limited to #{limit} Domain(s). Upgrade to Pro to add more.")
    end
  end
end
