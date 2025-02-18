# frozen_string_literal: true

require_relative "somm/version"
require_relative "somm/context"
require_relative "somm/failure"
require "active_support/core_ext/module/delegation"
require "active_support/rescuable"
require "active_support/callbacks"

class Somm
  include ActiveSupport::Rescuable
  include ActiveSupport::Callbacks
  define_callbacks :call

  class << self
    attr_accessor :context_class

    def inherited(subclass)
      if self == Somm
        subclass.context_class = Class.new(Context)
      else
        subclass.context_class = Class.new(context_class)
      end

      subclass.inputs.merge(inputs)
      subclass.outputs.merge(outputs)

      super
    end

    def input(*attributes)
      inputs.merge(attributes)
      context_class.attr_accessor(*attributes)
      delegate(*attributes, to: :@context)
    end

    def output(*attributes)
      outputs.merge(attributes)
      context_class.attr_accessor(*attributes)
      delegate(*attributes, to: :@context)
    end

    def call(**attributes)
      new(**attributes).tap(&:run).context
    end

    def call!(**attributes)
      call(**attributes).tap do |context|
        if context.failure?
          raise Failure.new(context)
        end
      end
    end

    def before(*filter_list, &block)
      set_callback(:call, :before, *filter_list, &block)
    end

    def after(*filter_list, &block)
      set_callback(:call, :after, *filter_list, &block)
    end

    def around(*filter_list, &block)
      set_callback(:call, :around, *filter_list, &block)
    end

    def inputs
      @inputs ||= Set.new
    end

    def outputs
      @outputs ||= Set.new
    end
  end

  attr_reader :context

  def initialize(**attributes)
    @context = self.class.context_class.new(**attributes)
  end

  def call
    raise NotImplementedError
  end

  def run
    catch(:failure) do
      begin
        run_callbacks(:call) do
          call
        end
      rescue StandardError => error
        rescue_with_handler(error) || raise
      end
    end
  end

  def fail!(**attributes)
    @context.fail!(**attributes)
  end
end
