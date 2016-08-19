module Drone
  #
  # Drone plugin to upgrade services in Rancher
  #
  class Rancheroo
    autoload :Config,
      File.expand_path("../rancheroo/config", __FILE__)

    autoload :Rancher,
      File.expand_path("../rancheroo/rancher", __FILE__)

    autoload :Logger,
      File.expand_path("../rancheroo/logger", __FILE__)

    attr_accessor :config

    def initialize(payload)
      self.config = Config.new(
        payload
      )
    end

    def execute!
      config.validate!

      Rancher.new config do |rancher|
        rancher.start_upgrade!

        if config.confirm then
          rancher.confirm_upgrade!
        end
      end
    end
  end
end
