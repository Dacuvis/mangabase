class BestManga < ApplicationRecord
  belongs_to :manga

  validates :rank, precense: true,
                  numericality: { only_integer: true, in: 1..10},
                  uniqueness: { message: "sudah terisi manga lain"}

  validates :manga_id, uniqueness: { message: "sudah ada dalam daftar Best Manga"}
  
  valdiates :max_ten_entries, on: :create

  private

  def max_ten_entries
    if BestManga.count >= 10
      errors.add(:base, "Daftar Best Manga sudah penuh")
    end
  end
end
