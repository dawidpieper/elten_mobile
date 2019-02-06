module UI
  class Text < View
    include Eventable

    attr_reader :placeholder

    alias initializer initialize

    def initialize
      @focus_events = []
      @change_events = []
      @blur_events = []
      @placeholder = ""
      initializer
    end

    def hasText
      proxy.hasText
    end

    def isEditing
      proxy.isEditing
    end

    def on(event, &block)
      case event
      when :change
        @change_events.push(block)
      when :focus
        @focus_events.push(block)
      when :blur
        @blur_events.push(block)
      end
      super
    end

    def textViewDidBeginEditing(textView)
      @proxy.becomeFirstResponder
      @focus_events.each { |e|
        e.call
      }
    end

    def textViewDidEndEditing(textView)
      @proxy.resignFirstResponder
      @blur_events.each { |e|
        e.call
      }
    end

    def textViewDidChange(textView)
      @change_events.each { |e|
        e.call
      }
    end

    def placeholder=(plc)
      @placeholder = plc
      proxy.accessibilityLabel = plc + ":\r\n" + text
    end

    alias texter text=

    def text=(txt)
      texter(txt)
    end

    def textView(view, shouldChangeCharactersInRange: range, replacementString: string)
      @date_picker
    end

    def textView(view, shouldInteractWithURL: url, inRange: range)
      false
    end

    def proxy
      @proxy ||= begin
        view = UITextView.alloc.init
        view.delegate = self
        view.frame = CGRectMake(0, 0, 200, 150)
        view.translatesAutoresizingMaskIntoConstraints = false

        view.setSelectable(true)
        view.setScrollingEnabled(true)
        view.setPagingEnabled(true)
        view.editable = true
        view.sizeToFit
        view.backgroundColor = UIColor.grayColor
        view.userInteractionEnabled = true
        view
      end
    end
  end

  class StaticText < View
    include UI::SharedText
    include Eventable

    def editable=(flag)
      proxy.editable = flag
    end

    def editable?
      proxy.editable
    end

    attr_reader :link_color

    def link_color=(color)
      if @link_color != color
        @link_color = color
        proxy.linkTextAttributes = {NSForegroundColorAttributeName => UI.Color(color).proxy}
      end
    end

    def links=(links)
      at = proxy.attributedText.mutableCopy

      links.each do |range, link|
        range = [range.begin, range.end - range.begin]
        at.addAttribute(NSLinkAttributeName, value: _add_link(link), range: range)
        at.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: range)
      end

      proxy.attributedText = at
      proxy.dataDetectorTypes = UIDataDetectorTypeLink
    end

    def _add_link(value)
      @links ||= {}
      link = "link#{@links.size}"
      @links[link] = value
      NSURL.URLWithString(link + "://")
    end

    def textView(view, shouldInteractWithURL: url, inRange: range)
      if @links and value = @links[url.scheme]
        trigger :link, value
        false
      else
        true
      end
    end

    def proxy
      @proxy ||= begin
        view = UITextView.alloc.init
        view.delegate = self
        view.editable = false
        view.selectable = false
        view.scrollingEnabled = true
        view.sizeToFit
        view
      end
    end
  end
end
