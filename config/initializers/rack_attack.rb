class Rack::Attack
  # Throttle semua request ke 60 per menit per IP
  throttle("req/ip", limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Response saat limit terlampaui
  self.throttled_responder = lambda do |_req|
    [
      429,
      { "Content-Type" => "application/json" },
      [ { error: "Too Many Requests: limit 60 requests per minute" }.to_json ]
    ]
  end
end
