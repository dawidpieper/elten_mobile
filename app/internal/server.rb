module Elten
  module Server
    def url_encode(url)
      r = url.gsub(/([^ a-zA-Z0-9_.-]+)/) do |m|
        "%" + m.unpack("H2" * m.bytesize).join("%").upcase
      end.tr(" ", "+")
      return r
    end

    def url_decode(url)
      r = url
      o = ""
      while r != o
        o = r
        r = url.gsub(/%([a-fA-F0-9][a-fA-F0-9])/) do |m|
          s = "\0"
          s[0] = m[1..2].to_i(16)
          s
        end.tr("+", " ")
        url = r
      end
      return r
    end

    def create_query(group, params = {})
      url = "https://api.elten-net.eu"
      group = "/" + group if group[0..0] != "/"
      url += group
      urlparams = "?app=#{$appcode}"
      urlparams += "\&name=" + url_encode($session.name) + "&token=" + url_encode($session.token) if $session != nil
      for key in params.keys
        urlparams += "&" if urlparams != "?"
        urlparams += url_encode(key) + "=" + url_encode(params[key])
      end
      url += urlparams if urlparams != "?"
      return url
    end
  end
end

class Object
  include Elten::Server
end
