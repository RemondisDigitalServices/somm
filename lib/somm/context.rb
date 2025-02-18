# frozen_string_literal: true

class Somm
  class Context
    def initialize(**attributes)
      @_failure = false
      set(**attributes)
    end

    def fail!(**attributes)
      set(**attributes)
      @_failure = true
      throw :failure
    end

    def success?
      !failure?
    end

    def failure?
      @_failure
    end

    private

    def set(**attributes)
      attributes.each { |key, value| public_send(:"#{key}=", value) }
    end
  end
end
