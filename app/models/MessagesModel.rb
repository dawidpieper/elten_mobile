class Struct_MessagesRoot < Struct_MTLFContainer
def initialize
super
@name=_("Messages")
@editable=false
@writable=true
@creation_types=[:text, :audio]
end
def get
return @children
end
def build(resp)
for user in resp['users']
fetch(Struct_MessagesUser, user)
end
sort_date!
reverse!
end
def refresh(&block)
erequest("messages", {'cat'=>'users'}, true) do |resp|
if resp.is_a?(Hash)
if resp["code"] != 200
UI.alert(:title => _("Error occurred"), :message => resp["errmsg"]||resp["code"].to_s ) { }
else
build(resp)
block.call if block != nil
end
end
end
end
end

class Struct_MessagesUser < Struct_MTLFContainer
attr_accessor :lastuser
attr_accessor :subject
attr_accessor :unread
attr_accessor :maxid
def initialize(s)
raise(ArgumentError, "hash was expected") if !s.is_a?(Hash)
super
@maxid=0
@id=s['user']
@name=s['user']
@author=s['user']
@lastuser=s['last']
@lastsubject=s['subj']
@date=s['date']
@unread=(s['read'].to_i==0)
@editable=false
@writable=false
@creation_types=[:text, :audio]
end
def to_s
return [
((@unread)?("("+_("New")+")"):(""))+@name,
_("Last message: %{subj}, from: %{user}", 'subj'=>@lastsubject, 'user'=>@lastuser),
Time.at(@date).strftime("%Y-%m-%d %H:%M:%S")
].join(", ")
end
def get
return @children
end
def build(resp)
@writable = (resp['canreply'].to_i==1)
for conversation in resp['conversations']
fetch(Struct_MessagesConversation, conversation, @id)
@maxid=conversation['id'].to_i if conversation['id'].to_i>@maxid
end
sort_date!
reverse!
end
def refresh(&block)
erequest("messages", {'cat'=>'conversations', 'user'=>@id}, true) do |resp|
if resp.is_a?(Hash)
if resp["code"] != 200
UI.alert(:title => _("Error occurred"), :message => resp["errmsg"]||resp["code"].to_s ) { }
else
build(resp)
block.call if block != nil
end
end
end
end
end

class Struct_MessagesConversation < Struct_MTLFContainer
attr_accessor :subject
attr_accessor :lastuser
attr_accessor :user
attr_accessor :maxid
def initialize(s, user)
raise(ArgumentError, "hash was expected") if !s.is_a?(Hash)
super
@maxid=0
@id=s['subj']
@name=s['subj']
@lastuser=s['last']
@unread = (s['read'].to_i==0)
@date = s['date'].to_i
@creation_types=[:text, :audio]
@user=""
end
def parent=(p)
@parent=p
if @parent.is_a?(Struct_MessagesUser)
@writable=@parent.writable
@user=@parent.id
end
end
def to_s
return [
((@unread)?("("+_("New")+")"):(""))+@name,
_("Last message from %{user}", 'user'=>@lastuser),
Time.at(@date).strftime("%Y-%m-%d %H:%M:%S")
].join(", ")
end
def get
return @children
end
def build(resp)
@writable = (resp['canreply'].to_i==1)
for message in resp['messages']
fetch(Struct_MessagesMessage, message)
@maxid=message['id'].to_i if message['id'].to_i>@maxid
end
sort_date!
end
def refresh(&block)
erequest("messages", {'cat'=>'messages', 'user'=>@user, 'subj'=>@id}, true) do |resp|
if resp.is_a?(Hash)
if resp["code"] != 200
UI.alert(:title => _("Error occurred"), :message => resp["errmsg"]||resp["code"].to_s ) { }
else
build(resp)
block.call if block != nil
end
end
end
end
end

class Struct_MessagesMessage < Struct_MTLFEntry
def initialize(s)
raise(ArgumentError, "hash was expected") if !s.is_a?(Hash)
super
@id=s['id'].to_i
@date=s['date'].to_i
@author=s['sender']
@value=s['message']
if s['audio_url']!=nil
@resource_type = :audio
@resource=s['audio_url']
end
@editable=true
@writable=true
end
def to_s
return (@unread?("("+_("New")+") "):"")+@author+":\n"+@value+"\n"+Time.at(@date).strftime("%Y-%m-%d %H:%M:%S")
end
end