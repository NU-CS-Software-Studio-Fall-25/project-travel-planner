# config/initializers/rack_attack.rb
class Rack::Attack
  ### Configure Cache ###
  
  # Use Rails.cache for storing Rack::Attack data
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  
  ### Throttle Requests ###
  
  # Throttle all requests by IP (60 requests per minute)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end
  
  # Throttle login attempts by IP address
  throttle('logins/ip', limit: 5, period: 20.seconds) do |req|
    if req.path == '/login' && req.post?
      req.ip
    end
  end
  
  # Throttle signup attempts by IP address
  throttle('signups/ip', limit: 3, period: 5.minutes) do |req|
    if req.path == '/users' && req.post?
      req.ip
    end
  end
  
  # Throttle travel recommendation generation (prevent abuse of AI API)
  throttle('recommendations/ip', limit: 10, period: 1.hour) do |req|
    if req.path == '/travel_recommendations' && req.post?
      req.ip
    end
  end
  
  # Throttle content reporting to prevent spam
  throttle('reports/ip', limit: 10, period: 1.hour) do |req|
    if req.path.include?('content_reports') && req.post?
      req.ip
    end
  end
  
  ### Block Suspicious Requests ###
  
  # Block requests from specific IPs if needed
  # blocklist('block suspicious IPs') do |req|
  #   # Requests are blocked if the block returns truthy
  #   ['1.2.3.4', '5.6.7.8'].include?(req.ip)
  # end
  
  # Block requests with suspicious user agents
  blocklist('block bots') do |req|
    # Block if user agent includes common bot signatures
    req.user_agent.present? && 
    req.user_agent.match(/scrapy|curl|wget|python-requests|bot/i)
  end
  
  ### Custom Response ###
  
  # Customize the response when a request is throttled
  self.throttled_responder = lambda do |env|
    retry_after = env['rack.attack.match_data'][:period]
    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => retry_after.to_s
      },
      [{ error: 'Rate limit exceeded. Please try again later.' }.to_json]
    ]
  end
  
  # Customize the response when a request is blocked
  self.blocklisted_responder = lambda do |env|
    [
      403,
      { 'Content-Type' => 'application/json' },
      [{ error: 'Your request has been blocked.' }.to_json]
    ]
  end
end
