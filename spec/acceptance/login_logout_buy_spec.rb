require_relative "acceptance_helper"

class LoginLogoutBuySpec < Minitest::Spec 
  include ::Capybara::DSL
  include ::Capybara::Minitest::Assertions

  def self.test_order
    :alpha #run the tests in this file in order
  end

  before do
    visit '/'
  end

  after do 
    Capybara.reset_sessions!
  end

  it 'user login and log out' do
    find('a', text: 'login').click()
    
    sleep(2)
    
    fill_in('email', with: "jesper@publicshop.io")
    fill_in('password', with: "OurAdmin")
    click_button('login')

    sleep(2)

    find('a', text: 'Logout').click()

    sleep(2)
  end
  
  it 'user login and buy rocks' do
    find('a', text: 'login').click()
    
    sleep(2)
    
    fill_in('email', with: "jesper@publicshop.io")
    fill_in('password', with: "OurAdmin")
    click_button('login')

    sleep(2)
    
    fill_in('q', with: 'rocks')
    click_button('Search')

    sleep(2)

    find('h1', text: 'rocks').click()

    sleep(2)

    find('button', text: 'Add to cart').click()

    sleep(2)

    find('a', text: 'Account').click()

    sleep(2)

    find('a', text: 'my cart').click()

    find(:xpath, '//section[@id="cart"]/section[1]/a[1]', text: 'rocks')
    find(:xpath, '//section[@id="cart"]/section[1]/a[2]', text: 'Adam')

    sleep(2)
  end

end