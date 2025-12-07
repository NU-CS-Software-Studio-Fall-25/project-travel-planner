# app/controllers/application_controller.rb
require "ostruct"

class ApplicationController < ActionController::Base
  # If the real Pagy backend is available, include it. Otherwise we'll
  # provide a small, safe fallback `pagy` implementation below.
  include Pagy::Backend if defined?(Pagy::Backend)

  allow_browser versions: :modern

  before_action :current_user

  # Provide a small pagy_array fallback for array pagination when Pagy isn't available.
  def pagy_array(array, **vars)
    page  = (params[:page] || 1).to_i
    items = vars[:items] || (defined?(Pagy::VARS) ? Pagy::VARS[:items] : 20)
    total = Array(array).size
    offset = (page - 1) * items
    pages = items > 0 ? (total.to_f / items).ceil : 1

    pagy_obj = Struct.new(:count, :page, :items, :pages).new(total, page, items, pages)
    page_collection = Array(array)[offset, items] || []

    [ pagy_obj, page_collection ]
  end

  # Fallback minimal pagy method when Pagy::Backend isn't available.
  # It returns [pagy_object, collection_page].
  unless defined?(Pagy::Backend)
    # A tiny pagy-like object used by views/controllers that expect a Pagy instance.
    PagyFallback = Struct.new(:count, :page, :items, :pages) do
      def vars; { items: items }; end
    end

    private

    def pagy(collection, **vars)
      page = (params[:page] || 1).to_i
      items = vars[:items] || (defined?(Pagy::VARS) ? Pagy::VARS[:items] : 20)
      total = collection.respond_to?(:count) ? collection.count : Array(collection).size
      offset = (page - 1) * items
      pages = items > 0 ? (total.to_f / items).ceil : 1
      pagy_obj = PagyFallback.new(total, page, items, pages)

      page_collection =
        if collection.respond_to?(:limit) && collection.respond_to?(:offset)
          collection.limit(items).offset(offset)
        else
          Array(collection)[offset, items] || []
        end

      [ pagy_obj, page_collection ]
    end
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def require_login
    unless logged_in?
      flash[:alert] = "Please log in to access this page"
      redirect_to login_path
    end
  end

  def render_not_found
    render template: "errors/not_found", status: :not_found
  end

  def render_internal_server_error
    render template: "errors/internal_server_error", status: :internal_server_error
  end

  helper_method :current_user, :logged_in?
end
