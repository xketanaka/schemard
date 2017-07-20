require 'yaml'
require_relative 'utils/localizer'

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

      # position, relation を設定
      (metadata["tables"] || {}).each do |table_name, hash|
        if hash["position_left"] && hash["position_top"]
          schema.table(table_name).position =
            { "left" => hash["position_left"], "top" => hash["position_top"] }
        end
        self.add_relations(table_name, "belongs_to", hash["belongs_to"], schema)
        self.add_relations(table_name, "has_many",   hash["has_many"], schema)
        self.add_relations(table_name, "has_one",    hash["has_one"], schema)
      end
      # output_file がなければ作成
      Writer.new(config.output_file).save_all(schema.tables) unless File.exist?(config.output_file)
      schema
    end

    def self.add_relations(table_name, type, relation_table_names, schema)
      return unless relation_table_names
      relation_table_names = relation_table_names.split(",") if relation_table_names.is_a?(String)

      relation_table_names.each do |rel_table_name|
        parent_table = type == "belongs_to" ? schema.table(rel_table_name) : schema.table(table_name)
        child_table = type == "belongs_to" ? schema.table(table_name) : schema.table(rel_table_name)

        if parent_table.relation_to(child_table.name).nil?
          relation = TableRelation.new(parent_table: parent_table, child_table: child_table)
          parent_table.relations << relation
        end
        parent_table.relation_to(child_table.name).child_cardinality = "1" if type == "has_one"
      end
    end

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

    class Parser
      def initialize(output_file, *metadata_files)
        @parsed = {}
        metadata_files.select{|metadata_file| File.exist?(metadata_file) }.each do |metadata_file|
          self.class.deep_merge(@parsed, YAML.load_file(metadata_file))
        end
        self.class.deep_merge(@parsed, YAML.load_file(output_file)) if File.exist?(output_file)
      end
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
