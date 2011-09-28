require 'rubygems'
require 'sinatra'
require 'uri'
require 'dm-core'
require 'dm-timestamps'
require 'dm-aggregates'
require 'dm-migrations'
# require './pony_gmail.rb'
require './partialsupport.rb'
require './models.rb'

helpers Sinatra::Partials


# --------------------------------------------------
# Routes
# --------------------------------------------------

# Quick and dirty solution to insert initial values in DB. 
# TODO -- Replace this with dm-migrations.   

get '/migrateup' do  
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
    erb :home
  end
end

get '/execute' do
   command = "#{params[:command]}"
   if command == nil or command.length == 0
     redirect '/'
   else
     tokens = command.split(' ')
   
     command_or_alias = tokens[0]
     params = tokens.slice(1, tokens.length) 
     puts "command_or_alias= #{command_or_alias}"
     puts "params = #{params}"
   
     redirect universal_translator(command_or_alias,params)
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

get '/:command' do
 
  if params[:command] == "alias"
    @aliases = Alias.all(:user => 'jteso')
  
  elsif params[:command] == "help"
    @commands = Command.basic_commands
  end
    
  erb params[:command].to_sym
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




