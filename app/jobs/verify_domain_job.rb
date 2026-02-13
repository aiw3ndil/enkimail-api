require 'resolv'

class VerifyDomainJob < ApplicationJob
  queue_as :default

  def perform(domain_id)
    domain = Domain.find_by(id: domain_id)
    return unless domain

    verify_spf(domain)
    verify_dkim(domain)
    
    if domain.verification_error.blank?
      domain.verified!
    else
      domain.failed!
    end
  end

  private

  def verify_spf(domain)
    # Check SPF record
    # Expected: "v=spf1 include:mail.enkimail.com ~all" or similar
    # For MVP, just checking if it contains 'include:mail.enkimail.com'
    
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

    # Check DKIM record
    # Expected: v=DKIM1; k=rsa; p=...
    
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
