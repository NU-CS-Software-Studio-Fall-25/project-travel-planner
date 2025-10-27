# Load environment variables from config/local_env.yml for local development.
# This file is gitignored and intended for local secrets only.
local_env_path = Rails.root.join('config', 'local_env.yml')
if (Rails.env.development? || Rails.env.test?) && File.exist?(local_env_path)
  begin
    require 'yaml'
    YAML.load_file(local_env_path).each do |key, value|
      if value.is_a?(Hash)
        value.each do |subkey, subval|
          ENV["#{key.upcase}_#{subkey.upcase}"] ||= subval.to_s
        end
      else
        ENV[key.upcase] ||= value.to_s
      end
    end
  rescue => e
    Rails.logger.warn "Failed to load local_env.yml: "+ e.message
  end
end
