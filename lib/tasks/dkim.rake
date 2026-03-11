namespace :enkimail do
  desc "Export all verified domain DKIM keys and regenerate OpenDKIM config files"
  task export_dkim_keys: :environment do
    # First export each domain's private key
    Domain.verified.find_each do |domain|
      begin
        if domain.dkim_private_key.blank?
          puts "Error: Domain #{domain.name} is verified but missing dkim_private_key!"
          next
        end
        base_dir = ENV['OPENDKIM_DATA_PATH'] || Rails.root.join("config", "opendkim")
        keys_directory = Pathname.new(base_dir).join("keys", domain.name)
        FileUtils.mkdir_p(keys_directory)
        key_file = keys_directory.join("#{domain.dkim_selector}.private")
        File.write(key_file, domain.dkim_private_key)
        File.chmod(0644, key_file)
        puts "Exported key for #{domain.name} (selector: #{domain.dkim_selector})"
      rescue => e
        puts "Failed to export key for #{domain.name}: #{e.message}"
      end
    end

    # Then regenerate all shared config files from scratch (clean, no duplicates)
    begin
      Domain.regenerate_opendkim_config
      puts "Regenerated OpenDKIM config files (KeyTable, SigningTable, TrustedHosts, opendkim.conf)"
    rescue => e
      puts "Failed to regenerate OpenDKIM config files: #{e.message}"
    end
  end
end
