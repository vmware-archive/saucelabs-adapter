class SampleWebratTest < ActionController::IntegrationTest

  def test_widget
    visit "/widgets"
    assert_contain "widget"
  end
end