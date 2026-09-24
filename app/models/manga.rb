class Manga < ApplicationRecord
  # 1. Title: Wajib diisi & maksimal 255 karakter
  validates :title, presence: { message: "wajib diisi" },
                    length: { maximum: 255 }

  # 2. Author: Maksimal 255 karakter (otomatis mengizinkan nilai kosong/nil jika tidak ada 'presence: true')
  validates :author, length: { maximum: 255 }, allow_nil: true

  # 3. Chapet Count: Harus berupa angka integer >= 0 jika diisi
  validates :chapet_count, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }, allow_nil: true

  # 4. Is Completed: Harus boolean jika diisi
  validates :is_completed, inclusion: { in: [ true, false ] }, allow_nil: true

  # Catatan: Kolom 'synopsis' tidak perlu baris 'validates' karena bersifat bebas/opsional.
end
