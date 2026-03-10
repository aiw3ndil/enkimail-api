namespace :enkimail do
  desc "Export all verified domain DKIM keys and regenerate OpenDKIM config files"
  task export_dkim_keys: :environment do
    # First export each domain's private key
    Domain.verified.find_each do |domain|
      base_dir = ENV['OPENDKIM_DATA_PATH'] || Rails.root.join("config", "opendkim")
      keys_directory = Pathname.new(base_dir).join("keys", domain.name)
      FileUtils.mkdir_p(keys_directory)
      key_file = keys_directory.join("#{domain.dkim_selector}.private")
      File.write(key_file, domain.dkim_private_key)
      File.chmod(0640, key_file)
      puts "Exported key for #{domain.name} (selector: #{domain.dkim_selector})"
    end

    # Then regenerate all shared config files from scratch (clean, no duplicates)
    Domain.regenerate_opendkim_config
    puts "Regenerated OpenDKIM config files (KeyTable, SigningTable, TrustedHosts, opendkim.conf)"
  end
end
