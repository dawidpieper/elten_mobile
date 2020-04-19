class Struct_ForumRoot < Struct_MTLFContainer
@@cache=nil
def initialize
super
@name=_("Forum")
end
def categories
return _("Joined groups"), _("Open groups"), _("All groups"), _("Moderated groups"), _("Waiting invitations")
end
def get
case @category
when 1
return get_open
when 2
return get_all
when 3
return get_moderated
when 4
return get_invited
else
return get_joined
end
end
def get_joined
sgroups=[]
sgroups.push(@followedthreads) if @followedthreads!=nil
@children.each {|g|
sgroups.push(g) if g.recommended||g.role==1||g.role==2
}
return sgroups
end
def get_open
sgroups=[]
@children.each {|g|
sgroups.push(g) if !g.recommended&&g.open&&g.public
}
return sgroups
end
def get_invited
sgroups=[]
@children.each {|g|
sgroups.push(g) if g.role==5
}
return sgroups
end
def get_moderated
sgroups=[]
@children.each {|g|
sgroups.push(g) if g.role==2
}
return sgroups
end
def get_all
sgroups=[]
@children.each {|g|
sgroups.push(g) if g.open||g.public
}
return sgroups
end
def build(groups, forums, threads)
if @followedthreads==nil
@followedthreads = Struct_ForumForum.new(:followedthreads)
@followedthreads.parent=self
end
@followedthreads.clear
@followedthreads.cnt_threads=0
@followedthreads.cnt_posts=0
@followedthreads.cnt_readposts=0
gh={}
fh={}
th={}
groups.values.each { |o|
g=fetch(Struct_ForumGroup, o)
gh[g.id]=g
}
forums.values.each {|o|
f=gh[o['groupid'].to_i].fetch(Struct_ForumForum, o)
fh[f.id]=f
}
threads.values.each {|o|
t=fh[o['forumid']].fetch(Struct_ForumThread, o)
if t.followed
@followedthreads.add(t)
@followedthreads.cnt_threads+=1
@followedthreads.cnt_posts+=t.cnt_posts
@followedthreads.cnt_readposts+=t.cnt_readposts
end
th[t.id]=t
}
@followedthreads.sort_date!
@followedthreads.reverse!
gh.values.each{|g| g.sort_pos!}
fh.values.each{|f| f.sort_date!;f.reverse!;}
sort_id!
end
def refresh(&block)
if @@cache==nil || @@cache[3]<Time.now.to_i-30
erequest("forum", {}, true) do |resp|
if resp.is_a?(Hash)
if resp["code"] != 200
$j=resp
UI.alert(:title => _("Error occurred"), :message => resp["errmsg"]||resp["code"].to_s ) { }
else
@@cache=[resp['groups'], resp['forums'], resp['threads'], Time.now.to_i]
build(*@@cache[0..2])
block.call if block != nil
end
end
end
else
build(*@@cache[0..2])
block.call if block != nil
end
end
end

class Struct_ForumGroup < Struct_MTLFContainer
attr_accessor :cnt_forums
attr_accessor :cnt_threads
attr_accessor :cnt_posts
attr_accessor :cnt_readposts
attr_accessor :public
attr_accessor :open
attr_accessor :recommended
attr_accessor :role
def initialize(s)
raise(ArgumentError, "hash was expected") if !s.is_a?(Hash)
super
@id=s['id'].to_i
@name=s['name']
@author=s['founder']
@cnt_forums = s['cnt_forums'].to_i
@cnt_threads = s['cnt_threads'].to_i
@cnt_posts = s['cnt_posts'].to_i
@cnt_readposts = s['cnt_readposts'].to_i
@open=(s['open'].to_i==1)
@public=(s['public'].to_i==1)
@recommended=(s['recommended'].to_i==1)
@role=s['role'].to_i
@readable=((@role==1||@role==2)||@public)
if $session!=nil and $session.name==@author
@editable=true
@writable=true
end
end
def to_s
return [
@name,
_("Forums: %{cnt}", 'cnt'=>@cnt_forums),
_("Threads: %{cnt}", 'cnt'=>@cnt_threads),
_("Posts: %{cnt}", 'cnt'=>@cnt_posts),
_("New: %{newposts}", 'newposts'=>(@cnt_posts-@cnt_readposts))
].join(", ")
end
def get
return @children
end
def enum_members(getlast=false, &b)
erequest("forum/groups", { "ac" => "members", "groupid" => @id.to_s }) { |rsp|
if rsp['code']!=200
UI.alert(:title => _("Error"), :message => rsp["errmsg"], :default => "Cancel") { }
else
for m in rsp["members"]
next if m['user']==""||m['user']==" "||m['user']==nil
b.call(m['user'], m['role'].to_i)
end
b.call(:last) if getlast
end
}
end
def refresh(&block)
@parent.refresh(&block) if @parent!=nil
end
end

