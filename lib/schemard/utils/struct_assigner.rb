module SchemaRD
  module Utils
    module StructAssigner
      def assign(hash)
        hash && self.members.each do |key|
          self[key] = hash[key] if hash.has_key?(key)
          self[key] = hash[key.to_sym] if hash.has_key?(key.to_sym)
        end
      end
    end
  end
end
