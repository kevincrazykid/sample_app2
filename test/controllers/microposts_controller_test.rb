require 'test_helper'

class MicropostsControllerTest < ActionController::TestCase
  # this is added from listing 11.30;
  def setup
    @micropost = microposts(:orange)
  end
  
  test "should redirect create when not logged in" do
    assert_no_difference 'Micropost.count' do
      post :create, micropost: { content: "Lorem ipsum" }
    end
    assert_redirected_to login_url
  end
  
  test "should redirect destroy when not logged in" do
    assert_no_difference 'Micropost.count' do
      delete :destroy, id: @micropost
    end
    assert_redirected_to login_url
  end
  
  # this is added in listing 11.52, and simply test micropost deletion
  # with a user mismatch; we expected no difference between micropost
  # count after 
  test "should redirect destroy for wrong micropost" do
    log_in_as(users(:test))
    micropost = microposts(:ants)
    assert_no_difference 'Micropost.count' do
      delete :destroy, id: micropost
    end
    assert_redirected_to root_url
  end
end
