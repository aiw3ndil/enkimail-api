require 'dnsruby'

class VerifyDomainJob < ApplicationJob
  queue_as :default

  def perform(domain_id)
    domain = Domain.find_by(id: domain_id)
    return unless domain

    domain.update(verification_error: nil) # Reset error message

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
      resolver = Dnsruby::Resolver.new
      resources = resolver.query(domain.name, Dnsruby::Types::TXT).answer
      verification_record = resources.find { |r| r.rdata.to_s.include?("enkimail-verification=#{domain.verification_token}") }

      unless verification_record
        domain.update(verification_error: "Ownership verification failed. TXT record not found or does not match.")
      end
    rescue => e
      domain.update(verification_error: "DNS lookup failed for ownership verification: #{e.message}")
    end
  end

  def verify_spf(domain)
    return if domain.verification_error.present? # Fail early
    
    begin
      resolver = Dnsruby::Resolver.new
      resources = resolver.query(domain.name, Dnsruby::Types::TXT).answer
      spf_record = resources.find { |r| r.rdata.to_s.include?("v=spf1") }

      if spf_record && spf_record.rdata.to_s.include?("include:mail.enkimail.com")
        # SPF passed
      else
        domain.update(verification_error: "SPF record missing or incorrect. Expected to include 'mail.enkimail.com'.")
      end
    rescue => e
      domain.update(verification_error: "DNS lookup failed for SPF: #{e.message}")
    end
  end

  def verify_dkim(domain)
    return if domain.verification_error.present? # Fail early

    begin
      resolver = Dnsruby::Resolver.new
      selector_domain = "#{domain.dkim_selector}._domainkey.#{domain.name}"
      resources = resolver.query(selector_domain, Dnsruby::Types::TXT).answer
      dkim_record = resources.first

      if dkim_record && dkim_record.rdata.to_s.include?(domain.dkim_public_key)
        # DKIM passed
      else
         domain.update(verification_error: "DKIM record missing or incorrect. Check selector '#{domain.dkim_selector}' and key value.")
      end
    rescue => e
       domain.update(verification_error: "DNS lookup failed for DKIM: #{e.message}")
    end
  end
end
