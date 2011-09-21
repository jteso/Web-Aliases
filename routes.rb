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
   websearch = "#{params[:websearch]}"
   params = websearch.split(' ')
   if params.length == 1
     if command_translator(websearch)
        redirect command_translator(websearch)
     else
        redirect(url_translator(websearch, nil))
     end
   else
      command = params[0]
      # build the parameter for command above
      i = 2
      query = params[1]
      while i < params.length do
        query = query + "+" + params[i]  
        i +=1
      end

      redirect(url_translator(command, query.strip))
   end
   
end

get '/:command' do
  # If required, pass the paramater to the view
  if params[:command] == "alias"
    @alias = basic_aliases
  end
  if params[:command] == "help"
    @commands = basic_commands
  end

  erb params[:command].to_sym
end


# --------------------------------------------------
# Helpers
# --------------------------------------------------

def basic_aliases
  basic_aliases = {
                    :g        => 'http://www.google.com/search?q={query}',
                    :gl       => 'http://www.google.com/search?btnI=I2+Feeling+Lucky&q={query}',
                    :gi       => 'http://images.google.com/search?q={query}&biw=1276&bih=702&tbm=isch',
                    :gm       => 'http://maps.google.com/maps?q={query}',
                    :gt       => 'http://translate.google.com/?text={query}',
                    :gr       => 'http://www.google.com/reader',
                    :gmail    => 'http://mail.google.com',
                    :amazon   => 'http://www.amazon.com/s?url=search-alias=aps&field-keywords={query}',
                    :weather  => 'http://weather.yahoo.com/search/weather?location={query}',
                    :cba      => 'https://www.my.commbank.com.au/netbank/Logon/Logon.aspx',
                    :as       => 'http://www.as.com',
                    :rdoc     => 'http://www.ruby-doc.org/core/classes/{query}.html',
                  }
end

def basic_commands
  basic_commands = {
                     ':help'  => '/help',
                     ':date'  => '/date',
                     ':alias' => '/alias'
                    }
end
                  

def command_translator(websearch)
  commands = basic_commands
  commands[websearch]
end


def url_translator(websearch, query)
  basic_searches = basic_aliases
  
  url_found = basic_searches[websearch.to_sym]

  if  url_found == nil
    fallback(websearch)
  else
    inject_param(url_found, query)
  end
  
 
end


def inject_param(url,param)
  
  if url.include? "{query}"
     if param == nil
       uri_split = URI.split(url.gsub('{query}','')) # making the URI valid
       uri_split[0] + "://" + uri_split[2] 
     else
        url.gsub('{query}', param)
     end
  else
    # static alias -- ignore 'param'
    url
  end
  
  
end

def fallback(websearch)
  fallback = 'http://www.google.com/search?q={query}'
  inject_param(fallback,websearch)
end


