namespace :enkimail do
  desc "Export all verified domain DKIM keys to the MTA shared volume"
  task export_dkim_keys: :environment do
    count = 0
    Domain.verified.find_each do |domain|
      domain.export_dkim_key
      count += 1
      puts "Exported key for #{domain.name}"
    end
    puts "Finished: #{count} keys exported to config/opendkim/keys/"
  end
end
