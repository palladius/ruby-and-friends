APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'sinatra'
require 'koala'
require 'socket'
#require 'actionpack' #  action_view/helpers/text_helper.rb
require 'action_view' #  action_view/helpers/text_helper.rb

# register your app at facebook to get those infos
require APP_ROOT + '/conf/my_facebook_app_conf.rb' # configuration for your app
require APP_ROOT + '/lib/friend.rb'                # Facebook friend definition
require APP_ROOT + '/lib/html_helper.rb'           # Helper functions


=begin
  Docs:
  
  http://stackoverflow.com/questions/6976394/facebook-graph-api-koala-how-to-find-relationship-status-of-a-users-friend

=end

class RubyAndFriends < Sinatra::Application

  include Koala
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  
  # cut n paster by graphs APIs :)
  GraphActions = %w{ accounts activities adaccounts albums apprequests
    books checkins events family feed friendlists friendrequests friends games groups home inbox interests likes links 
    movies music mutualfriends notes notifications outbox
    payments permissions photos picture posts scores statuses
    tagged television updates videos
  }
  
  set    :root, APP_ROOT
  enable :sessions

  # used in various places
  def get_username(graph)
    graph.get_object('me')['name']
  end

  get '/' do
    if session['access_token']
      # for example:
      # publish to your wall (if you have the permissions)
      #@graph.put_wall_post("I'm posting from my new cool app!")
      # or publish to someone else (if you have the permissions too ;) )
      html_page('You are '+ tt(h( get_username @graph ))+'.' +
      "<img src='#{ @graph.get_picture('me') }' height='30' />" +
      "<a href=\"/logout\">Logout</a> <BR/>
      :")
    else
      html_page '<a href="/login">Login</a>'
    end
  end
  
  def html_page(str, opts={})
    set :opts, opts
    erb(:'header.html') + 
      str.to_s + 
      erb(:'footer.html')
  end
  
  # before any GET, it initializes the GRAPH object
  before do
    #@graph = Koala::Facebook::GraphAPI.new(session["access_token"]) # pre 1.2beta
    @graph = Koala::Facebook::API.new(session["access_token"])     # 1.2beta and beyond
    @graph = Koala::Facebook::API.new(SUPER_TOKEN) if SUPER_TOKEN
  end
  
  get '/me' do
    #@result = @graph.get_connections('me', 'feed')
    #my_friends = @graph.get_connections('me','friends',:fields=>"name,gender,relationship_status").first(10)
    html_page "
      <h1>About Me</h1>
        #{ @graph.get_object("me").inspect }     
      <h2>Feeds</h2>
        #{ @graph.get_connections('me', 'feed').inspect }
      "
  end

  get '/post_on_other_persons_wall' do
    friend_id = params.fetch :friend_id, TEST_FRIEND_ID
    msg = params.fetch 'msg', "default hello #{TEST_FRIEND_NAME}"
    @graph.put_wall_post("#{log_info}: #{msg}", {}, friend_id)
    html_page "Message '<b>#{msg}</b>' correctly published on #{TEST_FRIEND_NAME}'s wall: #{fb_link_for friend_id}. 
    <BR/>DEBUG: params are: #{params.inspect}"
  end
  
  get '/friendlists/:id' do
    id = params[:id]
    #hash = @graph.get_connections('me',id)
    erb :friendlist, :layout => :ric_layout, :locals => {:id => id } # , :hash => :hash}
  end
  
  get '/friendlists/' do
    set :friend_list, @graph.get_connections('me','friendlists').first(5) # ,:fields=>"name,gender,relationship_status")
    erb :friendlists, :layout => :ric_layout
  end
  
  get '/friends' do
    erb :'friends.html', :layout => :ric_layout
  end
  
  get '/friends/:id' do
    id = params[:id]
    @friend = Friend.find(params[:id]) rescue nil
    # using the params convention, you specified in your route
    html_page "#{@friend.inspect}", :title => "Friend #{id}"
  end
  
  get '/graphs/:id/:action' do
    # possible actions: 'members, picture, photos, ...'
    #action_jason = @graph.get_object(params[:id])
    generic_graph = @graph.get_connections(params[:id], params[:action])
    #html_page "#{@friend.inspect}", :title => "Friend #{id} action: #{ params[:action]}"
    erb :graph_action, 
      :layout => :ric_layout, 
      :locals => { 
        :json => generic_graph , 
        :title => "Friend #{id} action: #{ params[:action]}",
        :action => params[:action], 
        :fbid   => params[:id] 
      }
  end
  
  get '/graphs/:name' do
    username = @graph.get_object(params[:name])
    friend = Friend.new( @graph , params[:name] )
    #set :friend, friend
    return erb :graphs, :layout => :ric_layout, :locals => {:friend => friend }
  end
  
  def fblink(id)
    "http://www.facebook.com/#{id}"
  end
  
  def friend_partial(friend_hash)
    set :graph, @graph
    set :friend_hash, friend_hash
    return erb :_friend
  end
  
  get '/myfriends/' do
    MAX_FRIENDS = 10
    my_friends = @graph.get_connections('me','friends',:fields=>"name,gender,relationship_status")
    tmp = ''
    friends_page = my_friends.first(MAX_FRIENDS).map{|friend_hash| 
      tmp += friend_partial(friend_hash) 
    }
    html_page "<h2>My friends (max #{MAX_FRIENDS})</h2>    #{tmp}", :title => "MyFriends"
  end
  
  get '/README' do
    html_page( "<pre>" + File.read(APP_ROOT + "/README") + "</pre>" )
  end
  
  get '/index' do
    erb 'index.html'
  end
  
  get '/post_on_wall' do
    @graph.put_wall_post("I'm posting from my new cool app bella Ric From: #{log_info}")
    html_page "Curva mac! Wanna post on wall? Really sure? 
    TODO nicknames (applica nicknames in database locale che matchino il tuo user)"
  end

  get '/login' do
    # generate a new oauth object with your app data and your callback url
    session['oauth'] = Facebook::OAuth.new(APP_ID, APP_CODE, SITE_URL + 'callback')
    # redirect to facebook to get your code
    redirect session['oauth'].url_for_oauth_code()
  end

  get '/logout' do
    session['oauth'] = nil
    session['access_token'] = nil
    redirect '/'
  end

  #method to handle the redirect from facebook back to you
  get '/callback' do
    #get the access token from facebook with your code
    session['access_token'] = session['oauth'].get_access_token(params[:code])
    redirect '/'
  end

end

