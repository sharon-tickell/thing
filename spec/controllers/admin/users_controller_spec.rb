require 'rails_helper'

describe Admin::UsersController, type: :controller do
  it 'requires admin' do
    visit admin_users_path
    page.should have_content('Not authorized')
  end

  describe 'listing' do
    it "renders user's name, email, and track" do
      log_in admin: true, mundane_name: 'Fred', tracks: [Instructable::TRACKS.keys.first, Instructable::TRACKS.keys.last]
      visit admin_users_path
      find('.roles').should have_content('Admin')
      find('.roles').should have_content('Coordinator')
      find('.display_name').should have_content('Fred')
      find('.display_name').should have_content current_user.email
      current_user.tracks.each { |track|
        find('.tracks').should have_content track
      }
    end

    it "renders '-' if the user has no track" do
      log_in admin: true, mundane_name: 'Fred'
      visit admin_users_path
      find('.tracks').should have_content '-'
    end

    it 'renders with more than a page full of users' do
      30.times do
        create(:user)
      end
      log_in admin: true
      visit admin_users_path
    end

    it 'renders the bootstrap_renderer gap' do
      70.times do
        create(:user)
      end
      log_in admin: true
      visit admin_users_path
    end
  end

  describe 'edit user' do
    before :each do
      log_in admin: true
      @other_user = create(:user)
      @link_id = "\#edit_user_#{@other_user.id}"
    end

    it 'shows link' do
      visit admin_users_path
      find(@link_id).should have_content @other_user.email
    end

    it 'link works' do
      visit admin_users_path
      click_on @other_user.display_name
      page.should have_content "Editing #{@other_user.display_name}"
    end
  end

  describe 'edit' do
    before :each do
      log_in admin: true
      @other_user = create(:user)
    end

    it 'renders' do
      visit edit_admin_user_path(@other_user)
      page.should have_content "Editing #{@other_user.display_name}"
    end

    it 'updates' do
      visit edit_admin_user_path(@other_user)
      page.should have_content @other_user.email
      fill_in 'Email address', with: 'example@example.com'
      click_on 'Update user'
      page.should have_content 'User updated.'
    end

    it 're-renders form on error' do
      visit edit_admin_user_path(@other_user)
      page.should have_content @other_user.email
      fill_in 'Email address', with: ''
      click_on 'Update user'
      page.should_not have_content 'User updated.'
    end
  end

  describe 'search' do
    before :each do
      @users = []
      @users << log_in(admin: true, sca_name: 'adminofdoom')
      @users << create(:instructor, sca_name: 'scaflarg', mundane_name: 'mundaneflarg', email: 'flargemail@example.com')
      @users << create(:instructor, sca_name: 'scabaz', mundane_name: 'mundanebaz', email: 'bazemail@example.com')
      @users << create(:user, mundane_name: 'notateacher')
      @users << create(:user, mundane_name: 'proofer', proofreader: true)
      @users << create(:user, mundane_name: 'tracker', tracks: ['Middle Eastern'])
      @users << create(:user, mundane_name: 'pu-staffer', pu_staff: true)
    end

    def check_users(role)
      @users.each do |user|
        if user.send(role)
          page.should have_content user.mundane_name
        else
          page.should_not have_content user.mundane_name
        end
      end
    end

    it 'searches on email' do
      visit admin_users_path
      fill_in 'Search', with: 'flargemail'
      click_on 'Filter'
      page.should have_content 'mundaneflarg'
      page.should_not have_content 'scabaz'
    end

    it 'searches on mundane_name' do
      visit admin_users_path
      fill_in 'Search', with: 'mundaneflarg'
      click_on 'Filter'
      page.should have_content 'scaflarg'
      page.should_not have_content 'scabaz'
      page.should_not have_content 'notateacher'
    end

    it 'searches on sca_name' do
      visit admin_users_path
      fill_in 'Search', with: 'scaflarg'
      click_on 'Filter'
      page.should have_content 'mundaneflarg'
      page.should_not have_content 'scabaz'
      page.should_not have_content 'notateacher'
    end

    it 'searches by role admin' do
      visit admin_users_path
      select 'Admin', from: 'role'
      click_on 'Filter'
      check_users(:admin?)
    end

    it 'searches by role coordinator' do
      visit admin_users_path
      select 'Coordinator', from: 'role'
      click_on 'Filter'
      check_users(:coordinator?)
    end

    it 'searches by role instructor' do
      visit admin_users_path
      select 'Instructor', from: 'role'
      click_on 'Filter'
      check_users(:instructor?)
    end

    it 'searches by role pu staff' do
      visit admin_users_path
      select 'PU Staff', from: 'role'
      click_on 'Filter'
      check_users(:pu_staff?)
    end

    it 'searches by role proofreader' do
      visit admin_users_path
      select 'Proofreader', from: 'role'
      click_on 'Filter'
      check_users(:proofreader?)
    end

    it 'clears' do
      visit admin_users_path
      fill_in 'Search', with: 'scaflarg'
      click_on 'Filter'
      click_on 'Clear'
      page.should have_content 'mundaneflarg'
      page.should have_content 'scabaz'
    end
  end
end
