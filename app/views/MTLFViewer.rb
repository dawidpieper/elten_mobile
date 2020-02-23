class Scene_MTLFViewer < UI::Screen
def initialize(model)
@model=model
end
def on_load
    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

@text = UI::StaticText.new
@text.height = self.view.height*0.9
@text.text=@model.value||""
@background.add_child(@text)

self.view.update_layout
end
def on_show
title=@model.name
title=@model.author if title==""
self.navigation.title=title
end
end