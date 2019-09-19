module UI
  class TabBar < UITabBarController
    include Eventable

attr_accessor :navigation

    def initialize
      super
      proxy
    end

    def tabBar(tabBar, didSelectItem: item)
    end

attr_reader :items

    def proxy
      @proxy ||= begin
        tabbar = UITabBarController.alloc.init

        tabbar
      end
    end
  end

  class TabBarItem < View
    def initialize(title = "",tag=0)
      @title,@tag = title,tag
super
proxy
    end

    def proxy
      @proxy ||= begin
        tabbaritem = UITabBarItem.alloc.init
        tabbaritem.setTitle(@title)
tabbaritem.setTag(@tag)



        tabbaritem
      end
    end
  end
end
