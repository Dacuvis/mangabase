module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    # Urutan rescue_from berpengaruh: Rails akan mengeksekusi dari bawah ke atas.
    # Tangkap StandardError paling atas agar exception yang lebih spesifik bisa di-handle duluan.
    rescue_from StandardError, with: :render_internal_server_error
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_bad_request
    rescue_from ActionController::ParameterMissing, with: :render_bad_request
    rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
    rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
  end

  private

  # Handler untuk Error 404 (Data tidak ditemukan)
  def render_not_found(exception)
    render json: {
      error: {
        code: "NOT_FOUND",
        message: exception.message
      }
    }, status: :not_found
  end

  # Handler untuk Error 422 (Gagal validasi model, misal: save! atau update!)
  def render_unprocessable_entity(exception)
    render json: {
      error: {
        code: "VALIDATION_ERROR",
        message: "Validation failed",
        details: exception.record.errors.full_messages
      }
    }, status: :unprocessable_entity
  end

  # Handler untuk Error 400 (Parameter request tidak sesuai / hilang)
  def render_bad_request(exception)
    render json: {
      error: {
        code: "BAD_REQUEST",
        message: exception.message
      }
    }, status: :bad_request
  end

  # Handler untuk Error 500 (Fatal / Unhandled Error)
  def render_internal_server_error(exception)
    # Catat error ke log server untuk keperluan debugging
    Rails.logger.error("#{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    render json: {
      error: {
        code: "INTERNAL_SERVER_ERROR",
        message: Rails.env.production? ? "Internal server error" : exception.message
      }
    }, status: :internal_server_error
  end
end
