require "net/http"
require "uri"

class ApplicationController < ActionController::API
  include ExceptionHandler
end
