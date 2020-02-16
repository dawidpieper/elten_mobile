module UI
  module Eventable
    alias trg trigger

    def trigger(event, *args)
      return if event == nil
      trg(event, *args)
    end
  end
end
