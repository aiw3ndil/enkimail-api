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

      if spf_record && spf_record.rdata.to_s.include?("ip4:54.37.230.86")
        # SPF passed
      else
        domain.update(verification_error: "SPF record missing or incorrect. Expected to include 'ip4:54.37.230.86' and 'include:mx.ovh.com'.")
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

      # DKIM records can be split into multiple strings (e.g., OVH)
      # We need to join them to get the full record
      full_dkim_record = if dkim_record.respond_to?(:strings)
                           dkim_record.strings.join
                         else
                           dkim_record&.rdata.to_s
                         end

      if full_dkim_record.include?(domain.dkim_public_key)
        # DKIM passed
      else
         domain.update(verification_error: "DKIM record missing or incorrect. Check selector '#{domain.dkim_selector}' and key value.")
      end
    rescue => e
       domain.update(verification_error: "DNS lookup failed for DKIM: #{e.message}")
    end
  end
end
