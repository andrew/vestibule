require 'test_helper'

class ViewingTalksTest < IntegrationTestCase
  setup do
    @suggester = Factory.create(:user)
    @extra_detail_provider = Factory.create(:user)
    @discusser = Factory.create(:user)

    @talk_1 = Factory.create(:talk, :title => 'Jumping for joy with <Ruby>!', :created_at => 10.days.ago, :updated_at => 9.days.ago, :suggester => @suggester)
    @talk_1.contributions.create_providing_extra_detail(:user => @extra_detail_provider)
    Factory.create(:feedback, :talk => @talk_1, :user => @discusser)
    @talk_2 = Factory.create(:talk, :title => 'Touching RedCloth', :created_at => 1.minute.ago, :updated_at => 1.minute.ago)
    @talk_3 = Factory.create(:talk, :title => 'Pass the salt father, Oh! and by the way, I use Ruby', :created_at => 10.minutes.ago, :updated_at => 10.minutes.ago)
    @talk_4 = Factory.create(:talk, :title => 'To Ruby or not to Ruby', :created_at => 4.days.ago, :updated_at => 2.minutes.ago)
  end

  scenario "When I visit the talks index, I can see a list of talks that link to individual talk pages" do
    visit '/'

    the_page_has_title 'Talks'

    within('#talks') do
      assert_in_order all('.talk h2').map {|elem| elem.text}, @talk_2.title, @talk_4.title, @talk_3.title, @talk_1.title
    end

    click @talk_1.title

    i_am_on talk_path(@talk_1)
  end

  context "As a signed in user" do
    setup do
      sign_in
    end

    context "When viewing the page about a talk" do
      setup do
        visit talk_path(@talk_1)

        the_page_has_title @talk_1.title
      end

      scenario "I can see all the details of that talk that have been filled in, and am prompted to fill in the missing ones" do
        this_section_of_the_talk_page_is_empty 'abstract'
        i_follow_the_link_in_this_section_and_fill_out_the_missing_detail 'abstract', with: 'This talk will cover why I think ruby is a joyful language.'
        this_section_of_the_talk_page_is_not_empty 'abstract', with_content: 'This talk will cover why I think ruby is a joyful language.'

        this_section_of_the_talk_page_is_empty 'outline'
        i_follow_the_link_in_this_section_and_fill_out_the_missing_detail 'outline', with: 'The first slides will cover my "Aw yeah!" moment with Ruby. The next slides will be the same thing from some other rubyists. It\'ll finish up with ways you can help other programmers experience their own "Aw yeah!" moments when they first experience ruby.'
        this_section_of_the_talk_page_is_not_empty 'outline', with_content: 'The first slides will cover my "Aw yeah!" moment with Ruby. The next slides will be the same thing from some other rubyists. It\'ll finish up with ways you can help other programmers experience their own "Aw yeah!" moments when they first experience ruby.'

        this_section_of_the_talk_page_is_empty 'why_its_interesting', with_missing_content_message: 'Nothing about why this talk is interesting has been provided yet.'
        i_follow_the_link_in_this_section_and_fill_out_the_missing_detail 'why_its_interesting', with: 'Day to day programming can be dull and enterprisey. We need reminding of why we\'ve chosen Ruby. And we need to be able to pass on that excitement to others.'
        this_section_of_the_talk_page_is_not_empty 'why_its_interesting', with_content: 'Day to day programming can be dull and enterprisey. We need reminding of why we\'ve chosen Ruby. And we need to be able to pass on that excitement to others.'
      end

      scenario "I can see a list of all the contributors to the talk" do
        i_can_see_the_list_of_all_the_contributors_to_the_talk
      end
    end
  end

  context "As a visitor" do
    context "When viewing the page about a talk" do
      setup do
        visit talk_path(@talk_1)

        the_page_has_title @talk_1.title
      end

      scenario "I can see all the details of that talk that have been filled in, and am prompted to sign up or sign in to fill in the missing ones" do
        this_section_of_the_talk_page_is_empty 'abstract', but_has_no_flesh_it_out_prompt: true
        i_am_prompted_to_sign_up_or_sign_in_to_fill_out_section 'abstract'

        this_section_of_the_talk_page_is_empty 'outline', but_has_no_flesh_it_out_prompt: true
        i_am_prompted_to_sign_up_or_sign_in_to_fill_out_section 'outline'

        this_section_of_the_talk_page_is_empty 'why_its_interesting', but_has_no_flesh_it_out_prompt: true, with_missing_content_message: 'Nothing about why this talk is interesting has been provided yet.'
        i_am_prompted_to_sign_up_or_sign_in_to_fill_out_section 'why_its_interesting'
      end

      scenario "I can see a list of all the contributors to the talk" do
        i_can_see_the_list_of_all_the_contributors_to_the_talk
      end
    end
  end

  def this_section_of_the_talk_page_is_empty(which_section, options = {})
    within("##{which_section}") do
      assert page.has_content?(options[:with_missing_content_message] || "No #{which_section} has been provided yet.")
      look_for_prompt =
        if options.has_key?(:but_has_no_flesh_it_out_prompt)
          !options[:but_has_no_flesh_it_out_prompt]
        else
          true
        end
      if look_for_prompt
        assert page.has_link?('Why don\'t you fill it in?')
      else
        assert page.has_no_link?('Why don\'t you fill it in?')
      end
    end
  end

  def i_follow_the_link_in_this_section_and_fill_out_the_missing_detail(which_section, options = {})
    within("##{which_section}") do
      click 'Why don\'t you fill it in?'
    end

    i_am_on edit_talk_path(@talk_1)

    new_value = (options[:with] || 'Some long bit of text that fleshes out this part of the talk')
    label = (options[:via_form] || Talk.human_attribute_name(which_section))

    fill_in label, :with => new_value
    click_button 'Update suggestion'
  end

  def this_section_of_the_talk_page_is_not_empty(which_section, options={})
    non_empty_value = (options[:with_content] || 'Some long bit of text that fleshes out this part of the talk')

    within("##{which_section}") do
      assert page.has_content?(non_empty_value)
      assert page.has_no_link?('Why don\'t you fill it in?')
    end
  end

  def i_am_prompted_to_sign_up_or_sign_in_to_fill_out_section(which_section)
    within "##{which_section}" do
      there_are_sign_up_and_sign_in_links
    end
  end

  def i_can_see_the_list_of_all_the_contributors_to_the_talk
    within '.contributors' do
      within '.suggester' do
        assert page.has_content?(@suggester.email)
      end

      within '.extra_detail_providers' do
        assert page.has_content?(@extra_detail_provider.email)
      end

      within '.discussers' do
        assert page.has_content?(@discusser.email)
      end
    end
  end
end
