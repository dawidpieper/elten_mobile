module UI
  class Application
    def tabbars(labels, navigations)
      @tabbar = UI::TabBar.new
      vc = []
      for i in 0...navigations.size
        navigations[i].proxy.tabBarItem = UITabBarItem.alloc.initWithTitle(labels[i], image: nil, tag: i)
        vc.push(navigations[i].proxy)
      end
      @tabbar.proxy.viewControllers = vc
      self.navigation.replace(@tabbar)
    end
  end
end
