# config/initializers/pagy.rb
# Compatibility shim for Pagy toolbox-style layout (pagy v40+/v43).
# It requires the toolbox loader and provides lightweight Backend/Frontend
# fallbacks if the gem does not define them, so controllers/views can call
# pagy, pagy_array and pagy_bootstrap_nav.

begin
  require 'pagy'
rescue LoadError
  Rails.logger.warn "Pagy gem not available - skipping Pagy initializer"
else
  pagy_spec = Gem.loaded_specs['pagy']
  pagy_gem_path = pagy_spec&.full_gem_path

  if pagy_gem_path
    # require the toolbox loader (defines Pagy::Loader for helper fragments)
    loader = File.join(pagy_gem_path, 'lib', 'pagy', 'toolbox', 'helpers', 'loader.rb')
    require loader if File.exist?(loader)

    # require some bootstrap helper fragments if present (used by pagy_bootstrap_nav)
    %w[
      bootstrap/previous_next_html
      bootstrap/series_nav
      bootstrap/input_nav_js
    ].each do |frag|
      path = File.join(pagy_gem_path, 'lib', 'pagy', 'toolbox', 'helpers', "#{frag}.rb")
      require path if File.exist?(path)
    end
  end

  # Ensure Pagy::VARS exists and set a sensible default
  unless defined?(Pagy::VARS)
    if defined?(Pagy::DEFAULT)
      Pagy.const_set(:VARS, Pagy::DEFAULT.dup)
    else
      Pagy.const_set(:VARS, {})
    end
  end
  Pagy::VARS[:items] ||= 20

  # If the gem provides Backend/Frontend, include them; otherwise define small compatibility shims.

  unless defined?(Pagy::Backend)
    class Pagy
      module Backend
        # Simple pagy_array: returns [pagy_obj, slice]
        def pagy_array(array, **vars)
          items = (vars[:items] || Pagy::VARS[:items] || 20).to_i
          page  = (params[:page] || 1).to_i
          total = array.respond_to?(:size) ? array.size : array.to_a.size
          pages = (total.to_f / items).ceil
          from  = (page - 1) * items
          to    = from + items - 1
          page_slice = array.to_a[from..to] || []

          pagy = OpenStruct.new(
            page: page,
            items: items,
            count: total,
            pages: pages,
            from: from,
            to: to
          )
          [pagy, page_slice]
        end

        # Simple pagy for ActiveRecord-like relations or arrays
        def pagy(collection, **vars)
          # If it looks like an ActiveRecord relation, perform limit/offset.
          if collection.respond_to?(:limit) && collection.respond_to?(:offset)
            items = (vars[:items] || Pagy::VARS[:items] || 20).to_i
            page  = (params[:page] || 1).to_i
            offset_val = (page - 1) * items
            # Use count when available; fallback to converting to array if count raises
            total = begin
              collection.count
            rescue StandardError
              Array(collection).size
            end
            records = collection.limit(items).offset(offset_val).to_a
            pages = (total.to_f / items).ceil

            pagy = OpenStruct.new(
              page: page,
              items: items,
              count: total,
              pages: pages,
              from: offset_val,
              to: offset_val + records.size - 1
            )
            [pagy, records]
          else
            # fallback to array pagination
            pagy_array(collection, **vars)
          end
        end
      end
    end
  end

  unless defined?(Pagy::Frontend)
    class Pagy
      module Frontend
        include ActionView::Helpers::UrlHelper if defined?(ActionView::Helpers::UrlHelper)

        # Minimal pagy_nav (Prev / Next)
        def pagy_nav(pagy)
          return '' unless pagy && pagy.pages.to_i > 1
          prev_link = (pagy.page > 1) ? link_to('Prev', url_for(page: pagy.page - 1)) : nil
          next_link = (pagy.page < pagy.pages) ? link_to('Next', url_for(page: pagy.page + 1)) : nil
          content = []
          content << prev_link if prev_link
          content << next_link if next_link
          content.join(' ').html_safe
        end

        # Minimal Bootstrap-compatible nav
        def pagy_bootstrap_nav(pagy)
          return '' unless pagy && pagy.pages.to_i > 1
          prev_disabled = (pagy.page <= 1)
          next_disabled = (pagy.page >= pagy.pages)

          prev_li = if prev_disabled
                      "<li class=\"page-item disabled\"><a class=\"page-link\">Previous</a></li>"
                    else
                      "<li class=\"page-item\"><a class=\"page-link\" href=\"#{url_for(page: pagy.page - 1)}\">Previous</a></li>"
                    end

          next_li = if next_disabled
                      "<li class=\"page-item disabled\"><a class=\"page-link\">Next</a></li>"
                    else
                      "<li class=\"page-item\"><a class=\"page-link\" href=\"#{url_for(page: pagy.page + 1)}\">Next</a></li>"
                    end

          "<nav aria-label=\"pagination\"><ul class=\"pagination\">#{prev_li}#{next_li}</ul></nav>".html_safe
        end
      end
    end
  end

  # Include into controllers and views if not already included
  if defined?(ActiveSupport)
    ActiveSupport.on_load(:action_controller) do
      include Pagy::Backend if defined?(Pagy::Backend)
    end
    ActiveSupport.on_load(:action_view) do
      include Pagy::Frontend if defined?(Pagy::Frontend)
    end
  end

  # If app already loaded, include immediately
  ApplicationController.include Pagy::Backend if defined?(ApplicationController) && defined?(Pagy::Backend)
  ActionView::Base.include Pagy::Frontend if defined?(ActionView::Base) && defined?(Pagy::Frontend)
end