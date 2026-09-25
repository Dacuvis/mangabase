module ApiKeyAuthenticatable
  extend ActiveSupport::Concern

  private

  # Kembalikan role berdasarkan API key yang dikirim di header X-API-KEY.
  # Mengembalikan :admin, :user, atau nil jika key tidak valid.
  def resolve_api_key_role
    api_key = request.headers["X-API-KEY"]
    return nil if api_key.blank?

    admin_key = ENV["API_KEY_ADMIN"]
    user_key  = ENV["API_KEY_USER"]

    if admin_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, admin_key)
      :admin
    elsif user_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, user_key)
      :user
    end
  end

  # Simpan role di instance variable supaya tidak dihitung ulang.
  def current_api_role
    @current_api_role ||= resolve_api_key_role
  end

  # Untuk endpoint yang butuh admin (create/update/destroy resource global
  # seperti mangas, genres, users, dll).
  def authenticate_admin!
    return if current_api_role == :admin

    render json: { error: "Forbidden: Admin API key required" }, status: :forbidden
  end

  # Untuk endpoint yang boleh diakses admin ATAU user biasa
  # (dipakai di reading_lists create/update/destroy).
  def authenticate_any_key!
    return if current_api_role.present?

    render json: { error: "Unauthorized: Invalid or missing API key" }, status: :unauthorized
  end

  # Kembalikan user_id yang terautentikasi untuk role :user.
  # Diambil dari header X-USER-ID dan divalidasi keberadaannya.
  # Admin tidak butuh ini karena bisa operasi atas nama siapapun.
  def authenticated_user_id
    return nil unless current_api_role == :user

    uid = request.headers["X-USER-ID"]
    if uid.blank?
      render json: { error: "Unauthorized: X-USER-ID header required for user role" }, status: :unauthorized
      return nil
    end

    uid.to_i
  end
end
