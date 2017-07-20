
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

  module AttributeAssigner
    def assign(hash)
      return self if hash.nil?
      self.members.each do |key|
        value = hash[key] || hash[key.to_sym]
        self[key] = value if value
       end
    end
  end

  class Table < Struct.new(*%i(relations columns indexes name localized_name comment position))
    include AttributeAssigner
    def initialize(hash = nil)
      self.relations = []
      self.columns = []
      self.indexes = []
      self.position = { "left" => 5, "top" => 100 }
      self.assign(hash)
    end
    def relations_as_parent
      self.relations.select{|r| r.parent_table == self }
    end
    def relation_to(table_name)
      self.relations.find{|r| r.child_table.name == table_name }
    end
    def display_name
      self.localized_name || self.name
    end
  end

  class TableRelation < Struct.new(*%i(parent_table child_table parent_cardinality child_cardinality))
    include AttributeAssigner
    def initialize(hash = nil)
      self.parent_cardinality = "1"
      self.child_cardinality = "N"
      self.assign(hash)
    end
  end

  class TableColumn < Struct.new(
    *%i(name localized_name type null default limit precision scale comment))
    include AttributeAssigner
    def initialize(hash = nil)
      self.assign(hash)
    end
    def display_name
      self.localized_name || self.name
    end
  end
  class TableIndex < Struct.new(*%i(name columns unique))
    include AttributeAssigner
    def initialize(hash = nil)
      self.columns = []
      self.assign(hash)
    end
  end
end
