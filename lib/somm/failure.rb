# frozen_string_literal: true

class Somm
  class Failure < StandardError
    attr_reader :context

    def initialize(context)
      @context = context
      super("Service failed: #{@context.inspect}")
    end
  end
end
