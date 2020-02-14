module Net
  class Response
    attr_accessor :options, :mock

    def status
      return nil if options == nil
      options[:status_code]
    end

    def status_message
      return nil if options == nil
      options[:status_message]
    end

    def mime_type
      return nil if options == nil
      options[:mime_type]
    end

    def body
      return nil if options == nil
      options.fetch(:body, "")
    end

    def headers
      @headers
    end
  end
end
