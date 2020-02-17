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