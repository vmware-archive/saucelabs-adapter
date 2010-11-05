require File.expand_path(File.dirname(__FILE__) + '/selenium_spec_helper')

describe 'Google Search' do
  it 'can find Google' do
    visit 'http://www.google.com'
    response.should contain 'Google'
  end
end
