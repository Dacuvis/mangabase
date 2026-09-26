module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100

  private

  # Hitung current page dari params, minimal 1
  def current_page
    [ params.fetch(:page, 1).to_i, 1 ].max
  end

  # Hitung per_page dari params, clamp antara 1 dan MAX_PER_PAGE
  def per_page
    [ [ params.fetch(:per_page, DEFAULT_PER_PAGE).to_i, 1 ].max, MAX_PER_PAGE ].min
  end

  # Terapkan pagination ke sebuah relation dan render JSON dengan metadata.
  # Serializer dipilih otomatis oleh ActiveModel::Serializer berdasarkan tipe record.
  def render_paginated(relation, **options)
    total_count = relation.count
    total_pages = (total_count.to_f / per_page).ceil

    records = relation
                .limit(per_page)
                .offset((current_page - 1) * per_page)

    render_options = {
      meta: {
        current_page: current_page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }.merge(options)

    render json: records, **render_options
  end
end
