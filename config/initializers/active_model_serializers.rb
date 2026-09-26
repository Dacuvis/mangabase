# frozen_string_literal: true

# Sertakan asosiasi (seperti has_many :genres pada MangaSerializer) secara default
ActiveModelSerializers.config.default_includes = "**"
