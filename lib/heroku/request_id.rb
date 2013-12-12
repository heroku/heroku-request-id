require "heroku/auth"
require "heroku/command"

Heroku::Command.global_option :request_id, "--request-id REQUESTID", "-z"

module Heroku::RequestId
  class Placeholder
    def initialize(*args); end
    def index; end
  end

  def self.included(base)
    patch_client(base.client) if base.respond_to? :client
    patch_api(base.api) if base.respond_to? :api
  end

  def self.options
    cmd = Heroku::Command.clone
    cmd.commands["request-id"] = {
      :klass => Heroku::RequestId::Placeholder,
      :options => [],
      :method => "index"
    }
    cmd.prepare_run("request-id", ARGV)
    return cmd.current_options
  end

  private

  def self.patch_client(client)
    def client.heroku_headers
      options = Heroku::RequestId.options
      headers = {}
      headers.merge!("Request-Id" => options[:request_id]) if options[:request_id]
      super.merge(headers)
    end
  end

  def self.patch_api(api)
    api.instance_eval do
      options = Heroku::RequestId.options
      data = if @connection.respond_to?(:data)
        @connection.data
      elsif @connection.respond_to?(:connection)
        @connection.connection
      end
      headers = {}
      headers.merge!("Request-Id" => options[:request_id]) if options[:request_id]
      data[:headers].merge!(headers)
    end
  end
end

Heroku::Auth.send(:include, Heroku::RequestId)
