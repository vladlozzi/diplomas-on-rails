# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

require "rack"
unless defined?(Rack::File)
  module Rack
    File = Files
  end
end

run Rails.application
Rails.application.load_server
