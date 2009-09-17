ENV['RACK_ENV'] = 'test'
require 'lib/cilantro'
Cilantro.load_environment

describe 'Tests' do
  it 'should operate properly' do
    true.should eql(true)
  end
end
