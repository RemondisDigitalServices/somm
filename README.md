# Somm

Somm is a Service Object library inspired by [Interactor](https://github.com/collectiveidea/interactor) and [ServiceActor](https://github.com/sunny/actor) with as little features as we need.

It offers:

- Inputs and Outputs
- Result Objects
- Callbacks
- Rescuable Exceptions

It does not offer:

- Organizers
- Input defaults or validations

## Installation

Add the gem to your Gemfile:

```ruby
gem "somm", github: "RemondisDigitalServices/somm"
```

## Usage

The Service interface is a single `.call` class method which accepts any pre-defined Inputs as keyword arguments. It internally calls the `#call` instance method and returns a Context (or Result) object. The Result object is a `success?` per default and becomes a `failure?` if `fail!` was called. It includes all the Inputs and Outputs.

```ruby
class AuthenticateUser < Somm
  input :email, :password
  output :user, :error

  def call
    if user = User.authenticate(email, password) # Inputs are available as getters
      context.user = user
    else
      fail!(error: "User not found")
    end
  end
end

result = AuthenticateUser.call(email: "…", password: "…")

if result.success?
  # do something with result.user
else
  # do something with result.error
end
```

#### `.call!`

In case you need the service to raise instead of returning a failed Result object, use `.call!`:

```ruby
begin
  AuthenticateUser.call!(user: "…", password: "wrong-password")
rescue Somm::Failure => error
  error.context.success? # => false
  error.context.failure? # => true
  error.context.error # => "User not found"
end
```

#### Callbacks

```ruby
class SomeService < Somm
  after { puts "after" }
  before { puts "before" }

  around do |service, block|
    puts "around before"
    block.call
    puts "around after"
  end

  def call
    puts "call"
  end
end

SomeService.call
# before
# around before
# call
# around after
# after
```

#### Rescuable Exceptions

```ruby
class SomeService < Somm
  output :error

  rescue_from(SomeException) do |error|
    fail!(error: error.message)
  end

  def call
    raise SomeException, "Some error message"
  end
end

result = SomeService.call
result.success? # => false
result.failure? # => true
result.error # => "Some error message"
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/RemondisDigitalServices/somm.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
