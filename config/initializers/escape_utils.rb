if Rails.env == 'test' 
  module Rack
    module Utils
      def escape(s)
        EscapeUtils.escape_url(s)
      end
    end
  end

  require "escape_utils/html/rack"
end