# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class Scene_Forum < Scene_MTLF

def initialize(model=nil)
@model=model
@model = Struct_ForumRoot.new if @model==nil
@controller = Control_Forum.new(self, @model)
end




end