require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ProjectTravelPlanner
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # CORS configuration for frontend integration
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "localhost:3000", "localhost:3001", "localhost:8080", "127.0.0.1:3000", "127.0.0.1:3001", "127.0.0.1:8080"
        resource "*",
          headers: :any,
          methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
          credentials: true
      end
    end

    # Enable Rack::Attack for rate limiting and abuse prevention
    config.middleware.use Rack::Attack
  end
end
