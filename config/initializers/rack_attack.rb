MAX_REQUEST_COUNT = 60
MAX_REQUEST_WINDOW = 1

class Rack::Attack
  throttle("prices/ip", limit: MAX_REQUEST_COUNT, period: MAX_REQUEST_WINDOW.minute) do |req|
    req.ip if req.path.start_with?("/prices")
  end

  self.throttled_responder = lambda do |request|
    [
      429,
      {
        "Content-Type" => "application/json"
      },
      [
        {
          message: "You have exceeded your maximum limit. Please try after sometime."
        }.to_json
      ]
    ]
  end
end
