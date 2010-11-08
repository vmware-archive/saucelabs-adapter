require File.expand_path(File.dirname(__FILE__) + '/selenium_spec_helper')

describe 'access a webpage' do
  it 'can find Pivotal Labs' do
    visit 'http://www.pivotallabs.com'
    webrat_session.selenium.get_html_source.should contain 'Pivotal Labs'
  end
end
