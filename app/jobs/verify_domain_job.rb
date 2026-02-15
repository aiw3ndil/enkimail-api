require 'resolv'

class VerifyDomainJob < ApplicationJob
  queue_as :default

  def perform(domain_id)
    domain = Domain.find_by(id: domain_id)
    return unless domain

    domain.verification_error = nil # Reset error message

    verify_ownership(domain)
    verify_spf(domain)
    verify_dkim(domain)
    
    if domain.verification_error.blank?
      domain.verified!
      domain.update(verified_at: Time.current)
    else
      domain.failed!
    end
  end

  private
  
  def verify_ownership(domain)
    return if domain.verification_error.present? # Fail early

    begin
      resources = Resolv::DNS.open { |dns| dns.getresources(domain.name, Resolv::DNS::Resource::IN::TXT) }
      verification_record = resources.find { |r| r.data.include?("enkimail-verification=#{domain.verification_token}") }

      unless verification_record
        domain.verification_error = "Ownership verification failed. TXT record not found or does not match."
      end
    rescue => e
      domain.verification_error = "DNS lookup failed for ownership verification: #{e.message}"
    end
  end

  def verify_spf(domain)
    return if domain.verification_error.present? # Fail early
    
    begin
      resources = Resolv::DNS.open { |dns| dns.getresources(domain.name, Resolv::DNS::Resource::IN::TXT) }
      spf_record = resources.find { |r| r.data.include?("v=spf1") }

      if spf_record && spf_record.data.include?("include:mail.enkimail.com")
        # SPF passed
      else
        domain.verification_error = "SPF record missing or incorrect. Expected to include 'mail.enkimail.com'."
      end
    rescue => e
      domain.verification_error = "DNS lookup failed for SPF: #{e.message}"
    end
  end

  def verify_dkim(domain)
    return if domain.verification_error.present? # Fail early

    begin
      selector_domain = "#{domain.dkim_selector}._domainkey.#{domain.name}"
      resources = Resolv::DNS.open { |dns| dns.getresources(selector_domain, Resolv::DNS::Resource::IN::TXT) }
      dkim_record = resources.first

      if dkim_record && dkim_record.data.include?(domain.dkim_public_key)
        # DKIM passed
      else
         domain.verification_error = "DKIM record missing or incorrect. Check selector '#{domain.dkim_selector}' and key value."
      end
    rescue => e
       domain.verification_error = "DNS lookup failed for DKIM: #{e.message}"
    end
  end
end
