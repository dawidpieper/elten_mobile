class Scene_MTLFCreator < UI::Screen
def initialize(title="")
@title=title
@ids=[]
@items=[]
@heights=[]
end
def on_load
    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    label = UI::Label.new
    label.text = @title
    label.height = self.view.height * 0.1
    label.header = true
    @background.add_child(label)
end
def add_item(item, id, height)
@ids.push(id)
item.height=self.view.height*height
@background.add_child(item)
@items.push(item)
@heights.push(item.height)
end
def add_edit(title, id, height=0.1)
item = UI::TextInput.new
item.placeholder=title
item.on(:focus) {setscale(true)}
item.on(:blur) {setscale(false)}
add_item(item, id, height)
end
def setscale(s=true)
return if @scaled==s
@scaled=s
if s==true
@background.scale(1,0.5)
elsif s==false
@background.scale(1,1)
end
end
def create
item = UI::TextView.new
item.placeholder=title
item.on(:focus) {setscale(true)}
item.on(:blur) {setscale(false)}
add_item(item, nil, self.view.height-@heights.sum-0.15)
cancel_button = UI::Button.new
cancel_button.title = _("Cancel")
cancel_button.height = self.view.height * 0.05
@background.add_child(cancel_button)
cancel_button.on :tap {
if @items[-1].text==""
self.navigation.pop
else
UI.alert({ :title => _("Are you sure you want to cancel the creation of new thread?"), :message => _("All the typed text will be lost."), :cancel => _("No"), :default => _("Yes") }) { |ind|
self.navigation.pop if ind == :default
}
end
}
self.view.update_layout
end
def on_show
self.navigation.title=@title
self.navigation.hide_bar if !self.navigation.bar_hidden?
end
end