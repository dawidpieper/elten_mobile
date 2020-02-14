module UI
  class Button < Control
    include Eventable

    def enabled=(b)
      proxy.enabled = b
    end

    def on_touchdown
      trigger(:touchdown)
    end

    def proxy
      @proxy ||= begin
          ui_button = UIButton.buttonWithType(UIButtonTypeCustom)
          ui_button.translatesAutoresizingMaskIntoConstraints = false
          ui_button.addTarget(self, action: :on_tap, forControlEvents: UIControlEventTouchUpInside)
          ui_button.addTarget(self, action: :on_touchdown, forControlEvents: UIControlEventTouchDown)

          ui_button
        end
    end
  end
end
