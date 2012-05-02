helpers do
  # Convenience method for manually escaping html
  def h(text)
    Rack::Utils.escape_html(text)
  end
  
  def tt(str)
    "<tt>#{str}</tt>"
  end
  
  def link_to(text, href)
    %(<a href="#{href}">#{h(text)}</a>)
  end
end

#helpers do
#  include Rack::Utils
#  alias_method :h, :escape
#end
