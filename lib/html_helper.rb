helpers do
  # Convenience method for manually escaping html
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
  def tt(str)
    "<tt>#{str}</tt>"
  end
  def li(s)
    "<li>#{s}</li>"
  end
  
  def link_to(text, href)
    %(<a href="#{href}">#{h(text)}</a>)
  end
  
  def fb_link_for(id,msg=nil)
    msg ||= "Facebook Page of #{id}"
    "<img src='facebook.png'><a href='https://www.facebook.com/profile.php?id=#{id}' >#{msg}</a>"
  end
  
  def img(src,opts={})
    "<img src='/images/#{src}' height='20' >"
  end
  
  def log_info()
    "#{ENV['USER']}@#{Socket.gethostname}"
  end
end

#helpers do
#  include Rack::Utils
#  alias_method :h, :escape
#end
