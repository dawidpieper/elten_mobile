module UI
  class Controller < UIViewController
    include Eventable

    attr_accessor :navigation

    def initWithScreen(screen)
      if init
        @screen = screen
        on(:view_did_load) { @screen.before_on_load }
        on(:view_will_appear) { @screen.before_on_show }
        on(:view_did_appear) { @screen.on_show }
        on(:view_will_disappear) { @screen.before_on_disappear }
      end
      self
    end

    def viewWillDisappear(animated)
      super
      trigger(:view_will_disappear)
    end
  end

  class Screen
    def before_on_disappear; end
  end
end
