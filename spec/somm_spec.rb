# frozen_string_literal: true

RSpec.describe Somm do
  describe ".call" do
    subject(:service) do
      Class.new(Somm) do
        def call
        end
      end
    end

    it "succeeds per default" do
      context = service.call

      expect(context.success?).to eq(true)
      expect(context.failure?).to eq(false)
    end
  end

  describe "#fail!" do
    subject(:service) do
      Class.new(Somm) do
        output :error

        def call
          fail!(error: "some error")
        end
      end
    end

    it "let's a service fail" do
      context = service.call

      expect(context.failure?).to eq(true)
      expect(context.success?).to eq(false)
    end

    it "assigns output" do
      context = service.call
      expect(context.error).to eq("some error")
    end
  end

  describe "deconstructing context" do
    subject(:service) do
      Class.new(Somm) do
        output :user_name

        def call
          context.user_name = "John Doe"
        end
      end
    end

    it "deconstructs the name" do
      service.call => user_name:, success:, failure:

      expect(user_name).to eq("John Doe")
      expect(success).to be(true)
      expect(failure).to be(false)
    end
  end

  describe ".call!" do
    subject(:service) do
      Class.new(Somm) do
        output :error

        def call
          fail!(error: "some error")
        end
      end
    end

    it "raises in case of failure" do
      expect { service.call! }.to raise_error(Somm::Failure)
    end
  end

  describe "inputs and outputs" do
    subject(:service) do
      Class.new(Somm) do
        input :a, :b
        output :x, :y

        def call
          context.x = 2*a
          context.y = 2*b
        end
      end
    end

    let(:sub_service) do
      Class.new(service) do
        input :c
        output :z

        def call
          context.x = 2*a
          context.y = 2*b
          context.z = 2*c
        end
      end
    end

    it "are available as getters and are returned as part of the context" do
      context = service.call(a: 1, b: 2)

      expect(context.a).to eq(1)
      expect(context.b).to eq(2)
      expect(context.x).to eq(2)
      expect(context.y).to eq(4)
    end

    it "get inherited" do
      context = sub_service.call(a: 1, b: 2, c: 3)

      expect(context.a).to eq(1)
      expect(context.b).to eq(2)
      expect(context.c).to eq(3)
      expect(context.x).to eq(2)
      expect(context.y).to eq(4)
      expect(context.z).to eq(6)
    end
  end

  describe ".rescue_from" do
    SomeException = Class.new(StandardError)

    subject(:service) do
      Class.new(Somm) do
        output :error

        rescue_from(SomeException) do |error|
          fail!(error: error.message)
        end

        def call
          raise SomeException, "some error"
        end
      end
    end

    it "rescues exceptions" do
      context = service.call

      expect(context.failure?).to eq(true)
      expect(context.error).to eq("some error")
    end
  end

  describe "callbacks" do
    subject(:service) do
      Class.new(Somm) do
        input :array

        before { array << "before" }
        after { array << "after" }

        def call
          array << "call"
        end
      end
    end

    it "are called before and after call" do
      context = service.call(array: [])
      expect(context.array).to eq(["before", "call", "after"])
    end
  end
end
