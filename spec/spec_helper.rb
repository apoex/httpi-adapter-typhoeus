require "bundler/setup"
require "httpi/adapter/typhoeus"
require "webmock/rspec"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :each do
    Typhoeus::Expectation.clear
  end
end

RSpec::Matchers.define :match_response do |options|
  defaults = {
    code: 200,
    headers: { "Accept-encoding" => "utf-8" },
    body: ""
  }
  response = defaults.merge options

  match do |actual|
    expect(actual).to be_an(HTTPI::Response)
    expect(actual.code).to eq(response[:code])
    expect(downcase(actual.headers)).to eq(downcase(response[:headers]))
    expect(actual.body).to eq(response[:body])
  end

  def downcase(hash)
    hash.inject({}) do |memo, (key, value)|
      memo[key.downcase] = value.downcase
      memo
    end
  end
end
