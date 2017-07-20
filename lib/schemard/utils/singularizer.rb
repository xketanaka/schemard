module SchemaRD::Utils
  module Singularizer
    def singularize
      return self if NO_SINGULAR_WORDS.include?(self)

      found = SINGULAR_RULES.find{|regexp, _| self =~ regexp }
      found ? self.gsub(found[0], found[1]) : self
    end
    SINGULAR_RULES = [
      [/(z)ombies$/i, "\\1ombie"],
      [/(z)ombie$/i, "\\1ombie"],
      [/(m)oves$/i, "\\1ove"],
      [/(m)ove$/i, "\\1ove"],
      [/(s)exes$/i, "\\1ex"],
      [/(s)ex$/i, "\\1ex"],
      [/(c)hildren$/i, "\\1hild"],
      [/(c)hild$/i, "\\1hild"],
      [/(m)en$/i, "\\1an"],
      [/(m)an$/i, "\\1an"],
      [/(p)eople$/i, "\\1erson"],
      [/(p)erson$/i, "\\1erson"],
      [/(database)s$/i, "\\1"],
      [/(quiz)zes$/i, "\\1"],
      [/(matr)ices$/i, "\\1ix"],
      [/(vert|ind)ices$/i, "\\1ex"],
      [/^(ox)en/i, "\\1"],
      [/(alias|status)(es)?$/i, "\\1"],
      [/(octop|vir)(us|i)$/i, "\\1us"],
      [/^(a)x[ie]s$/i, "\\1xis"],
      [/(cris|test)(is|es)$/i, "\\1is"],
      [/(shoe)s$/i, "\\1"],
      [/(o)es$/i, "\\1"],
      [/(bus)(es)?$/i, "\\1"],
      [/^(m|l)ice$/i, "\\1ouse"],
      [/(x|ch|ss|sh)es$/i, "\\1"],
      [/(m)ovies$/i, "\\1ovie"],
      [/(s)eries$/i, "\\1eries"],
      [/([^aeiouy]|qu)ies$/i, "\\1y"],
      [/([lr])ves$/i, "\\1f"],
      [/(tive)s$/i, "\\1"],
      [/(hive)s$/i, "\\1"],
      [/([^f])ves$/i, "\\1fe"],
      [/(^analy)(sis|ses)$/i, "\\1sis"],
      [/((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)(sis|ses)$/i, "\\1sis"],
      [/([ti])a$/i, "\\1um"],
      [/(n)ews$/i, "\\1ews"],
      [/(ss)$/i, "\\1"],
      [/s$/i, ""]
    ]
    NO_SINGULAR_WORDS = %w(equipment information rice money species series fish sheep jeans police)
  end
end

class String
  include SchemaRD::Utils::Singularizer
end
