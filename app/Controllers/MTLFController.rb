# Abstract class for MTFL Controllers
class Control_MTLF
def initialize(view, model)
raise(ArgumentError, "not MTLF struct") if !model.is_a?(Struct_MTLFContainer)
raise(ArgumentError, "not MTLF view") if !view.is_a?(Scene_MTLF)
@model, @view = model, view
end

def refresh
@model.refresh {@view.update}
end

def select(item)
if item.is_a?(Struct_MTLFEntry)
if item.resource_type==:text
@view.navigation.push(Scene_MTLFViewer.new(item))
elsif item.resource_type == :audio
$streamer ||= Player.new
if $streamer.file == item.resource && $streamer.duration>0.1 && $streamer.position!=nil && $streamer.position!=nil && $streamer.position<$streamer.duration
if $streamer.state==Player::StatePlaying
$streamer.pause
else
$streamer.resume
end
else
$streamer.stop if $streamer.duration>0.1
$streamer.play(item.resource)
end
end
elsif item.is_a?(Struct_MTLFContainer) && item.readable
@view.navigation.push(@view.class.new(item))
end
end

def setcategory(cat)
@model.category=cat
@view.update_data(true)
end

def fetch_actions(item)
return {}
end

def show
refresh
end

def dispose
$streamer.stop if $streamer != nil
end

def reset
$streamer.stop if $streamer != nil
end

def compose(*arg);end
end