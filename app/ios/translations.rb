module I18n
  class << self
    def translate(key, substitutions = {})
      String.new((NSBundle.mainBundle.localizedStringForKey(key, value:"", table:nil))).tap do |result|
        substitutions.each do |key, value|
          result.gsub!("%{#{key}}", value.to_s)
        end
      end
    end
    alias t translate

    def locale
      NSLocale.preferredLanguages.first
    end
  end
end

def _(s, h=nil)
return s_(s,h) if h.is_a?(Hash)
I18n.t(s)
end

def s_(s, h={})
t={}
for key in h.keys
t[key.to_sym]=h[key]
end
I18n.t(s,t)
end