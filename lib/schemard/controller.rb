require 'optparse'
require 'yaml'
require_relative "schema"
require_relative "schema_parser"
require_relative "metadata"
require_relative "utils/localizer"
require_relative "utils/struct_assigner"

module SchemaRD
  class Controller
    attr_reader :config

    def initialize(config)
      @config = config;
    end

    def index(req, res)
      locale = SchemaRD::Utils::MessageLocalizer.new(default_lang(req))
      schema = SchemaRD::SchemaParser.new(config.input_file).parse(with_comment: config.parse_db_comment?)
      SchemaRD::Metadata.load(config: self.config, lang: default_lang(req), schema: schema)
      send(req, res, render("index.html.erb", binding))
    end

    def show(req, res)
      locale = SchemaRD::Utils::MessageLocalizer.new(default_lang(req))
      match = req.path.match(/\/tables\/(\w+)/)
      unless match
        res.status = 404
      else
        schema = SchemaRD::SchemaParser.new(config.input_file).parse(with_comment: config.parse_db_comment?)
        SchemaRD::Metadata.load(config: self.config, lang: default_lang(req), schema: schema)
        table_name = match[1]
        send(req, res, render("show.html.erb", binding))
      end
    end

    def update(req, res)
      match = req.path.match(/\/tables\/(\w+)/)
      unless match
        res.status = 404
      else
        if req.query['layout']
          pos = req.query['layout'].split(",")
          SchemaRD::Metadata::Writer.new(config.output_file).save(match[1], { "left" => pos[0], "top" => pos[1] })
        end
        send(req, res, "OK")
      end
    end

    def static_file(req, res)
      send(req, res, File.new(CONTENTS_DIR + req.path).read)
    end

    TEMPLATES_DIR = "#{File.dirname(File.expand_path(__FILE__))}/../templates/"
    CONTENTS_DIR = "#{File.dirname(File.expand_path(__FILE__))}/../contents/"

    private

    def default_lang(req)
      req.accept_language[0] || "en"
    end

    def send(req, res, body = nil)
      res.status = 200
      res.content_type = case req.path
      when /.*\.js\Z/
        "text/javascript"
      when /.*\.css\Z/
        "text/css"
      when /.*\.ico\Z/
        "image/x-icon"
      else
        "text/html"
      end
      res.body = body
    end

    def render(filename, current_binding)
      ERB.new(File.new(TEMPLATES_DIR + filename).read, nil, '-').result(current_binding)
    end
  end

  CONFIG_FILE = ".schamard.config"
  DEFAULT_CONFIG = {
    input_file: "db/schema.rb",
    output_file: "schema.metadata",
    metadata_files: [],
    rdoc_enabled: false,
    parse_db_comment_as: "ignore",
    log_output: STDOUT,
    webserver_host: "127.0.0.1",
    webserver_port: "10080",
    show_version: false
  }

  class Configuration < Struct.new(*DEFAULT_CONFIG.keys)
    include SchemaRD::Utils::StructAssigner
    attr_reader :errors
    def initialize(argv = nil)
      hash = {}.merge(DEFAULT_CONFIG)
      hash.merge!(YAML.load_file(CONFIG_FILE)) if File.readable?(CONFIG_FILE)

      unless argv.nil?
        opt = OptionParser.new
        opt.on('-i VAL', '--input-file=VAL') {|v| hash[:input_file] = v }
        opt.on('-o VAL', '--output-file=VAL') {|v| hash[:output_file] = v }
        opt.on('-f VAL', '-m VAL', '--metadata-file=VAL') {|v| hash[:metadata_files] << v }
        opt.on('--rdoc', '--rdoc-enabled') { hash[:rdoc_enabled] = true }
        opt.on('--parse-db-comment-as=VAL') {|v| hash[:parse_db_comment_as] = v }
        opt.on('-s', '--silent', '--no-log-output') {|v| hash[:log_output] = File.open(File::NULL, 'w') }
        opt.on('-h VAL', '--host=VAL') {|v| hash[:webserver_host] = v }
        opt.on('-p VAL', '--port=VAL') {|v| hash[:webserver_port] = v }
        opt.on('-l VAL', '--log-output=VAL') {|v| hash[:log_output] = self.class.str_to_io(v) }
        opt.on('-v', '--version') {|v| hash[:show_version] = true }
        opt.parse(argv)
      end
      self.assign(hash)
    end

    def parse_db_comment?
      self.parse_db_comment_as != "ignore"
    end

    def valid?
      @errors = []
      unless File.readable?(self.input_file)
        self.errors << "InputFile: \"#{self.input_file}\" is not readable!"
      end
      unless (File.writable?(self.output_file) || File.writable?(File.dirname(self.output_file)))
        self.errors << "OutputFile: \"#{self.output_file}\" is not writable!"
      end
      self.metadata_files.each do |metadata_file|
        unless File.readable?(metadata_file)
          self.errors << "MetadataFile: \"#{metadata_file}\" is not readable!"
        end
      end
      unless %w(ignore name localized_name description custom).include?(self.parse_db_comment_as)
        self.errors << "ParseDBCommentAs: \"#{self.parse_db_comment_as}\" is not allowed!"
      end
      if self.log_output.is_a?(String)
        self.errors << "LogFile: \"#{self.log_output}\" is not writable!"
      end
      unless self.webserver_port =~ /^[0-9]+$/
        self.errors << "WebServerPort: \"#{self.webserver_port}\" is invalid!"
      end
      if self.show_version
        self.errors << "schemard: version-#{SchemaRD::VERSION}"
      end
      self.errors.empty?
    end

    private

    def self.str_to_io(str)
      case str
      when "stdout", "STDOUT"
        STDOUT
      when "stderr", "STDERR"
        STDERR
      else
        File.open(str, 'w') rescue str
      end
    end
  end
end
