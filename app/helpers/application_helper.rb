# app/helpers/application_helper.rb
module ApplicationHelper
  # Prefer the official Pagy frontend helpers if available:
  if defined?(Pagy::Frontend)
    include Pagy::Frontend
  else
    # Minimal pagy_nav fallback that renders Previous / Next links.
    # This keeps views from crashing when Pagy frontend isn't available.
    def pagy_nav(pagy, id = nil, pagy_nav_partial: nil)
      current = (params[:page] || pagy&.page || 1).to_i
      prev_link = nil
      next_link = nil

      if current > 1
        prev_params = request.query_parameters.merge('page' => current - 1)
        prev_link = link_to('Previous', url_for(params.permit!.to_h.merge(prev_params)))
      end

      if pagy && pagy.pages && current < pagy.pages
        next_params = request.query_parameters.merge('page' => current + 1)
        next_link = link_to('Next', url_for(params.permit!.to_h.merge(next_params)))
      end

      content_tag(:nav, class: 'pagy-nav') do
        safe_join([prev_link, next_link].compact, ' ')
      end
    end

    # Minimal pagy_bootstrap_nav fallback used when Pagy::Frontend (bootstrap extra)
    # isn't available. It renders simple Bootstrap-style Prev / Next links and
    # preserves other query params.
    def pagy_bootstrap_nav(pagy)
      return ''.html_safe unless pagy && pagy.respond_to?(:pages) && (pagy.pages || 1).to_i > 1

      page = (params[:page] || pagy.page || 1).to_i
      pages = (pagy.pages || 1).to_i

      prev_link = if page > 1
        link_to('&laquo;'.html_safe, url_for(params.permit!.to_h.merge('page' => page - 1)), class: 'page-link')
      else
        content_tag(:span, '&laquo;'.html_safe, class: 'page-link disabled')
      end

      next_link = if page < pages
        link_to('&raquo;'.html_safe, url_for(params.permit!.to_h.merge('page' => page + 1)), class: 'page-link')
      else
        content_tag(:span, '&raquo;'.html_safe, class: 'page-link disabled')
      end

      content_tag(:nav, aria: { label: 'Pagination' }) do
        content_tag(:ul, class: 'pagination') do
          content_tag(:li, prev_link, class: 'page-item') +
            content_tag(:li, next_link, class: 'page-item')
        end
      end
    end
  end
end