class Scene_UsersList < UI::Screen
def initialize(controller=nil, title=nil)
@controller=controller
@title=title
    @list = UI::List.new
@users = []
end

  def on_show
    self.navigation.title = @title
  end

  def on_load
    $screen = self

    @background = UI::View.new
    @background.flex = 1
    @background.margin = 5
    @background.background_color = :white
    self.view.add_child(@background)

    @list.height = self.view.height
    @background.add_child(@list)

self.view.update_layout
  end

def adduser(user, text="")
@users.push(user)
@list.add(user+"\r\n"+text)
end

def refresh
@list.refresh
end
end