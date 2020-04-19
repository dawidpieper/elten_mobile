# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class Scene_MTLF < UI::Screen

def initialize(model)
@model=model
@controller = Control_MTLF.new(self, @model)
end

def show(obj, active=true)
@shown=[] if @shown==nil
if @shown.include?(obj) && active==false
@shown.delete(obj)
@background.delete_child(obj)
return true
elsif !@shown.include?(obj) and active==true
@shown.push(obj)
@background.add_child(obj)
return true
end
return false
end

def update(shouldClear=false)
upd=false
if @model.categories.size>0
if @pck_categories==nil
@pck_categories = UI::Picker.new
@pck_categories.height=self.view.height*0.1
@pck_categories.on(:select) {|opt,ind| @controller.setcategory(ind) }
@lst_list.height-=self.view.height*0.1
end
@pck_categories.data_source=@model.categories
end
upd=true if show(@pck_categories, (@model.categories.size>1))
update_data(shouldClear)
upd=true if show(@lst_list)
if @model.writable
if @btn_compose==nil
@btn_compose=UI::Button.new
@btn_compose.height = self.view.height*0.05
@btn_compose.title=_("New")
@btn_compose.on(:tap) {
press_compose
}
end
if @model.final?
if @edit_reply==nil and @model.creation_types.include?(:text)
@edit_reply = UI::Text.new
@edit_reply.height=self.view.height*0.1
@edit_reply.placeholder = _("Your reply")
@edit_reply.on(:focus) {@background.scale(1,0.5)}
@edit_reply.on(:blur) {@background.scale(1,1)}
@edit_reply.on(:change) {edit_reply_change}
@lst_list.height-=self.view.height*0.1
@btn_compose.title = _("Send")
end
if @canrecord==nil and @model.creation_types.include?(:audio)
@canrecord=true
@btn_compose.title = _("Record")
@btn_compose.on(:touchdown) {
if !@model.creation_types.include?(:text) or (@edit_reply!=nil and @edit_reply.text=="")
btn_record(false)
end
}
end
upd=true if @edit_reply!=nil and show(@edit_reply, @model.writable)
end
upd=true if show(@btn_compose, @model.writable)
end
self.view.update_layout if upd
end

def update_data(shouldClear=false)
@lst_list.refresh_begin if !@lst_list.refreshing?
if @items==nil or shouldClear
@items=@model.get
@lst_list.data_source = @items.map{|item| item.to_s}
for i in 0...@items.size
@lst_list.actions[i] = map_actions(i, @items[i])
end
@lst_list.refresh
@lst_list.setFocus
else
m=@model.get
@lst_list.update_begin
for i in 0...m.size
@items[i]=m[i]
a=map_actions(i, m[i])
@lst_list.edit(i,m[i].to_s,a)
end
@lst_list.update_end
end
@lst_list.refresh_end
end

def map_actions(i, item)
return if @lst_list==nil
acs={}
ac=@controller.fetch_actions(item)
for k in ac.keys
acs[k] = makeacproc(k, ac[k])
end
return acs
end

def makeacproc(k, v)
return Proc.new {|opt, row|
ind=row.row
$vvv=v
$iii=@items[ind]
$c=@controller
@controller.send(v, @items[ind]) if @items[ind]!=nil
}
end

  def on_load
super
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    @lst_list = UI::List.new
    @lst_list.margin = [5, 5]
    @lst_list.height = self.view.height * 0.8
@lst_list.refresh_enable
@lst_list.on(:select) {|opt,ind|  @controller.select(@items[ind]) if @items!=nil }
@lst_list.on(:refresh) {@controller.refresh}

self.view.update_layout
end

def before_on_disappear
recording_stop if @recorder!=nil
@controller.dispose
end

def reset
if @edit_reply!=nil
@edit_reply.text=""
edit_reply_change
end
end

def press_compose
arg=[]
if @model.final?
if @model.creation_types.include?(:text) and @edit_reply!=nil and @edit_reply.text!=""
arg=[@edit_reply.text, :text]
elsif @recorder!=nil
btn_record(true)
return
end
end
@controller.compose(*arg)
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
if tap==false
recording_start
@recording_time=Time.now.to_f
elsif @recording_time!=nil
recording_stop
tim=Time.now.to_f-@recording_time
@recording_time=nil
if tim<0.5
UI.alert(:title => _("Information"), :message => _("Hold this button to record message, release it once record is completed."), :default => "Ok") { }
else
recording_send
end
end
end

def edit_reply_change
if @edit_reply.text=="" and @empty_btn_compose_label!=nil
@btn_compose.title=@empty_btn_compose_label
@empty_btn_compose_label=nil
elsif @edit_reply.text!=""
@empty_btn_compose_label=@btn_compose.title
@btn_compose.title=_("Send")
end
end

def recording_start
play("quickrecording_start")
if @btn_cancel == nil
@btn_cancel = UI::Button.new
@btn_cancel.title = _("Cancel recording")
@btn_cancel.height = self.view.height * 0.02
@btn_cancel.on(:tap) { recording_stop }
end
show(@btn_cancel, true)
@btn_compose.title = _("Stop recording")
@recording_file ||= ENV["TMPDIR"] + "/record.m4a"
File.delete(@recording_file) if FileTest.exists?(@recording_file)
AudioConfig.category_tospeaker = AudioConfig::CategoryPlayAndRecord
@recorder = Recorder.new(@recording_file, Recorder::QualityMedium)
UI.alert(:title => _("Error"), :message => "Cannot initialize recorder") { } if !@recorder.start
end

def recording_stop
@recorder.stop
AudioConfig.category = AudioConfig::CategoryAmbient
@btn_compose.title = _("Record")
show(@btn_cancel, false)
@recorder = nil
play("quickrecording_stop")
end

def recording_send
@controller.compose(@recording_file, :audio) if @recording_file!=nil
end

def on_show
self.navigation.title = @model.name
self.navigation.show_bar if self.navigation.bar_hidden?
@controller.show
end
end
