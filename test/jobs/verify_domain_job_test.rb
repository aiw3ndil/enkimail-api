require "test_helper"
require "dnsruby"
require "minitest/mock"
require "ostruct"

class VerifyDomainJobTest < ActiveJob::TestCase
  setup do
    @user = users(:one)
    @user.update!(role: :pro) # Ensure user has a role for capitalization and limit check
    @domain_name = "example-#{SecureRandom.hex(4)}.com"
    @fake_dkim_key = "MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA0t6pX7v1...FAKE_KEY...wIDAQAB"
    @domain = Domain.create!(
      name: @domain_name,
      user: @user,
      dkim_selector: "enki",
      dkim_private_key: "fake_private_key",
      dkim_public_key: @fake_dkim_key
    )
  end

  test "verifies DKIM even if split into multiple strings" do
    # Mock DNS resolver
    mock_resolver = Minitest::Mock.new
    
    # Mock for verify_ownership
    ownership_answer = [
      OpenStruct.new(rdata: OpenStruct.new(to_s: "enkimail-verification=#{@domain.verification_token}"))
    ]
    mock_resolver.expect :query, OpenStruct.new(answer: ownership_answer), [@domain_name, Dnsruby::Types::TXT]
    
    # Mock for verify_spf
    spf_answer = [
      OpenStruct.new(rdata: OpenStruct.new(to_s: "v=spf1 ip4:54.37.230.86 include:mx.ovh.com -all"))
    ]
    mock_resolver.expect :query, OpenStruct.new(answer: spf_answer), [@domain_name, Dnsruby::Types::TXT]

    # Mock for verify_dkim - simulating split DKIM record
    dkim_parts = [
      "v=DKIM1; k=rsa; p=#{@fake_dkim_key[0..100]}",
      @fake_dkim_key[101..-1]
    ]
    
    # In Dnsruby, a TXT record has a 'strings' method returning the parts
    dkim_record = OpenStruct.new(strings: dkim_parts)
    # Current implementation uses dkim_record.rdata.to_s
    dkim_record.rdata = OpenStruct.new(to_s: dkim_parts.map { |s| "\"#{s}\"" }.join(" "))
    
    dkim_answer = [dkim_record]
    mock_resolver.expect :query, OpenStruct.new(answer: dkim_answer), ["enki._domainkey.#{@domain_name}", Dnsruby::Types::TXT]

    Dnsruby::Resolver.stub :new, mock_resolver do
      VerifyDomainJob.perform_now(@domain.id)
    end

    @domain.reload
    assert @domain.verified?, "Domain should be verified. Error: #{@domain.verification_error}"
  end
end
