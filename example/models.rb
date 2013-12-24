# encoding: utf-8

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "dm-core"
require "dm-notifications"

class User
  include DataMapper::Resource
end
