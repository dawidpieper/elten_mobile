def _(s)
t=s+".translation"
y=I18n.translate t
if t==y
return s
else
return y
end
end