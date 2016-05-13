module Multipart
  require 'rubygems'
  require 'mime/types'
  require 'net/http'
  require 'cgi'

  class Param
    attr_accessor :k, :v
    def initialize(k, v)
      @k = k
      @v = v
    end

    def to_multipart
      return "Content-Disposition: form-data; name=\"#{k}\"\r\n\r\n#{v}\r\n"
    end
  end

  class FileParam
    attr_accessor :k, :filename, :content
    def initialize( k, filename, content )
      @k = k
      @filename = filename
      @content = content
    end

    def to_multipart
      return "Content-Disposition: form-data; name=\"#{k}\"; filename=\"#{filename}\"\r\n" +
        "Content-Transfer-Encoding: binary\r\n" +
        "Content-Type: #{MIME::Types.type_for(@filename)}\r\n\r\n" + content + "\r\n"
    end
  end

  class MultipartPost
    BOUNDARY = 'tarsiers-rule0000'
    HEADER = {"Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " "}

    def prepare_query (params)
      fp = []
      params.each {|k,v|
        if v.respond_to?(:read)
          fp.push(FileParam.new(k, v.path, v.read))
        else
          fp.push(Param.new(k,v))
        end
      }
      query = fp.collect {|p| "--" + BOUNDARY + "\r\n" + p.to_multipart }.join("") + "--" + BOUNDARY + "--"
      return query, HEADER
    end
  end
end
