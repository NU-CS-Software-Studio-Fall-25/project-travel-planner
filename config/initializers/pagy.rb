# config/initializers/pagy.rb

begin
  require 'pagy'
rescue LoadError
  # Pagy not installed — skip the initializer so Rails can still boot
  Rails.logger.warn "Pagy not available — skipping Pagy initializer"
else
  # Explicitly require backend/frontend so the constants exist for inclusion below.
  # Some Pagy versions split backend/frontend into separate files.
  begin
    require 'pagy/backend'
  rescue LoadError
    Rails.logger.warn "pagy/backend not available in initializer"
  end

  begin
    require 'pagy/frontend'
  rescue LoadError
    Rails.logger.warn "pagy/frontend not available in initializer"
  end
  begin
    require 'pagy/extras/array'
  rescue LoadError
    Rails.logger.warn "pagy/extras/array not available in initializer"
  end
  begin
    # Pagy extras that add view helpers like pagy_bootstrap_nav
    require 'pagy/extras/bootstrap_nav'   # primary name
  rescue LoadError
    # Some installations use a slightly different name; try the other path
    begin
      require 'pagy/extras/bootstrap'
    rescue LoadError
      Rails.logger.warn "pagy bootstrap extra not available: tried pagy/extras/bootstrap_nav and pagy/extras/bootstrap"
    end
  end

  # Ensure Pagy::VARS exists (compatibility across Pagy versions)
  unless defined?(Pagy::VARS)
    if defined?(Pagy::DEFAULT)
      Pagy.const_set(:VARS, Pagy::DEFAULT.dup)
    else
      Pagy.const_set(:VARS, {})
    end
  end

  # Safe default items per page
  Pagy::VARS[:items] = 20

  # Try to load bootstrap extra (optional)
  extras_loaded = false
  %w[pagy/extras/bootstrap pagy/extras/bootstrap_nav].each do |path|
    begin
      require path
      extras_loaded = true
      break
    rescue LoadError
      next
    end
  end

  Rails.logger.warn "Pagy bootstrap extra not available: tried pagy/extras/bootstrap and pagy/extras/bootstrap_nav" unless extras_loaded
  Pagy::VARS[:nav] = 'bootstrap' if extras_loaded

  # Include Pagy modules into controllers & views after those subsystems load
  # This prevents NameError when controllers are loaded before Pagy is required
  if defined?(ActiveSupport)
    ActiveSupport.on_load(:action_controller) do
      include Pagy::Backend if defined?(Pagy::Backend)
    end

    ActiveSupport.on_load(:action_view) do
      include Pagy::Frontend if defined?(Pagy::Frontend)
    end
  end

  # If ApplicationController or ActionView were already loaded before this initializer,
  # include the modules immediately so methods are available in the current process.
  if defined?(ApplicationController) && defined?(Pagy::Backend)
    ApplicationController.include Pagy::Backend
    Rails.logger.info "Included Pagy::Backend into ApplicationController (initializer)"
  end

  if defined?(ActionView::Base) && defined?(Pagy::Frontend)
    ActionView::Base.include Pagy::Frontend
    Rails.logger.info "Included Pagy::Frontend into ActionView::Base (initializer)"
  end
end