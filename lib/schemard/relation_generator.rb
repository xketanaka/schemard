require 'yaml'
require 'pathname'
require 'optparse'

module SchemaRD
  class RelationGenerator
    def initialize(argv)
      rails_root = Pathname.pwd
      opt = OptionParser.new
      opt.on('-d VAL', 'Rails.root.directory') {|v| rails_root = Pathname.new(v).expand_path }
      opt.parse(argv)

      require_path = rails_root + "config/environment.rb"
      unless require_path.exist?
        puts "<#{rails_root}> is not Rails.root Directory, Abort!"
        puts "Usage: schemard -d <Rails.root.dir>"
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
end
