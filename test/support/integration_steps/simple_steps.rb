module SimpleSteps
  def i_am_on(expected_path)
    assert_equal expected_path, current_path
  end

  def the_page_has_title(expected_title)
    ['h1', 'title'].each do |title_selector|
      within(title_selector) do
        assert page.has_content?(expected_title), %Q{Expected "#{expected_title}" within CSS selector '#{title_selector}', but it's not there}
      end
    end
  end
end