class Struct_ForumForum < Struct_MTLFContainer
attr_accessor :cnt_threads
attr_accessor :cnt_posts
attr_accessor :cnt_readposts
attr_accessor :type
attr_accessor :closed
def initialize(s)
super
if s.is_a?(Hash)
@id=s['id']
@name=s['name']
@pos=s['pos'].to_i
@type=s['type'].to_i
@closed=(s['closed'].to_i==1)
@cnt_threads = s['cnt_threads'].to_i
@cnt_posts = s['cnt_posts'].to_i
@cnt_readposts = s['cnt_readposts'].to_i
if @type==0
@creation_types=[:text]
elsif @type==1
@creation_types=[:audio]
elsif @type==2
@creation_types=[:audio, :text]
end
elsif s == :followedthreads
@id=-1
@name=_("Followed threads")
@pos=-1
@type=-1
@cnt_threads=0
@cnt_posts=0
@cnt_readposts=0
@closed=false
@editable=false
@writable=false
@closed=false
else
raise(ArgumentError, "wrong constructor data")
end
end
def parent=(p)
@parent=p
if @parent.is_a?(Struct_ForumGroup)
@editable=@parent.editable
@writable=((@parent.public&&@parent.open)||(@parent.role==1||@parent.role==2))&&!@closed
end
end
def to_s
return [
@name,
_("Threads: %{cnt}", 'cnt'=>@cnt_threads),
_("Posts: %{cnt}", 'cnt'=>@cnt_posts),
_("New: %{newposts}", 'newposts'=>(@cnt_posts-@cnt_readposts))
].join(", ")
end
def get
return @children
end
def refresh(&block)
@parent.refresh(&block) if @parent!=nil
end
end

class Struct_ForumThread < Struct_MTLFContainer
attr_accessor :cnt_posts
attr_accessor :cnt_readposts
attr_accessor :type
attr_accessor :closed
attr_accessor :pinned
attr_accessor :followed
def initialize(s)
super
raise(ArgumentError, "hash was expected") if !s.is_a?(Hash)
@id=s['id'].to_i
@name=s['name']
@author=s['author']
@date=s['lastupdate'].to_i
@type=0
@creation_types = [:text]
@cnt_posts = s['cnt_posts'].to_i
@cnt_readposts = s['cnt_readposts'].to_i
@pinned=(s['pinned'].to_i==1)
@closed=(s['closed'].to_i==1)
@followed=(s['followed'].to_i==1)
end
def parent=(p)
@parent=p
if @parent.is_a?(Struct_ForumForum)
@type=@parent.type
@creation_types = [:audio] if @type==1
@creation_types = [:audio, :text] if @type==2
@editable=@parent.editable
@writable = @parent.writable && !@closed
end
end
def to_s
return [
((@cnt_posts>@cnt_readposts)?("("+_("New")+")"):(""))+@name,
_("Author: %{author}", "author"=>@author),
_("Posts: %{cnt}", 'cnt'=>@cnt_posts),
_("New: %{newposts}", 'newposts'=>(@cnt_posts-@cnt_readposts))
].join(", ")
end
def refresh(&block)
erequest("forum/#{@id.to_s}", {}, true) { |resp|
if resp.is_a?(Hash)
if resp["code"] != 200
UI.alert({ :title => _("Error occurred"), :message => resp["errmsg"] }) { }
else
resp['posts'].each {|post|
ps=fetch(Struct_ForumPost, post)
ps.unread=true if @children.size>@cnt_readposts
}
sort_id!
@cnt_readposts=@cnt_posts=count
block.call if block!=nil
end
end
}
end
end

class Struct_ForumPost < Struct_MTLFEntry
attr_accessor :type
def initialize(s)
raise(ArgumentError, "hash was expected") if !s.is_a?(Hash)
super
@id=s['id'].to_i
@author=s['author']
@date=s['date']
@value=s['post']
@type=0
if s['audio_url']!=nil
@type=1
@resource_type = :audio
@resource=s['audio_url']
end
if $session!=nil
@editable=true if @author==$session.name
end
end
def to_s
return (@unread?("("+_("New")+") "):"")+@author+":\n"+@value+"\n"+@date.to_s
end
def parent=(pa)
@parent=pa
if @parent.is_a?(Struct_ForumForum)
@editable=true if @parent.editable
@writable=@parent.writable
end
end
end