require 'yaml'
require_relative 'utils/localizer'
require_relative 'rdoc_parser'

module SchemaRD
  module Metadata
    def self.load(config:, lang:, schema:)
      metadata = Parser.new(config.output_file, *config.metadata_files).parse()
      localizer = SchemaRD::Utils::SchemaLocalizer.new(lang, metadata)
      # localized_name を設定
      schema.tables.each do |table|
        table.localized_name = localizer.table_name(table.name)
        table.columns.each do |column|
          column.localized_name = localizer.column_name(table.name, column.name)
        end
      end
      # set position, and relations
      (metadata["tables"] || {}).each do |table_name, hash|
        # skip when table name exists in metadata only.
        next unless schema.table(table_name)
        if hash["position_left"] && hash["position_top"]
          schema.table(table_name).position =
            { "left" => hash["position_left"], "top" => hash["position_top"] }
        end
        self.add_relations(table_name, "belongs_to", hash["belongs_to"], schema)
        self.add_relations(table_name, "has_many",   hash["has_many"], schema)
        self.add_relations(table_name, "has_one",    hash["has_one"], schema)
      end
      # db_comment にメタ情報が含まれる場合に設定
      if config.parse_db_comment?
        schema.tables.each do |table|
          if table.parsed_db_comment && table.parsed_db_comment.strip != ""
            case config.parse_db_comment_as
            when 'name', 'localized_name'
              table.localized_name = table.parsed_db_comment.strip
            when 'description'
              table.description = table.parsed_db_comment.strip
            when 'custom'
              config.db_comment_parser.call(table: table)
            end
          end
          table.columns
          .select{|c| c.parsed_db_comment && c.parsed_db_comment.strip != ""}.each do |column|
            case config.parse_db_comment_as
            when 'name', 'localized_name'
              column.localized_name = column.parsed_db_comment.strip
            when 'description'
              column.description = column.parsed_db_comment.strip
            when 'custom'
              config.db_comment_parser.call(column: column)
            end
          end
        end
      end
      # RDocコメントとしてメタ情報が含まれる場合に設定
      if config.rdoc_enabled
        rdoc = SchemaRD::RDocParser.new(config.input_file)
        schema.tables.select{|t| rdoc.table_comment(t.name) }.each do |table|
          parser = DefaultTableCommentParser.new(rdoc.table_comment(table.name))
          table.localized_name = parser.localized_name if parser.has_localized_name?
          table.description = parser.description if parser.has_description?

          %i(belongs_to has_many has_one).each do |rel_type|
            if parser.has_relation_of?(rel_type)
              self.add_relations(table.name, rel_type.to_s, parser.relation_of(rel_type), schema)
            end
          end
        end
      end
      # output_file がなければ作成
      Writer.new(config.output_file).save_all(schema.tables) unless File.exist?(config.output_file)
      schema
    end

    def self.add_relations(table_name, type, relation_table_names, schema)
      return unless relation_table_names
      relation_table_names = relation_table_names.split(",") if relation_table_names.is_a?(String)

      relation_table_names.map{|rel_table_name| schema.table(rel_table_name) }.compact.each do |rel_table|
        parent_table = type == "belongs_to" ? rel_table : schema.table(table_name)
        child_table = type == "belongs_to" ? schema.table(table_name) : rel_table

        if parent_table.relation_to(child_table.name).nil?
          schema.add_relation(TableRelation.new(parent_table: parent_table, child_table: child_table))
        end
        parent_table.relation_to(child_table.name).child_cardinality = "1" if type == "has_one"
      end
    end

    # Writer for metadata yaml
    class Writer
      def initialize(output_file)
        @output_file = output_file
      end
      def save_all(tables)
        hash = tables.each_with_object({}) do |t, hash|
          hash[t.name] = { "position_top" => t.position["top"], "position_left" => t.position["left"] }
        end
        File.write(@output_file, YAML.dump({ "tables" => hash }))
      end
      def save(table_name, position)
        hash = YAML.load_file(@output_file) || {}
        hash["tables"] = {} unless hash.has_key?("tables")
        hash["tables"] = {} unless hash["tables"].is_a?(Hash)
        hash["tables"][table_name] = {} unless hash["tables"][table_name]
        hash["tables"][table_name] = {} unless hash["tables"][table_name].is_a?(Hash)
        hash["tables"][table_name]["position_top"] = position["top"].to_s
        hash["tables"][table_name]["position_left"] = position["left"].to_s
        File.write(@output_file, YAML.dump(hash))
      end
    end

    # parser for metadata yaml
    class Parser
      def initialize(output_file, *metadata_files)
        @parsed = {}
        metadata_files.select{|metadata_file| File.exist?(metadata_file) }.each do |metadata_file|
          self.class.deep_merge(@parsed, YAML.load_file(metadata_file))
        end
        self.class.deep_merge(@parsed, YAML.load_file(output_file)) if File.exist?(output_file)
      end
      # get hash of metadata
      def parse
        @parsed
      end
      def self.deep_merge(source, other)
        other.each do |k,v|
          next self.deep_merge(source[k], other[k]) if other[k].is_a?(Hash) && source[k].is_a?(Hash)
          source[k] = other[k]
        end
      end
    end # end of Parser
  end # end of Metadata
end
