module ApiKeyAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_api_key!
    api_key = request.headers["X-API-KEY"]
    expected_key = ENV["API_KEY"]

    # ...
    is_valid = expected_key.present? &&
               api_key.present? &&
               ActiveSupport::SecurityUtils.secure_compare(api_key, expected_key)

    unless is_valid
      render json: { error: "Unauthorized: Invalid or missing API Key" }, status: :unauthorized
    end
  end
end
