require_relative 'utils/struct_assigner'

module SchemaRD
  class Schema
    def initialize
      @tables = {}
    end
    def tables
      @tables.values
    end
    def table(name)
      @tables[name.to_s]
    end
    def add_table(name, table_object)
      @tables[name.to_s] = table_object
    end
  end

  class Table < Struct.new(*%i(relations columns indexes name localized_name comment position))
    include SchemaRD::Utils::StructAssigner
    def initialize(hash = nil)
      self.relations = []
      self.columns = []
      self.indexes = []
      self.position = { "left" => 0, "top" => 0 }
      self.assign(hash)
    end
    def relations_as_parent
      self.relations.select{|r| r.parent_table == self }
    end
    def relations_as_child(schema)
      schema.tables.reject{|tbl| tbl == self }
        .map(&:relations).flatten.select{|r| r.child_table == self }
    end
    def relation_to(table_name)
      self.relations.find{|r| r.child_table.name == table_name }
    end
    def display_name
      self.localized_name || self.name
    end
    def default_position?
      self.position["left"] == 0 && self.position["top"] == 0
    end
  end

  class TableRelation < Struct.new(*%i(parent_table child_table parent_cardinality child_cardinality))
    include SchemaRD::Utils::StructAssigner
    def initialize(hash = nil)
      self.parent_cardinality = "1"
      self.child_cardinality = "N"
      self.assign(hash)
    end
  end

  class TableColumn < Struct.new(
    *%i(name localized_name type null default limit precision scale comment))
    include SchemaRD::Utils::StructAssigner
    def initialize(hash = nil)
      self.assign(hash)
    end
    def display_name
      self.localized_name || self.name
    end
  end
  class TableIndex < Struct.new(*%i(name columns unique))
    include SchemaRD::Utils::StructAssigner
    def initialize(hash = nil)
      self.columns = []
      self.assign(hash)
    end
  end
end
