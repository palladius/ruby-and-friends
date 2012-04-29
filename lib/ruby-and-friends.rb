APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'sinatra'
require 'koala'
require 'socket'
#require 'actionpack' #  action_view/helpers/text_helper.rb
require 'action_view' #  action_view/helpers/text_helper.rb

# register your app at facebook to get those infos
require APP_ROOT + '/lib/my_facebook_app_conf.rb' # configuration for your app
require APP_ROOT + '/lib/friend.rb'          # Facebook friend definition

=begin
  Docs:
  
  http://stackoverflow.com/questions/6976394/facebook-graph-api-koala-how-to-find-relationship-status-of-a-users-friend

=end

class RubyAndFriends < Sinatra::Application

  include Koala
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::FormHelper
  
  set    :root, APP_ROOT
  enable :sessions

  def get_username(graph)
   #:TODO #graph.inspect rescue :boh
   graph.get_object("me")['name'] # Riccardo Carlesso
  end

  def log_info()
    "#{ENV['USER']}@#{Socket.gethostname}"
  end
  
  # before do
  #   MyStore.connect unless MyStore.connected?
  # end

  get '/' do
    if session['access_token']
      # do some stuff with facebook here
      # for example:
      @graph = Koala::Facebook::GraphAPI.new(session["access_token"])
      # publish to your wall (if you have the permissions)
      #@graph.put_wall_post("I'm posting from my new cool app!")
      # or publish to someone else (if you have the permissions too ;) )

      html_page('You just logged in as <tt>'+ escape_once(get_username(@graph)) +'</tt>!' +
      "<img src='#{ @graph.get_picture('fabiomattei') }' height='30' />" +
      "<a href=\"/logout\">Logout</a> <BR/>
      :")
    else
      html_page '<a href="/login">Login</a>'
    end
  end

  def fb_link_for(id,msg=nil)
    msg ||= "Facebook Page of #{id}"
    "<img src='facebook.png'><a href='https://www.facebook.com/profile.php?id=#{id}' >#{msg}</a>"
  end
  
  def img(src,opts={})
    "<img src='/images/#{src}' height='20' >"
  end
  def header(opts={})
    @graph = Koala::Facebook::GraphAPI.new(session["access_token"])
    session_info = if session['access_token'] then
      'You are logged in as <tt>'+ escape_once(get_username(@graph)) +'</tt>! '+
      "<img src='#{ @graph.get_picture('me') }' height='50' />" +
      '<a href="/logout">Logout</a>'
    else
      '<a href="/login">Login</a>'
    end
    
    friends_graph_addon = '{'+ FAVORITE_FRIENDS.map{ |username| "<a href='/graphs/#{username}'><tt>#{username}</tt></a> "}.join(' : ') + '}'
    
    return "<center>[ 
      #{ img('home.png') }
      <a href=\"/\">Home</a>
      <a href='/friends' >Friends</a>
      <a href='/myfriends' >MyFriends</a>
      <a href='/index' >Index</a>
      <a href='/me' >Me</a>
      <a href=\"/post_on_wall\">Post on YOUR uoll</a>
      <a href='/post_on_other_persons_wall?msg=ciao #{TEST_FRIEND_NAME}&friend_id=#{TEST_FRIEND_ID}' >Posting on '#{TEST_FRIEND_NAME}' wall</a>
    ] #{img('facebook.png')} #{session_info}</center> 
    
    #{friends_graph_addon}
    
    <h1>#{opts.fetch :title, APPNAME}</h1>"
  end
  
  def footer(opts={})
    "<hr/> #{img('riccardo.jpg')}<tt>Facebook mini app made in sinatra. See <a href='/README'>README</a></tt>"
  end
  
  def html_page(str, opts={})
    header(opts) + str.to_s + footer(opts)
  end
  
  before do
    @graph = Koala::Facebook::GraphAPI.new(session["access_token"])
  end
  
  get '/me' do
    #@result = @graph.get_connections('me', 'feed')
    #my_friends = @graph.get_connections('me','friends',:fields=>"name,gender,relationship_status").first(10)
    html_page "
      <h1>About Me</h1>
        #{ @graph.get_object("me").inspect }     
      <h2>Feeds</h2>
        #{ @graph.get_connections('me', 'feed') }
      "
  end

  get '/post_on_other_persons_wall' do
    friend_id = params.fetch :friend_id, TEST_FRIEND_ID
    msg = params.fetch 'msg', "default hello #{TEST_FRIEND_NAME}"
    @graph = Koala::Facebook::GraphAPI.new(session["access_token"])
    @graph.put_wall_post("#{log_info}: #{msg}", {}, friend_id)
    html_page "Message '<b>#{msg}</b>' correctly published on #{TEST_FRIEND_NAME}'s wall: #{fb_link_for friend_id}. 
    <BR/>DEBUG: params are: #{params.inspect}"
  end
  
  get '/friends' do
    html_page "It would be nice here to show your friends!!!<br/>
    Friends:<br/>
    <a href='/friends/123'>John - Friend 123</a><br/>
    <a href='/friends/456'>Alice - Friend 456</a><br/>
    Graphs:<br/>
    <a href='/graphs/palladius'>Palladius</a><br/>
    ", :title => 'Your Friends'
  end
  
  get '/friends/:id' do
    id = params[:id]
    @friend = Friend.find(params[:id]) rescue nil
    # using the params convention, you specified in your route
    html_page "#{@friend.inspect}", :title => "Friend #{id} TODO"
  end
  
  get '/graphs/:name' do
    #@graph = Koala::Facebook::GraphAPI.new(session["access_token"])
    username = @graph.get_object(params[:name])
    friend = Friend.new( @graph , params[:name] )
    #friend_id = friend.id
    #my_friends = @graph.get_connections('me','friends',:fields=>"name,gender,relationship_status")
    # #{:scope => 'publish_stream,offline_access,email,user_relationships,friends_relationships'}
    html_page "
    #{friend.img() }
    <h2>Friend #{friend}</h2>
    #{friend.html_name} : <br/>
    #{friend.to_html}
    <h2>Mutual friends for #{friend.id}</h2>
    
    #{ @graph.get_connections("me", "mutualfriends/#{friend.fb_id}").inspect }
    
    <h2>Likes</h2>
    
    #{ @graph.get_connections(friend.username, "likes") }
    

    ", :title => "Graph for #{username['name']}"
  end
  
  def fblink(id)
    "http://www.facebook.com/#{id}"
  end
  
  # TODO in ERB: _friend.erb
  def friend_partial(friend_hash)
    color = friend_hash['gender'] == 'male' ? 'darkcyan' : 'darksalmon'
    "- 
    <img src='#{ @graph.get_picture(TEST_FRIEND_ID) }' height='30' />
    <img src='#{ @graph.get_picture(friend_hash['id'] ) }' height='30' />
    
      <a href='#{fblink(friend_hash['id'])}'>
        <font color='#{color}'>
          #{friend_hash['name']}
        </font>
      </a> - 
      <small>#{friend_hash.delete_if{ |k,v| %w{id gender name}.include?(k)  }.inspect}</small> <br/>"
  end
  
  get '/myfriends/' do
    MAX_FRIENDS = 20
    my_friends = @graph.get_connections('me','friends',:fields=>"name,gender,relationship_status")
    tmp = ''
    friends_page = my_friends.first(MAX_FRIENDS).map{|friend_hash| 
      tmp += friend_partial(friend_hash) 
    }
    html_page "
    <h2>My friends (max #{MAX_FRIENDS})</h2>
    #{tmp}    
    ", :title => "Your friends"
    
  end
  
  get '/README' do
    html_page( "<pre>" + File.read(APP_ROOT + "/README") + "</pre>" )
  end
  
  get '/index' do
    erb 'index.html'
  end
  
  get '/post_on_wall' do
    @graph = Koala::Facebook::GraphAPI.new(session["access_token"])
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

