module UI
  class TabBar < View
    include Eventable

    def initialize
      super
      proxy
    end

    def tabBar(tabBar, didSelectItem: item)
    end

    attr_reader :items

    def items=(itm)
      @items = itm
      proxy.setItems([itm[0].proxy])
    end

    def proxy
      @proxy ||= begin
        tabbar = UITabBar.alloc.init
        tabbar.delegate = self
        tabbar.sizeToFit

        tabbar
      end
    end
  end

  class TabBarItem < View
    def initialize(title = "")
      @title = title
    end

    def proxy
      @proxy ||= begin
        tabbaritem = UITabBarItem.alloc.init
        tabbaritem.setTitle(@title)
        tabbaritem
      end
    end
  end
end
