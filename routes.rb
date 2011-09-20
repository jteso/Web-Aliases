require 'rubygems'
require 'sinatra'
require 'uri'

# --------------------------------------------------
# Routes
# --------------------------------------------------

['/', '/home'].each do |path|
  get path do
   # if session[:userid].nil? then erb :login 
   # else redirect "/#{User.get(session[:userid]).email}"
   erb :home
  end
end

get '/execute' do
   websearch = "#{params[:post][:websearch]}"
   params = websearch.split(' ')
   if params.length == 1
     if command_translator(websearch)
        redirect command_translator(websearch)
     else
        redirect(url_translator(websearch, nil))
     end
   else
      command = params[0]
      query   = params[1]

      redirect(url_translator(command, query))
   end
   
end

get '/:command' do
  erb params[:command].to_sym
end


# --------------------------------------------------
# Helpers
# --------------------------------------------------
def command_translator(websearch)
  basic_commands = {':help' => '/help' }
  basic_commands[websearch]
end


def url_translator(websearch, query)
  
  basic_searches = {
                    :as       => 'http://www.as.com',
                    :rdoc     => 'http://www.ruby-doc.org/core/classes/{query}.html',
                    :g        => 'http://www.google.com/search?q={query}',
                    :gl       => 'http://www.google.com/search?btnI=I2+Feeling+Lucky&q={query}',
                    :gi       => 'http://images.google.com/search?q={query}&biw=1276&bih=702&tbm=isch',
                    :gm       => 'http://maps.google.com/maps?q={query}',
                    :gt       => 'http://translate.google.com/?text={query}',
                    :gmail    => 'http://mail.google.com',
                    :amazon   => 'http://www.amazon.com/s?url=search-alias=aps&field-keywords={query}',
                    :weather  => 'http://weather.yahoo.com/search/weather?location={query}'
                  }
  url_found = basic_searches[websearch.to_sym]

  if  url_found == nil
    fallback(websearch)
  else
    inject_param(url_found, query)
  end
  
 
end

def inject_param(url,param)
  if param == nil
    "http://" + URI.parse(url.gsub('{query}', '')).host
  else
    url.gsub('{query}', param)
  end
  
end

def fallback(websearch)
  fallback = 'http://www.google.com/search?q={query}'
  inject_param(fallback,websearch)
end

