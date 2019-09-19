module Net
  class Request
    extend Actions
    include Request::Stubbable

    def run(&callback)
      return if stub!(&callback)

      Task.background do
        handler = lambda { |body, response, error|
          if response.nil? && error
		  $conn_failed=true
#            raise error.localizedDescription
          end
          Task.main do
            callback.call(ResponseProxy.build_response(body, response))
          end
        }
        task = ns_url_session.dataTaskWithRequest(ns_mutable_request,
                                                  completionHandler:handler)
        task.resume
      end
    end

    def build_body(body)
	return body if body.is_a?(NSData) or body.is_a?(NSConcreteData)
      (json? and body != '') ? body.to_json.dataUsingEncoding(NSUTF8StringEncoding) : body.dataUsingEncoding(NSUTF8StringEncoding)
    end

    end

    end