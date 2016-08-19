require 'rest-client'
require 'json'
require 'eventmachine'

module Drone
  class Rancheroo
    class Rancher
      class RancherWaitTimeOutError < StandardError; end

      attr_accessor :config

      def initialize(config)
        self.config = config

        yield(
          self
        ) if block_given?
      end

      def validate!
        true
      end

      def start_upgrade!
        service_name = config.service.split("/").last

        if (service = services.detect{|service| service["name"] == service_name}) then
          if ["active", "inactive"].include?(service["state"]) then
            Logger.log.info "Service #{service_name} found (##{service["id"]})"
          else
            Logger.log.info "Service #{service_name} found but cannot be upgraded. State: #{service["state"]}"
            exit 1
          end

          # Create payload for upgrade
          payload = create_payload(service)
        end

        begin
          Logger.log.info "Initiating service upgrade for #{service_name}"

          response = RestClient::Request.execute(
            method: :post,
            url: url_for(:upgrade, service),
            user: config.access_key,
            password: config.secret_key,
            payload: "#{payload.to_json}",
            headers: {"Content-Type" => "application/json"}
          )

          if config.confirm then
            sleep 10
            confirm_upgrade!(service)
          else
            end_upgrade!
          end

        rescue RestClient::UnprocessableEntity => e
          Logger.log.info "An error occured upgrading the service:"
          Logger.log.info e.response
          Logger.log.info e.message
        end
      end

      def confirm_upgrade!(service)
        wait_for_state(service, "upgraded")

        response = RestClient::Request.execute(
          method: :post,
          url: url_for(:confirm, service),
          user: config.access_key,
          password: config.secret_key
        )

        if response.code == 202 then
          end_upgrade!
          exit
        else
          Logger.log.info "Service could not be upgraded"
        end
      end

      def end_upgrade!
        Logger.log.info "Service upgraded successfully"
      end

    protected

      def create_payload(service)
        inServiceStrategy = {
          launchConfig: service["launchConfig"],
          secondaryLaunchConfigs: service["secondaryLaunchConfigs"],
          startFirst: true
        }
        inServiceStrategy[:launchConfig]["imageUuid"] = "docker:#{config.docker_image}"

        toServiceStrategy = {
          "batchSize": 1,
          "finalScale": service["scale"],
          "intervalMillis": 2000,
          "updateLinks": false
        }

        payload = {
          toServiceStrategy: toServiceStrategy,
          inServiceStrategy: inServiceStrategy
        }

        return payload
      end

      def url_for(action, service)
        case action.to_s
        when "upgrade"
          return service["actions"]["upgrade"]
        when "confirm"
          return service["actions"]["upgrade"].sub("upgrade", "finishupgrade")
        end
      end

      def services
        main_response = RestClient::Request.execute(
          method: :get,
          url: config.rancher_url,
          user: config.access_key,
          password: config.secret_key
        )
        main_response = JSON.parse(main_response)

        services_response = RestClient::Request.execute(
          method: :get,
          url: main_response["links"]["services"],
          user: config.access_key,
          password: config.secret_key
        )

        return JSON.parse(services_response)["data"]
      end

      def wait_for_state(service, desired_state)
        current_state = "pending"
        last_state = ""
        EM.run do
          EM.add_timer(config.get_timeout) do
            raise RancherWaitTimeOutError, "Timeout while waiting for transition to: #{desired_state}"
          end
          EM.tick_loop do
            if current_state != last_state then
              Logger.log.info "Updating service state. Current state: #{current_state}"
              last_state = current_state
            end

            response = RestClient::Request.execute(
              method: :get,
              url: service["links"]["self"],
              user: config.access_key,
              password: config.secret_key
            )

            current_state = JSON.parse(response)["state"]

            if current_state.eql?(desired_state.to_s)
              Logger.log.info "Service state now #{current_state}"
              EM.stop
            else
              sleep(1)
            end
          end
        end
      end
    end
  end
end
