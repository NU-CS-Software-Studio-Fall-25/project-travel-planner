# config/initializers/session_store.rb
#
# Configure the session store to use the cache store (backed by Solid Cache)
# instead of the default cookie store. This prevents cookie overflow errors
# when storing large objects in the session, such as AI-generated
# travel recommendations.

Rails.application.config.session_store :cache_store, key: '_project_travel_planner_session'