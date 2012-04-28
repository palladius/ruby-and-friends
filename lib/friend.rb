# Facebook friend, built from graph hash...

require 'action_view' #  action_view/helpers/text_helper.rb
include ActionView::Helpers::TextHelper
include ActionView::Helpers::TagHelper
include ActionView::Helpers::FormHelper

class Friend
  attr_accessor :fbhash
  
  def initialize(hash)
    puts "Friend class loaded!"
    @fbhash = hash
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
  
  def to_html
    #return "<pre>#{escape_once @fbhash.inspect}</pre>" 
    "<pre>#{@fbhash.map{|k,v| "#{k}: <B>#{v.inspect}</b><br/>"} }</pre>"
  end
  
  def to_s
    @fbhash['name']
  end
end