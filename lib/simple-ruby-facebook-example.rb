APP_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

require 'rubygems'
require 'sinatra'
require 'koala'
require 'socket'
#require 'actionpack' #  action_view/helpers/text_helper.rb
require 'action_view' #  action_view/helpers/text_helper.rb


#include MyLibrary

# register your app at facebook to get those infos
require APP_ROOT + '/lib/my_facebook_app.rb' # configuration for your app

class SimpleRubyFacebookExample < Sinatra::Application

	include Koala
	include ActionView::Helpers::TextHelper
	include ActionView::Helpers::TagHelper
	include ActionView::Helpers::FormHelper

	set :root, APP_ROOT
	enable :sessions
	
	def get_username(graph)
	 graph.inspect rescue :boh
	end

	get '/' do
		if session['access_token']
		  # do some stuff with facebook here
			# for example:
			@graph = Koala::Facebook::GraphAPI.new(session["access_token"])
			# publish to your wall (if you have the permissions)
			#@graph.put_wall_post("I'm posting from my new cool app!")
			# or publish to someone else (if you have the permissions too ;) )
			# @graph.put_wall_post("Checkout my new cool app!", {}, "someoneelse's id")
			'You are logged in as <tt>'+ escape_once(get_username(@graph)) +'</tt>! <a href="/logout">Logout</a> <BR/> <a href="/post_on_wall">Post on uoll (attento!)</a>:'
		else
			'<a href="/login">Login</a>'
		end
	end

  get '/post_on_wall' do
    @graph = Koala::Facebook::GraphAPI.new(session["access_token"])
    @graph.put_wall_post("I'm posting from my new cool app bella Ric From: #{ENV['USER']}@#{Socket.gethostname} on #{Time.now}")
    "Curva mac! Wanna post on wall? Really sure? TODO nicknames (applica nicknames in database locale che matchino il tuo user)"
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

