require "pathname"
require "logger"

module Drone
  class Rancheroo
    class Config
      extend Forwardable

      attr_accessor :payload, :logger

      delegate [:vargs, :workspace] => :payload,
               [:netrc] => :workspace,
               [:url, :access_key, :secret_key, :service, :docker_image, :confirm, :confirm_timeout, :debug] => :vargs

      def initialize(payload, log = nil)
        self.payload = payload
        self.logger = log || default_logger
      end

      def rancher_url
        url + '/v1'
      end

      def get_timeout
        confirm_timeout || 100
      end

      def debug?
        debug || false
      end

      def validate!
        raise "No plugin data found" if vargs.empty?

        raise "Please provide API url" if url.nil?
        raise "Please provide API access key" if access_key.nil?
        raise "Please provide API secret key" if secret_key.nil?
        raise "Please provide service to upgrade" if service.nil?
        raise "Please provide docker image to use for upgrade" if docker_image.nil?
      end

    protected

      def default_logger
        @logger ||= Logger.new(STDOUT).tap do |l|
          l.level = debug? ? Logger::DEBUG : Logger::INFO
          l.formatter = proc do |sev, datetime, _progname, msg|
            "Rancheroo: #{msg}\n"
          end
        end
      end
    end
  end
end
