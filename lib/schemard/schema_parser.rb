require_relative "schema"

module SchemaRD
  module MigrationContext
    class Loader
      class TableDefinition
        [
          :bigint,
          :binary,
          :boolean,
          :date,
          :datetime,
          :decimal,
          :float,
          :integer,
          :string,
          :text,
          :time,
          :timestamp,
          :virtual,
        ].each do |column_type|
          module_eval <<-CODE, __FILE__, __LINE__ + 1
            def #{column_type}(*args, **options)
              args.each { |name| column(name, :#{column_type}, options) }
            end
          CODE
        end
        alias_method :numeric, :decimal
        def initialize(table, with_comment:)
          @table = table
          @parse_db_comment = with_comment
        end
        def method_missing(name, *args)
          self.column(args[0], "unknown", args[1])
        end
        def column(name, type, options = {})
          if options[:comment] && @parse_db_comment
            options[:parsed_db_comment] = options.delete(:comment)
          end
          @table.columns << SchemaRD::TableColumn.new(options.merge({ name: name, type: type }))
        end
        def timestamps
          column("created_at", :timestamp, null: false)
          column("updated_at", :timestamp, null: false)
        end
        def index(column_name, options = {})
          column_name = [ column_name ] unless column_name.is_a?(Array)
          @table.indexes << SchemaRD::TableIndex.new(options.merge({ columns: column_name }))
        end
      end
      def initialize(schema, with_comment:)
        @schema = schema
        @parse_db_comment = with_comment
      end
      def create_table(table_name, options = {})
        if options[:comment] && @parse_db_comment
          options[:parsed_db_comment] = options.delete(:comment)
        end
        table = SchemaRD::Table.new(options.merge(name: table_name))
        @schema.add_table(table_name, table)
        yield TableDefinition.new(table, with_comment: @parse_db_comment)
      end
      def add_index(table_name, column_name, options = {})
        column_name = [ column_name ] unless column_name.is_a?(Array)
        index = SchemaRD::TableIndex.new(options.merge({ columns: column_name }))
        @schema.table(table_name).indexes << index
      end
      def enable_extension(*args); end

      module ActiveRecord
        class Schema
          def self.define(*args)
            yield
          end
        end
      end
    end
  end

  class SchemaParser
    def initialize(filename)
      @filename = filename
    end
    def parse(with_comment: false)
      Schema.new.tap do |schema|
        File.open(@filename) do |file|
          MigrationContext::Loader.new(schema, with_comment: with_comment).instance_eval(file.read, @filename)
        end
      end
    end
  end
end
