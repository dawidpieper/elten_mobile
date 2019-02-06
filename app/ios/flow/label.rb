module UI
  class Label < View
    include UI::SharedText

    def header=(isHeader)
      proxy.accessibilityTraits = ((isHeader == true) ? UIAccessibilityTraitHeader : UIAccessibilityTraitNone)
    end
  end
end
