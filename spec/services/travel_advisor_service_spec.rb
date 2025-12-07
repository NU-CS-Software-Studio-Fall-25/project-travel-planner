# spec/services/travel_advisor_service_spec.rb
require 'rails_helper'

RSpec.describe TravelAdvisorService do
  let(:api_key) { 'test_api_key' }
  let(:api_host) { 'travel-advisor.p.rapidapi.com' }
  let(:service) { described_class.new(key: api_key, host: api_host) }

  describe '#initialize' do
    it 'sets the API key' do
      expect(service.instance_variable_get(:@key)).to eq(api_key)
    end

    it 'sets the API host' do
      expect(service.instance_variable_get(:@host)).to eq(api_host)
    end

    it 'uses environment variables if not provided' do
      ENV['RAPIDAPI_KEY'] = 'env_key'
      ENV['RAPIDAPI_HOST'] = 'env_host'
      service = described_class.new
      expect(service.instance_variable_get(:@key)).to eq('env_key')
      expect(service.instance_variable_get(:@host)).to eq('env_host')
    end

    it 'sets correct headers' do
      headers = service.instance_variable_get(:@headers)
      expect(headers['X-RapidAPI-Key']).to eq(api_key)
      expect(headers['X-RapidAPI-Host']).to eq(api_host)
      expect(headers['Accept']).to eq('application/json')
    end
  end

  describe '#places_near' do
    let(:lat) { 48.8566 }
    let(:lng) { 2.3522 }

    context 'with valid coordinates' do
      it 'returns an array of places' do
        # Mock the HTTP response
        mock_response = {
          'data' => [
            {
              'location_id' => '123',
              'name' => 'Eiffel Tower',
              'rating' => '4.5'
            },
            {
              'location_id' => '456',
              'name' => 'Louvre Museum',
              'rating' => '4.8'
            }
          ]
        }

        stub_request(:get, "https://#{api_host}/attractions/list-by-lat-lng")
          .with(query: hash_including({ 'latitude' => lat.to_s, 'longitude' => lng.to_s }))
          .to_return(status: 200, body: mock_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = service.places_near(lat: lat, lng: lng)

        expect(result).to be_an(Array)
        expect(result.length).to be > 0
      end

      it 'uses caching for repeated requests' do
        cache_key = "ta:places:near:#{lat}:#{lng}:2000:8"

        expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: 12.hours).and_call_original

        stub_request(:get, "https://#{api_host}/attractions/list-by-lat-lng")
          .to_return(status: 200, body: { data: [] }.to_json)

        service.places_near(lat: lat, lng: lng)
      end

      it 'respects radius and limit parameters' do
        radius = 5000
        limit = 10

        stub_request(:get, "https://#{api_host}/attractions/list-by-lat-lng")
          .with(query: hash_including({ 'latitude' => lat.to_s, 'longitude' => lng.to_s, 'limit' => limit.to_s }))
          .to_return(status: 200, body: { data: [] }.to_json)

        result = service.places_near(lat: lat, lng: lng, radius_m: radius, limit: limit)
        expect(result).to be_an(Array)
      end
    end

    context 'with missing parameters' do
      it 'returns empty array when lat is blank' do
        result = service.places_near(lat: nil, lng: lng)
        expect(result).to eq([])
      end

      it 'returns empty array when lng is blank' do
        result = service.places_near(lat: lat, lng: nil)
        expect(result).to eq([])
      end

      it 'returns empty array when API key is blank' do
        service_no_key = described_class.new(key: '', host: api_host)
        result = service_no_key.places_near(lat: lat, lng: lng)
        expect(result).to eq([])
      end
    end

    context 'when API request fails' do
      it 'returns empty array on HTTP error' do
        stub_request(:get, "https://#{api_host}/attractions/list-by-lat-lng")
          .to_return(status: 500, body: 'Internal Server Error')

        result = service.places_near(lat: lat, lng: lng)
        expect(result).to eq([])
      end

      it 'logs the error' do
        stub_request(:get, "https://#{api_host}/attractions/list-by-lat-lng")
          .to_return(status: 404, body: 'Not Found')

        expect(Rails.logger).to receive(:warn).with(/TravelAdvisor API error/)
        service.places_near(lat: lat, lng: lng)
      end

      it 'handles network exceptions gracefully' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new('Network error'))

        expect(Rails.logger).to receive(:error).with(/TravelAdvisorService error/)
        result = service.places_near(lat: lat, lng: lng)
        expect(result).to eq([])
      end
    end
  end

  describe '#parse_places (private method)' do
    it 'parses place data correctly' do
      json_data = {
        'data' => [
          {
            'location_id' => '789',
            'name' => 'Test Place',
            'rating' => '4.2'
          }
        ]
      }

      result = service.send(:parse_places, json_data)

      expect(result).to be_an(Array)
      expect(result.first[:id]).to eq('789')
      expect(result.first[:name]).to eq('Test Place')
      expect(result.first[:rating]).to eq('4.2')
    end

    it 'limits results to 50 items' do
      large_data = { 'data' => Array.new(100) { |i| { 'id' => i.to_s } } }

      result = service.send(:parse_places, large_data)
      expect(result.length).to be <= 50
    end

    it 'handles different response structures' do
      json_with_results = { 'results' => [ { 'id' => '1', 'name' => 'Place 1' } ] }
      result = service.send(:parse_places, json_with_results)
      expect(result).to be_an(Array)
    end
  end
end
