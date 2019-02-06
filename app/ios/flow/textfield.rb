module UI
  class TextInput < Control
    include Eventable

    attr_reader :numbers

    def numbers=(nmb)
      @numbers = nmb
      proxy.setKeyboardType(((nmb == true) ? (UIKeyboardTypePhonePad) : (UIKeyboardTypeDefault)))
    end

    def textFieldShouldReturn(textField)
      @returns.each { |b| b.call }
    end

    def enter(&block)
      proxy.returnKeyType = UIReturnKeySend
      @returns ||= []
      @returns.push(block)
    end
  end
end
