module UI
  class View < CSSNode
    def scale(sclx, scly)
      transform = CGAffineTransformMakeScale(sclx, scly)
      proxy.transform = transform
    end
  end
end
