require 'rubygems'
require 'sinatra'
require 'uri'
require 'dm-core'
require 'dm-timestamps'
require 'dm-aggregates'
require 'dm-migrations'
require 'twitter_oauth'
require './partialsupport.rb'
require './models.rb'

helpers Sinatra::Partials

# --------------------------------------------------
# Configuration: Run Once in any environment
# --------------------------------------------------
configure do
  set :sessions, true
  @@config = YAML.load_file("config.yml") rescue nil || {}
end

# --------------------------------------------------
# Filters
# --------------------------------------------------
before do
  puts "+==============+"
  puts "| CONFIGURATION |"
  puts "+==============+"
  puts "request.path_info = #{request.path_info}"
  puts "consumer_key= #{@@config['consumer_key']}"
  puts "consumer_secret= #{@@config['consumer_secret']}"
  puts "callback_url= #{@@config['callback_url']}"
  
  @user = session[:user]
  @client = TwitterOAuth::Client.new(
    :consumer_key => ENV['CONSUMER_KEY'] || @@config['consumer_key'],
    :consumer_secret => ENV['CONSUMER_SECRET'] || @@config['consumer_secret'],
    :token => session[:access_token],
    :secret => session[:secret_token]
  )
  if @user  
    p @client.info 
    @profile_image_url = @client.info['profile_image_url']
    @profile_name      = @client.info['screen_name']
  end
  
end



# --------------------------------------------------
# Routes
# --------------------------------------------------
    
get '/reset' do
  session[:user] = nil
  
  #Delete all instances from the repository
  Alias.destroy
  Command.destroy
  
  #Load up initial aliases & commands
  Alias.basic_aliases.each do |key,value|
    Alias.create(:user =>  "jteso", :alias => "#{key}", :url  => "#{value[:url]}",  :desc => "#{value[:desc]}",
                 :created_at => Time.now, :updated_at => Time.now)
  end  
  
  Command.basic_commands.each do |key,value|
    Command.create(:name => "#{key}", :desc => "#{value[:desc]}", :url => "#{value[:url]}")
  end

  redirect '/'
end
     
                
['/', '/home'].each do |path|
  get path do
    redirect '/alias'
  end
end

get '/execute' do
   command = "#{params[:command]}"

   if command == nil or command.length == 0
     redirect '/'
   else
     puts "command is  #{command}"
     command_url = command_translator command
     if command_url
       redirect command_url
     else
       tokens = command.split(' ')
   
       command_or_alias = tokens[0]
       params = tokens.slice(1, tokens.length) 
       #puts "command_or_alias= #{command_or_alias}"
       #puts "params = #{params}"
   
       redirect universal_translator(command_or_alias,params)
     end
   end

   
end
  
get '/add/:alias/:url/:desc' do
    
    _alias = "#{params[:alias]}"
    #sanitising url
    _url   = "#{params[:url]}"
    _url   = "http://" + _url unless "#{params[:url]}".include? ("http://")
    _desc  = "#{params[:desc]}"
    
    a = Alias.new
    a.user       = "jteso"
    a.alias      = _alias
    a.url        = _url
    a.desc       = _desc
    a.created_at = Time.now
    a.updated_at = Time.now
    a.save
    erb :add
end
###########################
# CONTINUE HERE !!!!!!!!
###########################
# get '/email' do
#  Pony.mail(:to=>"jtejob@gmail.com", 
#            :from => 'tester@gmail.com', 
#            :subject=> "howdy",
#            :body => "Bug reported number 1",
#            :via => :smtp, :smtp => {
#              :host       => 'smtp.gmail.com',
#              :port       => '587',
#              :user       => 'jtejob@gmail.com',
#              :password   => 'cdujteso200',
#              :auth       => :plain,
#              :domain     => "colonalias.com"
#             }
#           )
#  "Email sent!"
#end

# Connect to twitter
get '/signin_with_twitter' do
  request_token = @client.request_token(
    :oauth_callback => ENV['CALLBACK_URL'] || @@config['callback_url']
  )
  session[:request_token] = request_token.token
  session[:request_token_secret] = request_token.secret
  
  redirect request_token.authorize_url # dont think we have to replace this substring as per developer suggests
end

get '/signout' do
  session[:user] = nil
  redirect '/'
end


# Exchange the request token for an access token: callback from twitter
get '/authenticated' do
  begin
    @access_token = @client.authorize(
                          session[:request_token],
                          session[:request_token_secret],
                          :oauth_verifier => params[:oauth_verifier]
    )
  rescue
    OAuth::Unauthorized
  end
  
  if @client.authorized?
    session[:access_token] = @access_token.token
    session[:secret_token] = @access_token.secret
    session[:user] = true
    redirect '/'
  else
    redirect '/'
  end
  
end

get '/timeline' do
  @tweets = @client.friends_timeline
  p "client => #{@client}"
  erb :timeline
end

get '/alias' do
  @aliases = Alias.all(:user => 'jteso')
  erb :alias
end

get '/help' do
  @commands = Command.basic_commands
  erb :help
end

  






# --------------------------------------------------
# Helpers
# --------------------------------------------------
def universal_translator(command, params)
  url = command_translator(command)
  url ? url : url_translator(command, params)
end
                  

def command_translator(command)
  Command.url(command)
end


def url_translator(p_alias, params)
  url_found = Alias.url(p_alias)
  
  if  url_found == nil
    Alias.fallback_url(p_alias,params)
  else
    Alias.inject_query(url_found, params)
  end
  
 
end




