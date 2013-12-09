require "heroku/auth"

Heroku::Command.global_option :request_id, "--request-id", "-z"

module Heroku::RequestId
  def self.included(base)
    patch_client(base.client) if base.respond_to? :client
    patch_api(base.api) if base.respond_to? :api
  end

  private

  def self.patch_client(client)
    def client.heroku_headers
      headers = {}
      headers.merge!("Request-Id" => options[:request_id]) if options[:request_id]
      super.merge(headers)
    end
  end

  def self.patch_api(api)
    api.instance_eval do
      data = if @connection.respond_to?(:data)
        @connection.data
      elsif @connection.respond_to?(:connection)
        @connection.connection
      end
      # headers = {}
      # headers.merge!("Request-Id" => options[:request_id]) if options[:request_id]
      # data[:headers].merge!(headers)
    end
  end
end

Heroku::Auth.send(:include, Heroku::RequestId)
