module UI
  class Switch < Control
    include Eventable

def initialize(label="")
@label=label
super
end

    def checked=(b)
      proxy.setOn(b, animated: false)
    end

def checked
proxy.isOn
end

def on_change
trigger(:change)
end

    def proxy
      @proxy ||= begin
          ui_switch = UISwitch.alloc.init
          ui_switch.translatesAutoresizingMaskIntoConstraints = false
          ui_switch.addTarget(self, action: :on_change, forControlEvents: UIControlEventValueChanged)
ui_switch.accessibilityLabel=@label

          ui_switch
        end
    end
  end
end
