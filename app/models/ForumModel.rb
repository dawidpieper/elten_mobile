class Struct_ForumRoot < Struct_MTLFContainer
attr_accessor :category
def initialize
super
@name=_("Forum")
@category=0
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
def refresh(&block)
play 'signal'
erequest("forum/struct", { "cat" => "groups", "listgroups"=>"all" }, true) do |resp|
if resp.is_a?(Hash)
if resp["code"] != 200
UI.alert({ :title => _("Error occurred"), :message => resp["errmsg"] }) { }
else
if @followdthreads==nil
@followedthreads = Struct_ForumForum.new(:followedthreads)
@followedthreads.parent=self
end
@followedthreads.cnt_threads=0
@followedthreads.cnt_posts=0
@followedthreads.cnt_readposts=0
resp['threads'].values.each {|t|
if t['followed'].to_i==1
ch=@followedthreads.fetch(Struct_ForumThread, t)
@followedthreads.cnt_threads+=1
@followedthreads.cnt_posts+=ch.cnt_posts
@followedthreads.cnt_readposts+=ch.cnt_readposts
g=resp['groups'][t['id'].to_i]
if g!=nil
ch.writable=true if g['role'].to_i==1 or g['role'].to_i==2 or (g['open'].to_i==1 and g['public'].to_i==1)
ch.editable=true if g['role'].to_i==2
end
end
}
@followedthreads.sort_date!
@followedthreads.reverse!
resp["groups"].values.each { |g|
fetch(Struct_ForumGroup, g).subbuild(resp["forums"].values, resp["threads"].values)
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
if @to_subbuild!=nil
forums,threads = @to_subbuild
forums.each {|f|
fetch(Struct_ForumForum, f).subbuild(threads) if f['groupid'].to_i==@id
}
sort_pos!
@to_subbuild=nil
end
return @children
end
def refresh(&block)
@parent.refresh(&block) if @parent!=nil
end
def subbuild(forums,threads)
@to_subbuild=[forums,threads]
end
end

class Struct_ForumForum < Struct_MTLFContainer
attr_accessor :cnt_threads
attr_accessor :cnt_posts
attr_accessor :cnt_readposts
attr_accessor :type
def initialize(s)
super
if s.is_a?(Hash)
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
elsif s == :followedthreads
@id=-1
@name=_("Followed threads")
@pos=-1
@type=-1
@cnt_threads=0
@cnt_posts=0
@cnt_readposts=0
@editable=false
@writable=false
else
raise(ArgumentError, "wrong constructor data")
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
if @to_subbuild!=nil
threads=@to_subbuild
if @id!=-1
threads.each {|t|
fetch(Struct_ForumThread, t) if t['forumid']==@id
}
end
sort_date!
reverse!
@to_subbuild=nil
end
return @children
end
def refresh(&block)
@parent.refresh(&block) if @parent!=nil
end
def subbuild(threads)
@to_subbuild=threads
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
def to_s
return [
@name,
_("Posts: %{cnt}", 'cnt'=>@cnt_posts),
_("New: %{newposts}", 'newposts'=>(@cnt_posts-@cnt_readposts))
].join(", ")
end
def refresh(&block)
@parent.refresh(&block) if @parent!=nil
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