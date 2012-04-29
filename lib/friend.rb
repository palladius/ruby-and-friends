# Facebook friend, built from graph hash...

require 'rubygems'
require 'sinatra'
require 'koala'
require 'action_view' #  action_view/helpers/text_helper.rb
include ActionView::Helpers::TextHelper
include ActionView::Helpers::TagHelper
include ActionView::Helpers::FormHelper

=begin

  Tries to model a Facebook friend...

=end
class Friend
  attr_accessor :fbhash, :graph, :username
  # TODO memoize!
  
  def initialize(graph, username)
    #puts "Friend class loaded with graph: #{graph}!"
    #throw ("Sorry I need a @graph object, not a '#{graph.class}'") unless graph.class == Koala::Facebook::GraphAPI
    throw "Sorry I need a @graph object, not a '#{graph.class}'" unless graph.class == Koala::Facebook::API
    @graph    =  graph  # original object
    @username =  username  # original object
    @fbhash   = graph.get_object(username) # hash
  end
  
  def html_name
    color = if @fbhash['gender'] == 'female' then
      "pink" else 'blue' end
    "
    <a href='https://www.facebook.com/#{@fbhash['id']}'>FB</a>
    <a href='#{@fbhash['link']}'>2</a>
    
    <a href=''><font color='#{color}' >#{@fbhash['name']}</font></a>
    "
  end
  
  def fb_id
    @fbhash['id']
  end
  
  def username
    @fbhash['username']
  end
  
  #{:scope => 'publish_stream,offline_access,email,user_relationships,friends_relationships'}
  def friends
    :TODO
  end
  
  # @graph.get_picture(username) rescue "Err: #{$!}"
  def get_picture
    @graph.get_picture(@username)
  end
  
  def img(opts={})
    height=opts.fetch :height, 100
    "<img src='#{get_picture}' height='#{height}' />"
  end
  
  def to_html
    #return "<pre>#{escape_once @fbhash.inspect}</pre>" 
    "<pre>#{@fbhash.map{|k,v| "#{k}: <B>#{v.inspect}</b><br/>"} }</pre>"
  end
  
  def to_s
    @fbhash['name']
  end
end