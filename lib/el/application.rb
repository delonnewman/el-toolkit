# frozen_string_literal: true

module El
  class Application
    attr_reader :loader, :env, :root, :logger

    def initialize(root_dir:)
      @logger = Logger.new(STDOUT)
      @root   = Pathname.new(root_dir).expand_path
      @env    = PredicateString.new(ENV.fetch('RACK_ENV') { 'development' })
      @loader = Zeitwerk::Loader.new.tap do |loader|
        loader.push_dir(root.join('lib'))
        loader.push_dir(root.join('apps'))
        loader.enable_reloading if env.development?
        loader.setup
      end
    end
  end
end
