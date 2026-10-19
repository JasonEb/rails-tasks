module AuthHelpers
  def auth_headers(user)
    { "Authorization" => "Bearer #{user.auth_token}" }
  end

  def json
    response.parsed_body
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
