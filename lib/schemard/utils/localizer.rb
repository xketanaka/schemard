require 'yaml'
require_relative 'singularizer'

module SchemaRD::Utils
  class Localizer
    def initialize(primary_lang)
      @primary_lang = primary_lang
    end
    def lang
      @lang ||= self.dictionary && self.dictionary.has_key?(@primary_lang) ? @primary_lang : "en"
    end
    def translate(key)
      key.split(".").inject(self.dictionary[lang]) do |dict, k|
        break if dict.nil? || !dict.is_a?(Hash)
        dict[k]
      end
    end
    alias_method :t, :translate
  end

  class MessageLocalizer < Localizer
    MESSAGES_FILE = "#{File.dirname(File.expand_path(__FILE__))}/../../locales/messages.yml"

    def initialize(lang)
      super(lang)
    end
    def dictionary
      YAML.load_file(MESSAGES_FILE)
    end
  end

  class SchemaLocalizer < Localizer
    def initialize(lang, hash)
      super(lang)
      @hash = hash
    end
    def dictionary
      @hash
    end
    def table_name(name)
      self.t("activerecord.models.#{name.singularize}")
    end
    def column_name(table_name, column_name)
      self.t("activerecord.attributes.#{table_name.singularize}.#{column_name}")
    end
  end
end
