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
      return "" if params == nil
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

    def erequest(group, params = {}, errorignore = false, &b)
      $conn_st ||= {}
      $conn_ts ||= {}
      id = rand(1e8)
      Net.get(create_query(group, params)) { |rsp|
        if rsp.body.is_a?(Hash) or rsp.body.is_a?(Array)
          $conn_st[id] = rsp.status
          b.call(rsp.body)
        elsif $conn_failed != true
          $conn_st[id] = "Server returned unexpected error: #{rsp.status_message.gsub(/HTTP\/([\d.]+)/i, "")} (#{rsp.status.to_s})"
        end
      }
      if !errorignore
        ti = Time.now.to_f
        bl = Proc.new {
          err = nil
          if $conn_st[id].is_a?(String)
            err = $conn_st[id]
          elsif $conn_st[id] == nil && $conn_failed
            $conn_failed = false
            err = "Failed to connect to Elten server"
          end
          if $conn_st[id] != nil || err != nil || Time.now.to_f - ti > 5
            $conn_st.delete(id)
            if err != nil && !errorignore
              UI.alert(title: "Error", message: err, cancel: "Cancel", default: "Try again") { |ind|
                Task.main { erequest(group, params, errorignore, &b) if ind == :default }
              }
            end
            $conn_ts[id].stop
            $conn_ts.delete(id)
          end
        }
        $conn_ts[id] = Task::Timer.new(0.1, true, bl)
        return id
      end
    end
  end
end

class Object
  include Elten::Server
end
