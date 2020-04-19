# -*- coding: utf-8 -*-

# ELTEN Mobile Code
# Copyright (C) Dawid Pieper
# This file and entire code are licensed under Open Public License
# For detailed information, refer to 'license.md' file

class Scene_Messages < Scene_MTLF

def initialize(model=nil)
@model=model
@model = Struct_MessagesRoot.new if @model==nil
@controller = Control_Messages.new(self, @model)
end

end