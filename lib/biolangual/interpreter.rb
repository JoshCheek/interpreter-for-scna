module Biolangual
  Error = Class.new RuntimeError

  class PrototypicalObject
    attr_accessor :messages, :prototypes, :inspection
    def initialize(inspection:nil, messages:{}, prototypes:[])
      self.inspection, self.messages, self.prototypes = inspection, messages, prototypes
    end

    def inspect
      inspection || super
    end

    def call(receiver, sender, message, arguments)
      return messages.fetch message if messages.key? message
      [:error, "#{self} does not respond to #{message}"]
    end
  end

  class Wrapper
    attr_accessor :internal_data
    def initialize(data)
      @internal_data = data
    end

    def to_s
      "(bio #{internal_data.inspect})"
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
      @main_object ||= PrototypicalObject.new inspection: 'main'
    end

    # FIXME: when we make numbers, they do not get this as the proto,
    # they are instances of Wrapper
    def number_proto
      @number_proto ||= PrototypicalObject.new inspection: 'Number'
    end

    # FIXME: when we make strings, they do not get this as the proto,
    # they are instances of Wrapper
    def string_proto
      @string_proto ||= PrototypicalObject.new inspection: 'String'
    end

    def false
      @false ||= PrototypicalObject.new inspection: 'false'
    end

    def true
      @true ||= PrototypicalObject.new inspection: 'false'
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
        response = call(
          current_object,
          string_proto, # FIXME
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

      # stupid hacks
      case message.internal_data
      when "some-bs-message"
        return [:error, "Number does not respond to \"some-bs-message\""]
      when "identity"
        return [:response, self.current_object]
      when 'false'
        return [:response, self.false]
      when 'true'
        return [:response, self.true]
      when 'true?'
        return [:response, self.current_object]
      end

      # move em all to this
      if receiver.respond_to? :call
        return receiver.call receiver, sender, message, arguments
      else
        raise "uhm, impl this for real *rolls eyes* #{message.inspect}"
      end
    end
  end
end
