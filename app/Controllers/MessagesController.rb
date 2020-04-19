class Control_Messages < Control_MTLF
def compose(*arg)
if @model.is_a?(Struct_MessagesConversation)
if arg[1]==:text
message_text(@model.user, "RE: "+@model.id, arg[0])
elsif arg[1]==:audio
message_audio(@model.user, "RE: "+@model.id, arg[0])
end
end
if @model.is_a?(Struct_MessagesUser)
if arg[1]==:text
message_text(@model.id, arg[2]['subject'], arg[0])
elsif arg[1]==:audio
message_audio(@model.id, arg[2]['subject'], arg[0])
elsif arg.size==0
creator = Scene_MTLFCreator.new(@model, self, [[_("Subject"), 'subject']], _("New message to user %{user}", 'user'=>@model.id), _("Message"))
@view.navigation.push(creator)
end
end
if @model.is_a?(Struct_MessagesRoot)
if arg[1]==:text
message_text(arg[2]['receiver'], arg[2]['subject'], arg[0])
elsif arg[1]==:audio
message_audio(arg[2]['receiver'], arg[2]['subject'], arg[0])
elsif arg.size==0
creator = Scene_MTLFCreator.new(@model, self, [[_("Receiver"), 'receiver'], [_("Subject"), 'subject']], _("New message"), _("Message"))
@view.navigation.push(creator)
end
end
end
def message_text(receiver, subject, text)
url=message_makeurl(receiver, subject)
              head = { "Content-Type" => "application/json" }
              Net.post(url, { :body => { "msg" => text }, :headers => head }) {|rsp|message_rsp(rsp)}
end
def message_audio(receiver, subject, file)
rece = File.get_data(file)
url=message_makeurl(receiver, subject, true)
head = { "Content-Type" => "application/aac" }
Net.post(url, { :body => rece, :headers => head }) {|rsp|message_rsp(rsp)}
end
def message_makeurl(receiver, subject, audio=false)
q={ "to" => receiver, 'subj' => subject}
if audio
q['src']="-"
q['type']='audio'
end
              url = create_query("messages/send", q)
return url
end
def message_rsp(rsp)
                if rsp.body.is_a?(Hash)
                  if rsp.body["code"] != 200
                    UI.alert({ :title => _("Error while sending message"), :message => rsp.body["errmsg"] }) { }
                  else
@view.navigation.pop if !@model.final?
reset
@view.reset
@model.refresh {@view.update(true)}
                  end
                end
end
end