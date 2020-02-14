class Task
  class Queue
    @@counter = 0

    def initialize
      @queue = Dispatch::Queue.new("eu.elten-net.eltenmobile.queue#{@@counter += 1}")
    end
  end
end
