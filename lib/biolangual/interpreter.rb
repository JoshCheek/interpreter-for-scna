module Biolangual
  Error = Class.new RuntimeError

  class Wrapper
    attr_accessor :internal_data
    def initialize(data)
      @internal_data = data
    end

    def ==(other)
      internal_data == other.internal_data
    end
  end

  class Interpreter
    def current_object
      @current_object ||= main_object
    end

    def main_object
      @main_object ||= Object.new
    end

    def number_proto
      @number_proto ||= Object.new
    end

    def string_proto
      @string_proto ||= Object.new
    end

    def false
      @false ||= Object.new
    end

    def true
      @true ||= Object.new
    end

    def biostring(ruby_string)
      Wrapper.new(ruby_string)
    end

    def biolist(ruby_array)
      Wrapper.new(ruby_array)
    end

    def bionum(ruby_num)
      Wrapper.new(ruby_num.to_f)
    end

    def evaluate!(ast)
      type, data = evaluate(ast)
      return data if type == :response
      raise Error, data
    end

    def respond_with(object)
      @current_object = object
      [:response, object]
    end

    def evaluate(ast)
      case ast[:type]
      when :expression
        last = nil
        ast[:messages].each { |message| last = evaluate(message) }
        last
      when :message
        # FIXME: string_proto is bs, we should know the caller and receiver
        response = call(
          string_proto,
          string_proto,
          biostring(ast[:name]),
          ast[:arguments],
        )

        # this obviously goes in #call, its here for now b/c call's message passing is bs
        if response[0] == :response
          respond_with response[1]
        else
          response
        end
      when :number
        respond_with bionum(ast[:value])
      when :string
        respond_with biostring(ast[:value])
      else
        raise "wat: #{ast.inspect}"
      end
       # :messages=>[{:type=>:message, :name=>"false", :arguments=>[]}]}
    end

    def last_message_sent
      @last_message_sent
    end

    def call(receiver, sender, message, arguments)
      @last_message_sent = {
        receiver:  receiver,
        sender:    sender,
        message:   message,
        arguments: arguments,
      }

      case message.internal_data
      when "some-bs-message"
        [:error, "Number does not respond to \"some-bs-message\""]
      when "identity"
        [:response, self.current_object]
      when 'false'
        [:response, self.false]
      when 'true'
        [:response, self.true]
      when 'true?'
        [:response, self.current_object]
      else
        raise "uhm, impl this for real *rolls eyes* #{message.inspect}"
      end
    end
  end
end
