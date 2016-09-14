module Biolangual
  Error = Class.new RuntimeError

  class Wrapper
    attr_accessor :internal_data
    def initialize(data)
      @internal_data = data
    end
  end

  class Interpreter
    def number_proto
      @number_proto ||= Object.new
    end

    def string_proto
      @string_proto ||= Object.new
    end

    def false
      @false ||= Object.new
    end

    def biostring(ruby_string)
      Wrapper.new(ruby_string)
    end

    def biolist(ruby_array)
      Wrapper.new(ruby_array)
    end

    def evaluate!(ast)
      type, data = evaluate(ast)
      return data if type == :response
      raise Error, data
    end

    def evaluate(ast)
      case ast[:type]
      when :expression
        last = nil
        ast[:messages].each { |message| last = evaluate(message) }
        last
      when :message
        # FIXME: string_proto is bs, we should know the caller and receiver
        call string_proto, string_proto, biostring(ast[:name]), ast[:arguments]
      when :number
        [:response, biostring(ast[:value])]
      when :string
        [:response, biolist(ast[:value])]
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

      if "some-bs-message" == message.internal_data
        [:error, "Number does not respond to \"some-bs-message\""]
      else
        [:response, self.false]
      end
    end
  end
end
