require 'webrick'
require_relative "controller"

module SchemaRD
  class WebServer
    attr_reader :config
    def initialize(config)
      @config = config
    end
    def setup(srv, options)
      Signal.trap("INT"){ srv.shutdown }
      Signal.trap("TERM"){ srv.shutdown }

      # アクションメソッド
      srv.mount_proc '/' do |req, res|
        controller = SchemaRD::Controller.new(self.config)
        case req.path
        when "/", "/index"
          controller.index(req, res)
        when /\/tables\/.+/
          controller.show(req, res) if req.request_method == "GET"
          controller.update(req, res) if req.request_method == "POST"
        when /.*\.(js|css|ico)/
          controller.static_file(req, res)
        else
          res.status = Rack::Utils.status_code(404)
        end
      end
    end

    def start()
      options = {
        :Host => config.webserver_host,
        :Port => config.webserver_port,
        :ServerType => WEBrick::SimpleServer,
        :Logger => WEBrick::Log.new(config.log_output),
      }
      begin
        srv = WEBrick::HTTPServer.new(options);
        setup(srv, options)
        srv.start
      rescue Errno::EADDRINUSE => e
        (options[:Logger] || Logger.new(STDOUT)).error("#{__FILE__}: #{e.to_s}")
      end
    end
  end
end

if $0 == __FILE__
  config = SchemaRD::Configuration.new(ARGV)
  if config.valid?
    SchemaRD::WebServer.new(config).start()
  else
    config.errors.each{|err| puts err }
  end
end
