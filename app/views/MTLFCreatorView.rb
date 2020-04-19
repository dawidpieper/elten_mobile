class Scene_MTLFCreator < UI::Screen
def initialize(model, controller, fields={}, title="", posttitle="")
@title=title
@posttitle=posttitle
@model=model
@controller=controller
@fields=fields
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

@fields.each{|f|
add_field(f[0], f[1], f[2]||0.1)
}
if @model.creation_types.include?(:text)
item = @edit_text = UI::Text.new
item.placeholder=@posttitle
item.on(:focus) {setscale(true)}
item.on(:blur) {setscale(false)}
item.on(:change) {
if @edit_text.text==""
@btn_send.title=@btn_send_title||_("Send")
else
@btn_send_title=@btn_send.title
@btn_send.title=_("Send")
end
}
sm=0.1
@heights.each{|h| sm+=h}
add_item(item, nil, 1-sm-0.15)
end
cancel_button = UI::Button.new
cancel_button.title = _("Cancel")
cancel_button.height = self.view.height * 0.05
@background.add_child(cancel_button)
cancel_button.on :tap {
if @item_text==nil || @item_text.text==""
self.navigation.pop
else
UI.alert({ :title => _("Are you sure you want to cancel?"), :message => _("All the typed text will be lost."), :cancel => _("No"), :default => _("Yes") }) {|ind|
self.navigation.pop if ind == :default
}
end
}
@btn_send = UI::Button.new
@btn_send.title = _("Send")
@btn_send.title = _("Record") if @model.creation_types.include?(:audio)
@btn_send.height = self.view.height * 0.05
@btn_send.on(:tap) {btn_send}
@background.add_child(@btn_send)
self.view.update_layout
end
def add_item(item, id, height)
@ids.push(id)
item.height=self.view.height*height
@background.add_child(item)
@items.push(item)
@heights.push(height)
end
def add_field(title, id, height=0.1)
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
def btn_send
if @edit_text!=nil and @edit_text.text!=""
send_text
elsif @model.creation_types.include?(:audio)
btn_record
end
end
def btn_record(tap=false)
    if (Recorder.permitted?) == nil
pr=Proc.new{btn_record}
      Recorder.request_permission(pr,pr,pr)
end
if Recorder.permitted? != true
UI.alert(:title => "Error", :message => _("Elten does not have permission to use your microphone. You can change it in your system settings."), :default => "Cancel") {}
return
end
if @recorder==nil and @recording_file==nil
recording_start
elsif @recorder!=nil
recording_stop
else @recording_file!=nil
send_audio
end
end
def recording_start
play("recording_start")
@btn_send.title = _("Stop recording")
@recording_file ||= ENV["TMPDIR"] + "/record.m4a"
File.delete(@recording_file) if FileTest.exists?(@recording_file)
AudioConfig.category_tospeaker = AudioConfig::CategoryPlayAndRecord
@recorder = Recorder.new(@recording_file, Recorder::QualityMedium)
UI.alert(:title => _("Error"), :message => "Cannot initialize recorder") { } if !@recorder.start
end
def recording_stop
@recorder.stop
AudioConfig.category = AudioConfig::CategoryAmbient
@btn_send.title = _("Send")
@recorder = nil
play("recording_stop")
@btn_clear=UI::Button.new
@btn_clear.height=self.view.height*0.05
@btn_clear.title = _("Delete recording")
@btn_clear.on(:tap) {
@recording_file=nil
@btn_send.title=_("Record")
@background.delete_child(@btn_clear)
self.view.update_layout
}
@background.add_child(@btn_clear)
self.view.update_layout
end
def send_text
return if @edit_text==nil || @edit_text.text==""
@controller.compose(@edit_text.text, :text, get_fieldsdata)
end
def get_fieldsdata
h={}
for i in 0...@items.size
if @items[i].is_a?(UI::TextInput)
h[@ids[i]]=@items[i].text
end
end
return h
end
def send_audio
return if @recording_file==nil
@controller.compose(@recording_file, :audio, get_fieldsdata) if @recording_file!=nil
end
def on_show
self.navigation.title=@title
self.navigation.hide_bar if !self.navigation.bar_hidden?
end
def before_on_disappear
@record.stop if @record!=nil
end
end