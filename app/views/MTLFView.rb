# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class Scene_MTLF < UI::Screen

def initialize(model)
@model=model
end

def show(obj, active=true)
@shown=[] if @shown==nil
if @shown.include?(obj) and active==false
@shown.delete(obj)
@background.delete_child(obj)
elsif !@shown.include?(obj) and active==true
@shown.push(obj)
@background.add_child(obj)
end
end

def refresh
@model.refresh {
if @model.categories.size>0
if @pck_categories==nil
@pck_categories = UI::Picker.new
@pck_categories.height=self.view.height*0.1
@lst_list.height=self.view.height*0.65
end
@pck_categories.data_source=@model.categories
end
show(@pck_categories, (@model.categories.size>1))
if @items==nil
@items=@model.get
@lst_list.data_source = @model.get.map{|item| item.to_s}
@lst_list.refresh
elsif @items.size<(m=@model.get).size
@lst_list.update_begin
for i in 0...m.size
item=m[i]
if !@items.include?(item)
@items.push(item)
@lst_list.insert(i,item.to_s)
end
end
@lst_list.update_end
end
show(@lst_list)
self.view.update_layout
}
end

def compose;end
def setcategory(ind);end
  def on_load
super
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

      @btn_refresh = UI::Button.new
      @btn_refresh.height = self.view.height * 0.05
      @btn_refresh.title = _("Refresh")
@btn_refresh.on(:tap) {refresh}
show(@btn_refresh)

    @lst_list = UI::List.new
    @lst_list.margin = [5, 5]
    @lst_list.height = self.view.height * 0.75
@lst_list.on(:select) {|opt,ind| load(ind)}

self.view.update_layout
end

def load(ind)
if @items.size>ind && @items[ind]!=nil
self.navigation.push(self.class.new(@items[ind]))
end
end

def on_show
self.navigation.title = @model.name
refresh
end
end