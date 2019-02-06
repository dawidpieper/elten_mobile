class Elten_Session
  attr_accessor :name, :token

  def initialize(pre = {})
    @name = pre["name"] || ""
    @token = pre["token"] || ""
  end
end
