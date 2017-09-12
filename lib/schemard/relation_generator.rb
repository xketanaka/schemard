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
        ENV["RAILS_ENV"] = "production"
        Dir.chdir(rails_root) do
          require require_path.to_s
        end
      end
    end
    def ready?
      unless defined?(Rails)
        puts "Rails application not found."
        return false
      end
      unless Rails.application.config.eager_load
        puts "Rails.application.eager_load was set to false, abort!"
        return false
      end
      true
    end
    def run
      hash = ObjectSpace.each_object(Class)
      .select{|o| o.ancestors.include?(ActiveRecord::Base) && o != ActiveRecord::Base }
      .select{|o| o.table_name }
      .each_with_object({}) do |model, hash|
        hash[model.table_name] = {}

        relation_selector = ->(type){
          # Over ActiveRecord 4.2.7
          if defined?(ActiveRecord::Reflection::HasOneReflection)
            klasses = {
              has_one: ActiveRecord::Reflection::HasOneReflection,
              has_many: ActiveRecord::Reflection::HasManyReflection,
              belongs_to: ActiveRecord::Reflection::BelongsToReflection
            }
            model._reflections.values.select{|r| r.is_a?(klasses[type]) }
          else
            klasses = {
              has_one: ActiveRecord::Associations::HasOneAssociation,
              has_many: ActiveRecord::Associations::HasManyAssociation,
              belongs_to: ActiveRecord::Associations::BelongsToAssociation
            }
            model.reflections.values
            .select{|r| r.is_a?(ActiveRecord::Reflection::AssociationReflection) }
            .select{|r| r.association_class == klasses[type] }
          end
        }
        has_one_rels = relation_selector.call(:has_one)
        has_many_rels = relation_selector.call(:has_many)
        belongs_to_rels = relation_selector.call(:belongs_to)

        relations_to_table_names = ->(relations){
          relations.map{|r| begin r.klass.table_name; rescue => e; nil; end }.compact
        }

        if has_one_rels.present?
          hash[model.table_name]["has_one"] = relations_to_table_names.call(has_one_rels)
        end
        if has_many_rels.present?
          hash[model.table_name]["has_many"] = relations_to_table_names.call(has_many_rels)
        end
        if belongs_to_rels.present?
          hash[model.table_name]["belongs_to"] = relations_to_table_names.call(belongs_to_rels)
        end
      end
      puts YAML.dump({ "tables" => hash.reject{|key,val| val.empty? } })
    end
  end
end
