# An abstract class representing Maze of Twisty Little Forums  - all forum-like structures
class Struct_MTLFContainer
# Represents whether user can read elements
attr_accessor :readable
# Represents whether user can add elements
attr_accessor :writable
# determines whether object can be edited by user
attr_accessor :editable
# determines whether object is associated with user profile
attr_accessor :profilable
# object parent
attr_accessor :parent
# object id
attr_accessor :id
# Object name
attr_accessor :name
# object creator, administrator etc.
attr_accessor :author
# MaxID used when updating
attr_accessor :maxid
# virtual position
attr_accessor :pos
# date of modification or creation
attr_accessor :date
# determines if model is searchable
attr_accessor :searchable
# Selected category
attr_accessor :category
# creation types
attr_accessor :creation_types

def inspect
return "MTLF Object of type #{self.class.to_s}: id: #{@id}, name: #{@name}, children: #{count}"
end

def to_s
return @name
end

def initialize(*arg)
@id=0
@children=[]
@screens=[]
@readable=true
@writable=false
@editable=false
@profilable=false
@author=""
@name=""
@date=0
@maxid=0
@pos=0
@searchable=false
@category=0
@creation_types = []
end

def subregister(depth, o);end

def setcategory(cat)
end

def get
return @children
end
def add(item)
raise(ArgumentError, "item is not MTLF") if !item.is_a?(Struct_MTLFContainer)
@children.push(item)
end
def delete(item)
@children.delete(item)
end
def delete_at(index)
@children.delete_at(index)
end
def include?(item)
@children.include?(item)
end

def write(*arg)
return if !@writable
end
def edit(*arg)
return if !@writable
end

def refresh(&block)
end

def categories
return []
end

def count
@children.size
end
def reverse!
@children.reverse!
end
def sort_date!
@children.sort! {|a,b|
if a.is_a?(Symbol) or a==nil
a
elsif b.is_a?(Symbol) or b==nil
b
else
a.date<=>b.date
end
}
end
def sort_id!
@children.sort! {|a,b|
if a.is_a?(Symbol) or a==nil
a
elsif b.is_a?(Symbol) or b==nil
b
else
a.id<=>b.id
end
}
end
def sort_pos!
@children.sort! {|a,b|
if a.is_a?(Symbol) or a==nil
a
elsif b.is_a?(Symbol) or b==nil
b
else
a.pos<=>b.pos
end
}
end
def clear
@children.clear
end

def fetch(cls, *arg)
child=cls.new(*arg)
child.parent=self
for i in 0...@children.size
if @children[i].id==child.id
@children[i]=child
return child
end
end
add(child)
i=0
pr=self
while pr!=nil
pr.subregister(i, child)
i+=1
pr=pr.parent
end
return child
end

def final?
@children.each {|ch| return true if ch.is_a?(Struct_MTLFEntry)}
return false
end
end

# Represents an entry
class Struct_MTLFEntry < Struct_MTLFContainer
# entry value
attr_accessor :value
# resource associated with this entry
attr_accessor :resource
# Determines if entry unread
attr_accessor :unread
# resource type
attr_accessor :resource_type

def initialize(*arg)
super
@unread=false
@resource_type = :text
end
end