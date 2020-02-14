module Net
  class ResponseProxy
    private

    def status_message
      return nil if @response == nil
      message = CFHTTPMessageCreateResponse(KCFAllocatorDefault,
                                            @response.statusCode, nil, KCFHTTPVersion1_1)
      CFHTTPMessageCopyResponseStatusLine(message)
    end

    def headers
      return nil if @response == nil
      @response.allHeaderFields
    end

    def mime_type
      return nil if @response == nil
      @response.MIMEType
    end

    def status_code
      return nil if @response == nil
      @response.statusCode
    end
  end
end
