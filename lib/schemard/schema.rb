require_relative 'utils/struct_assigner'

module SchemaRD
  class Schema
    attr_reader :relations
    def initialize
      @tables = {}
      @relations = []
    end
    def tables
      @tables.values
    end
    def table(name)
      @tables[name.to_s]
    end
    def add_table(name, table_object)
      @tables[name.to_s] = table_object
      table_object.set_schema(self)
    end
    def add_relation(relation)
      @relations << relation
    end
  end

  class Table < Struct.new(*%i(columns indexes name localized_name description position parsed_db_comment))
    include SchemaRD::Utils::StructAssigner
    def initialize(hash = nil)
      self.columns = []
      self.indexes = []
      self.position = { "left" => 0, "top" => 0 }
      self.assign(hash)
    end
    def set_schema(schema)
      @schema = schema
    end
    def relations_as_parent
      @schema.relations.select{|r| r.parent_table == self }
    end
    def relations_as_child
      @schema.relations.select{|r| r.child_table == self }
    end
    def relation_to(table_name)
      self.relations_as_parent.find{|r| r.child_table.name == table_name }
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
    *%i(name localized_name type null default limit precision scale description parsed_db_comment))
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
