module Biolangual
  class Interpreter
    def number_proto
      :number_proto
    end

    def string_proto
      @string_proto ||= Object.new
    end

    def false
      @false ||= Object.new
    end

    def biostring(ruby_string)
      "biostring: #{ruby_string.inspect}"
    end

    def biolist(ruby_array)
      "List: #{ruby_array.inspect}"
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

      if "biostring: \"some bs message\"" == message
        [:error, "Number does not respond to \"some bs message\""]
      else
        [:response, self.false]
      end
    end
  end
end
