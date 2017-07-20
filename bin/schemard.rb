require 'yaml'
require 'pathname'
require 'optparse'

class RelationGenerator
  def self.usage
    "Usage: schemard -d <Rails.root.dir>"
  end

  def initialize(rails_root)
    require_path = rails_root + "config/environment.rb"
    unless require_path.exist?
      puts "<#{rails_root}> is not Rails.root Directory, Abort!"
      puts self.class.usage()
    else
      Dir.chdir(rails_root) do
        require require_path.to_s
      end
    end
  end
  def ready?
    defined?(Rails)
  end
  def run
    Dir.glob(Rails.root + "app/models/**/*")
    .reject{|path| Dir.exist?(path) }.each{|filepath| require filepath }

    hash = ObjectSpace.each_object(Class)
    .select{|o| o.ancestors.include?(ActiveRecord::Base) && o != ActiveRecord::Base }
    .select{|o| o.table_name }
    .each_with_object({}) do |model, hash|
      hash[model.table_name] = {}

      relation_selector = ->(klass){ model._reflections.values.select{|r| r.is_a?(klass) } }
      has_one_rels = relation_selector.call(ActiveRecord::Reflection::HasOneReflection)
      has_many_rels = relation_selector.call(ActiveRecord::Reflection::HasManyReflection)
      belongs_to_rels = relation_selector.call(ActiveRecord::Reflection::BelongsToReflection)

      if has_one_rels.present?
        hash[model.table_name]["has_one"] = has_one_rels.map{|r| r.klass.table_name }
      end
      if has_many_rels.present?
        hash[model.table_name]["has_many"] = has_many_rels.map{|r| r.klass.table_name }
      end
      if belongs_to_rels.present?
        hash[model.table_name]["belongs_to"] = belongs_to_rels.map{|r| r.klass.table_name }
      end
    end
    puts YAML.dump({ "tables" => hash })
  end
end

if ARGV[0] == "generate-relations" || ARGV[0] == "generate-relation"
  rails_root = Pathname.pwd
  opt = OptionParser.new
  opt.on('-d VAL', 'Rails.root.directory') {|v| rails_root = Pathname.new(v) }
  opt.parse(ARGV.slice(1..-1))

  generator = RelationGenerator.new(rails_root.expand_path)
  if generator.ready?
    generator.run
  end
else
  require 'schemard'
  config = SchemaRD::Configuration.new(ARGV)
  SchemaRD::WebServer.new(config).start()
end
