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
@lst_list.height=@lst_list.height*0.85
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
@btn_compose.on(:tap) {@controller.compose}
end
upd=true if show(@btn_compose, @model.writable)
end
self.view.update_layout if upd
end

def update_data(shouldClear=false)
@lst_list.refresh_begin if !@lst_list.refreshing?
if @items==nil or shouldClear
@items=@model.get
$it=@items
@lst_list.data_source = @items.map{|item| item.to_s}
@lst_list.refresh
@lst_list.setFocus
elsif @items.size<(m=@model.get).size
@lst_list.update_begin
for i in 0...m.size
if !@items.include?(m[i])
@items.insert(i,m[i])
@lst_list.insert(i,m[i].to_s)
end
end
@lst_list.update_end
end
@lst_list.refresh_end
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
@controller.dispose
end

def on_show
self.navigation.title = @model.name
@controller.show
end
end
