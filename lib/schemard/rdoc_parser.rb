require 'rdoc'
module SchemaRD
  class RDocParser
    def initialize(filename)
      parse(filename)
    end

    def table_comment(name)
      method_obj = @clazz.find_method_named(name)
      method_obj ? method_obj.comment.text : ""
    end

    private

    def parse(filename)
      file_content = File.read(filename)
      content = "module Schemafile\n#{file_content}\nend"

      rdoc = RDoc::RDoc.new
      store = RDoc::Store.new
      options = rdoc.load_options
      stats = RDoc::Stats.new(store, 1, options.verbosity)
      top_level = store.add_file(filename)
      RDoc::Parser::Ruby.new(top_level, filename, content, options, stats).scan
      @clazz = top_level.find_module_named("Schemafile")
    end
  end

  class DefaultTableCommentParser
    def initialize(comment_text)
      @hash = { relations: {} }
      @hash[:description] = comment_text.split("\n").map(&:strip).map{|line|
        if line =~ /^name\:\:/ || line =~ /^localized_name\:\:/
          @hash[:localized_name] = line.match(/^[^:]*name\:\:(.+)$/)[1].strip
          next
        end
        %w(belongs_to has_many has_one).each do |rel_type|
          if line =~ /^#{rel_type}\:\:/
            tables = line.match(/^#{rel_type}\:\:(.+)$/)[1].split(",").map(&:strip).select{|s| s != "" }
            @hash[:relations][rel_type.to_sym] = tables unless tables.empty?
            line = nil # skip this line (by compact)
          end
        end
        line
      }.compact.join("\n")
    end
    def has_localized_name?
      @hash[:localized_name] && @hash[:localized_name] != ""
    end
    def localized_name
      @hash[:localized_name]
    end
    def has_description?
      !!@hash[:description]
    end
    def description
      @hash[:description]
    end
    def has_relation_of?(rel_type)
      !!@hash[:relations][rel_type]
    end
    def relation_of(rel_type)
      @hash[:relations][rel_type]
    end
  end
end
