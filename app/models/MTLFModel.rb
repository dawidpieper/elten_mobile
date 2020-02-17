# An abstract class representing Maze of Twisty Little Forums  - all forum-like structures
class Struct_MTLFContainer
# Represents whether user can add elements
attr_accessor :writable
# determines whether object can be edited by user
attr_accessor :editable
# object parent
attr_accessor :parent
# object id
attr_accessor :id
# Object name
attr_accessor :name
# object creator, administrator etc.
attr_accessor :author
# determines whether object should be considered as new
attr_accessor :unread
# MaxID used when updating
attr_accessor :maxid
# virtual position
attr_accessor :pos
# date of modification or creation
attr_accessor :date

def inspect
return "MTLF Object of type #{self.class.to_s}: id: #{@id}, name: #{@name}, children: #{count}"
end

def initialize(*arg)
@children=[]
@writable=false
@editable=false
@unread=false
@author=""
@name=""
@date=0
@maxid=0
@pos=0
end

def add(item)
raise(ArgumentError, "item is not MTLF") if !item.is_a?(Struct_MTLFContainer)
item.parent=self
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

def refresh
fetch_data
end

def count
@children.size
end
def reverse!
@children.reverse!
end
def sort_date!
@children.sort! {|a,b| a.date<=>b.date}
end
def sort_id!
@children.sort! {|a,b| a.id<=>b.id}
end
def sort_pos!
@children.sort! {|a,b| a.pos<=>b.pos}
end
def clear
@children.clear
end

private
def fetched(cls, *arg)
child=cls.new(*arg)
for item in @children
return child if item.id==child.id
end
add(child)
return child
end
def fetch_data
end
end

# Represents an entry
class Struct_MTLFEntry < Struct_MTLFContainer
# Entry date
attr_accessor :date
# entry value
attr_accessor :value
# resource associated with this entry
attr_accessor :resource

def initialize(*arg)
super

end
end