class Control_Forum < Control_MTLF
def compose(*arg)
if @model.is_a?(Struct_ForumThread)
if arg[1]==:text
post_text(arg[0], nil, nil, @model.id)
elsif arg[1]==:audio
post_audio(arg[0], nil, nil, @model.id)
end
end
if @model.is_a?(Struct_ForumForum)
if arg[1]==:text
post_text(arg[0], @model.id, arg[2]['title'])
elsif arg[1]==:audio
post_audio(arg[0], @model.id, arg[2]['title'])
elsif arg.size==0
creator = Scene_MTLFCreator.new(@model, self, [[_("Thread name"), 'title']], _("New thread"), _("Post"))
@view.navigation.push(creator)
end
end
end
def post_text(text, forum=nil, title=nil, thread=nil)
url=post_makeurl(forum, title, thread)
              head = { "Content-Type" => "application/json" }
              Net.post(url, { :body => { "post" => text }, :headers => head }) {|rsp|post_rsp(rsp)}
end
def post_audio(file, forum=nil, title=nil, thread=nil)
rece = File.get_data(file)
              url = post_makeurl(forum, title, thread, true)
head = { "Content-Type" => "application/aac" }
Net.post(url, { :body => rece, :headers => head }) {|rsp|post_rsp(rsp)}
end
def post_makeurl(forum, title, thread, audio=false)
q={ "ac" => "add"}
q["threadid"] = thread.to_s if thread!=nil
q['forum']=forum.to_s if forum!=nil
q['threadname']=title.to_s if title!=nil
q['threadid']='new' if thread==nil
if audio
q['src']="-"
q['type']='audio'
end
              url = create_query("forum/edit", q)
return url
end
def post_rsp(rsp)
                if rsp.body.is_a?(Hash)
                  if rsp.body["code"] != 200
                    UI.alert({ :title => _("Error while sending your reply"), :message => rsp.body["errmsg"] }) { }
                  else
@view.navigation.pop if !@model.final?
reset
@view.reset
@model.refresh {@view.update(true)}
                  end
                end
end

def fetch_actions(item)
a={}
if item.is_a?(Struct_ForumGroup)
a[_("Members")] = :groupmembers
k = nil
if item.author != $session.name and (item.role == 1 or item.role == 2)
k = _("Leave")
elsif item.open and item.public and item.role == 0
k = _("Join")
elsif item.role==5
k = _("Accept invitation")
elsif item.role == 0 and (item.open==1 or item.public==1)
k = _("Request")
end
a[k] = :groupchrole if k != nil && (@grouprolechanged==nil || @grouprolechanged[item.id]!=true)
end
if item.is_a?(Struct_ForumThread)
s=_("Follow thread")
s=_("Unfollow thread") if item.followed==true
a[s] = :threadfollower
end
return a
end

def groupmembers(group)
scene=Scene_UsersList.new(self, _("Members of %{groupname}", 'groupname'=>group.name))
waiting=0
group.enum_members do |user, role|
if user == :last
scene.refresh
else
o=""
o = _("moderator") if role==2 and group.author != user
o = _("administrator") if group.author == user
o = _("invited") if role==5
o = _("banned") if role==3
scene.adduser(user, o)
end
end
@view.navigation.push(scene)
end

def groupchrole(group)
@grouprolechanged||=[]
@grouprolechanged[group.id]=true
ac = "join"
s = _("Are you sure you want to join %{groupname}?", "groupname"=>group.name)
s = _("Are you sure you want to request to join %{groupname}?", "groupname"=>group.name) if !group.open or !group.public
if group.role==1 or group.role==2
ac = "leave"
s = _("Are you sure you want to leave %{groupname}?", "groupname"=>group.name)
end
UI.alert(:title => "Group membership", :message => s, :default => "Yes", :cancel => "No") { |n|
if n == :default
erequest("forum/groups", { "ac" => ac, "groupid" => group.id.to_s }) { |rsp|
if rsp["code"] != 200
UI.alert(:title => _("Error"), :message => rsp["errmsg"], :default => "Cancel") { }
else
if group.role==1 || group.role==2
group.role=0
elsif group.role==0 && (group.open && group.public)
group.role=1
end
@model.refresh {@view.update(true)}
end
}
end
}
end

def threadfollower(thread)
ac="follow"
ac="unfollow" if thread.followed
erequest("forum/follow", { "cat" => "thread", "threadid" => thread.id.to_s, "ac" => ac }) { |resp|
if resp["code"] == 200
thread.followed=!thread.followed
@model.refresh {@view.update(true)}
else
UI.alert(:title => _("Error"), :message => resp["errmsg"]) { }
end
}
end

end