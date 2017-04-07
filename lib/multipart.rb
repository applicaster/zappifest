module Multipart
  require 'rubygems'
  require 'mime/types'
  require 'net/http'
  require 'cgi'

  class Param
    attr_accessor :key, :value

    def initialize(key, value)
      @key = key
      @value = value
    end

    def to_multipart
      "Content-Disposition: form-data; name=\"#{key}\"\r\n\r\n#{value}\r\n"
    end
  end

  class FileParam
    attr_accessor :key, :filename, :content

    def initialize(key, filename, content)
      @key = key
      @filename = filename
      @content = content
    end

    def to_multipart
      "Content-Disposition: form-data; name=\"#{key}\"; filename=\"#{filename}\"\r\n" +
      "Content-Transfer-Encoding: binary\r\n" +
      "Content-Type: #{MIME::Types.type_for(filename).first.content_type}\r\n\r\n" +
      "#{content}\r\n"
    end
  end

  class MultipartPost
    BOUNDARY = "tarsiers-rule0000"
    HEADER = { "Content-type" => "multipart/form-data, boundary=" + BOUNDARY + " " }

    def prepare_query(params)
      normalized_params = params.each_with_object([]) do |(key, value), result|
        if value.respond_to?(:read)
          result.push(FileParam.new(key, value.path, value.read))
        elsif value.kind_of?(Array)
          value.each do |array_element|
            result.push(Param.new(key, array_element))
          end
        else
          result.push(Param.new(key,value))
        end
      end

      query = normalized_params.map do |p|
        "--" + BOUNDARY + "\r\n" + p.to_multipart
      end.join("") + "--" + BOUNDARY + "--"

      return query, HEADER
    end
  end
end
