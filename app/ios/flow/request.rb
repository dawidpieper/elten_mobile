module Net
  class Request
    extend Actions
    include Request::Stubbable

    def build_body(body)
      return body if body.is_a?(NSData)
      (json? and body != "") ? body.to_json.dataUsingEncoding(NSUTF8StringEncoding) : body.dataUsingEncoding(NSUTF8StringEncoding)
    end
  end
end
