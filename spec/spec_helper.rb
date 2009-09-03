ENV['RACK_ENV'] = 'test'
require 'lib/cilantro'
Cilantro.load_environment

describe '' do
  it 'should test properly' do
    true.should eql(true)
  end
end
