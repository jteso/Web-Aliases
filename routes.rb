require 'rubygems'
require 'sinatra'
require 'uri'
require 'dm-core'
require 'dm-timestamps'
require 'dm-aggregates'
require 'dm-migrations'
require './partialsupport.rb'

helpers Sinatra::Partials

# --------------------------------------------------
# Model
# --------------------------------------------------
DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/alias.db")

class Alias
  include DataMapper::Resource
  property :id,         Serial
  property :user,       Text, :required => true
  property :alias,      Text, :required => true
  property :url,        Text, :required => true
  property :created_at, DateTime
  property :updated_at, DateTime
end

DataMapper.finalize.auto_upgrade!

#DataMapper.finalize.auto_migrate!

# --------------------------------------------------
# Routes
# --------------------------------------------------

# Quick and dirty solution to insert initial values in DB. 
# TODO -- Replace this with dm-migrations.   

get '/migrateup' do
  initial_aliases = basic_aliases
  initial_aliases.each do |key,value|
    a = Alias.new
    a.user       = "jteso"
    a.alias      = "#{key}"
    a.url        = "#{value}"
    a.created_at = Time.now
    a.updated_at = Time.now
    a.save
   # puts "alias #{alias} saved. "
  end  
    redirect '/'  
end
    
   
                
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
      puts "redirect #{command} #{query.strip}"
      redirect(url_translator(command, query.strip))
   end
   
end

get '/add/:alias/:url' do
  
    _alias = "#{params[:alias]}"
    #sanitising url
    _url   = "#{params[:url]}"
    _url   = "http://" + _url unless "#{params[:url]}".include? ("http://")
    
    a = Alias.new
    a.user       = "jteso"
    a.alias      = _alias
    a.url        = _url
    a.created_at = Time.now
    a.updated_at = Time.now
    a.save
    erb :add
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
                    :b        => 'http://www.bing.com/search?q={query}',
                    :gl       => 'http://www.google.com/search?btnI=I2+Feeling+Lucky&q={query}',
                    :gd       => 'https://docs.google.com/?ui%3D1&ltmpl=homepage#search/{query}',
                    :gi       => 'http://images.google.com/search?q={query}&biw=1276&bih=702&tbm=isch',
                    :gm       => 'http://maps.google.com/maps?q={query}',
                    :gt       => 'http://translate.google.com/?text={query}',
                    :gr       => 'http://www.google.com/reader',
                    :gml      => 'http://mail.google.com',
                    :gn       => 'http://www.google.com/search?aq=f&hl=en&gl=au&tbm=nws&btnmeta_news_search=1&q={query}',
                    :utb      => 'http://www.youtube.com/results?search_query={query}',
                    :am       => 'http://www.amazon.com/s?url=search-alias=aps&field-keywords={query}',
                    :weather  => 'http://weather.yahoo.com/search/weather?location={query}',
                    :tw       => 'http://twitter.com',
                    :twu      => 'http://twitter.com/#!/search/{query}', #search for users
                    :twt      => 'http://twitter.com/#!/{query}', #search for terms
                    :wiki     => 'http://en.wikipedia.org/wiki/{query_}',
                    :imdb     => 'http://www.imdb.com/find?s=all&q={query}',
                    :rt       => 'http://www.rottentomatoes.com/m/{query_}',
                    :ebay     => 'http://www.ebay.com/sch/?_nkw={query}',
                    :lin      => 'http://www.linkedin.com',
                    :linu     => 'http://www.linkedin.com/commonSearch?type=people&keywords={query}', #search for users
                    :fb       => 'http://www.facebook.com',
                    :fbu      => 'http://www.facebook.com/search/?q={query}',
                    :flkr     => 'http://www.flickr.com/search/?q={query}&w=all'
                  }
                  
 #                  :cba      => 'https://www.my.commbank.com.au/netbank/Logon/Logon.aspx',
 #                  :as       => 'http://www.as.com',
 #                  :rdoc     => 'http://www.ruby-doc.org/core/classes/{query}.html',
                  
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
    if query == nil
      fallback(websearch)
    else
      fallback(websearch + "+" + query) 
    end
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
  elsif url.include? "{query_}"
      if param == nil
        uri_split = URI.split(url.gsub('{query}','')) # making the URI valid
        uri_split[0] + "://" + uri_split[2] 
      else
         url.gsub('{query_}', param.gsub('+','_'))
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


