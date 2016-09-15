class Proc
  # uhm...
  def to_ruby
    self
  end
end

module Biolangual
  Error = Class.new RuntimeError

  class PrototypicalObject
    attr_accessor :responses, :prototypes, :inspection
    def initialize(inspection:nil, responses:[], prototypes:[])
      self.inspection, self.responses, self.prototypes = inspection, responses, prototypes
      yield self if block_given?
    end

    def inspect
      inspection || super
    end

    def call(receiver, sender, message, arguments)
      _, body = responses.assoc message
      return [:error, "#{self} does not respond to #{message}"] unless body
      body.call receiver, sender, message, arguments
    end
  end

  class Wrapper < PrototypicalObject
    attr_accessor :internal_data
    def initialize(data, **keys)
      @internal_data = data
      super **keys
    end

    def to_s
      "b.#{internal_data.inspect}"
    end

    alias inspect to_s

    def ==(other)
      internal_data == other.internal_data
    end

    def to_ruby
      internal_data
    end
  end

  class Biolist < Wrapper
    def to_ruby
      internal_data.map(&:to_ruby)
    end
  end

  class Interpreter
    def current_object
      @current_object ||= main_object
    end

    def main_object
      # FIXME: callers in these lambdas shouldn't be `this`,
      # it should have its own function context!
      # also, this is going to happen a lot, and its super annoying
      # maybe a helper? (specifically, the needing to turn all of Ruby's objs into biolang objs
      # here, the string and list
      @main_object ||= PrototypicalObject.new inspection: 'b.main' do |main|
        # TODO: `respones` belongs on to Prototype
        main.responses << [
          biostring('responses'),
          lambda do |this, that, message, args|
            responses = this.responses.map { |pair| biolist(pair) }
            [:response, biolist(responses)]
          end,
        ]

        main.responses << [
          biostring('prototypes'),
          lambda do |this, that, message, args|
            [:response, biolist(this.prototypes)]
          end,
        ]
      end
    end

    def list_proto
      @list_proto ||= Biolist.new inspection: 'b.ListProto' do |list|
        # TODO: clone belongs on PrototypicalObject
        list.responses << [
          biostring('clone'),
          lambda do |this, that, message, args|
            [ :response,
              Biolist.new(inspection: 'b.[?...?]', prototypes: [this]),
            ]
          end
        ]
      end
    end

    # FIXME: when we make numbers, they do not get this as the proto,
    # they are instances of Wrapper
    def number_proto
      @number_proto ||= PrototypicalObject.new inspection: 'b.NumberProto'
    end

    # FIXME: when we make strings, they do not get this as the proto,
    # they are instances of Wrapper
    def string_proto
      @string_proto ||= PrototypicalObject.new inspection: 'b.StringProto'
    end

    def false
      @false ||= PrototypicalObject.new inspection: 'b.false'
    end

    def true
      @true ||= PrototypicalObject.new inspection: 'b.false'
    end

    def biostring(ruby_string)
      Wrapper.new(ruby_string)
    end

    def biolist(array)
      # FIXME: total bs, should be a clone of the list prototype
      Biolist.new array
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
        receiver.call receiver, sender, message, arguments
      else
        raise "uhm, impl this for real *rolls eyes* #{message.inspect}"
      end
    end
  end
end
