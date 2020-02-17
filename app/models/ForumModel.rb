class Struct_ForumRoot < Struct_MTLFContainer
def initialize
super
end
def get
sgroups=[]
@children.each {|g|
sgroups.push(g) if g.recommended||g.role==1||g.role==2
}
return sgroups
end
def get_recommended
sgroups=[]
@children.each {|g|
sgroups.push(g) if g.recommended
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
def build(&block)
erequest("forum/struct", { "cat" => "groups", "listgroups"=>"all" }, true) do |resp|
if resp.is_a?(Hash)
if resp["code"] != 200
UI.alert({ :title => _("Error occurred"), :message => resp["errmsg"] }) { }
else
clear
resp["groups"].values.each { |g|
fetched(Struct_ForumGroup, g).subbuild(resp["forums"].values, resp["threads"].values)
}
sort_id!
block.call if block != nil
end
end
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
if $session!=nil and $session.name==@author
@editable=true
@writable=true
end
end
def get
return @children
end
def build(&block)
@parent.build(&block) if @parent!=nil
end
def subbuild(forums,threads)
forums.each {|f|
fetched(Struct_ForumForum, f).subbuild(threads) if f['groupid'].to_i==@id
}
sort_pos!
end
end

class Struct_ForumForum < Struct_MTLFContainer
attr_accessor :cnt_threads
attr_accessor :cnt_posts
attr_accessor :cnt_readposts
attr_accessor :type
def initialize(s)
raise(ArgumentError, "hash was expected") if !s.is_a?(Hash)
super
@id=s['id']
@name=s['name']
@pos=s['pos'].to_i
@type=s['type'].to_i
@cnt_threads = s['cnt_threads'].to_i
@cnt_posts = s['cnt_posts'].to_i
@cnt_readposts = s['cnt_readposts'].to_i
if @parent.is_a?(Struct_ForumGroup)
@editable=@parent.editable
@writable=(@parent.public&&@parent.open)||(@parent.role==1||@parent.role==2)
end
end
def get
return @children
end
def build(&block)
@parent.build(&block) if @parent!=nil
end
def subbuild(threads)
threads.each {|t|
fetched(Struct_ForumThread, t) if t['forumid']==@id
}
sort_date!
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
@cnt_posts = s['cnt_posts'].to_i
@cnt_readposts = s['cnt_readposts'].to_i
@closed=(s['closed'].to_i==1)
@pinned=(s['pinned'].to_i==1)
@followed=(s['followed'].to_i==1)
if @parent.is_a?(Struct_ForumForum)
@type=@parent.type
@editable=@parent.editable
@writable = @parent.writable && !@closed
end
end
def build(&block)
@parent.build(&block) if @parent!=nil
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
@resource=s['audio_url']
end
if $session!=nil
@editable=true if @author==$session.name
end
if @parent.is_a?(Struct_ForumForum)
@editable=true if @parent.editable
@writable=@parent.writable
end
end
end