require 'rubygems'
require 'sinatra'
require 'dm-core'
require 'dm-timestamps'
require 'dm-aggregates'
require 'dm-migrations'
require 'uri'
# --------------------------------------------------
# Model
# --------------------------------------------------
DataMapper::setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/alias.db")
class Command
  include DataMapper::Resource
  property :id,     Serial
  property :name,   Text
  property :desc,   Text
  property :url,    Text
  
  def self.basic_commands
    basic_commands = {
                       ':help'  => {:desc => 'Show a list of all available commands',  :url=>'/help'},
                       ':date'  => {:desc => 'Display Date and Time',                  :url=>'/date'},
                       ':alias' => {:desc => 'Show all aliases available',             :url=>'/alias'}
                      }
  end
  
  def self.url(p_name)
     record = first(:name => p_name)
     record ? record.url : nil
  end
end


class Alias
  include DataMapper::Resource
  property :id,         Serial
  property :user,       Text, :required => true
  property :alias,      Text, :required => true
  property :url,        Text, :required => true
  property :desc,       Text, :default => 'Not Available'
  property :created_at, DateTime
  property :updated_at, DateTime
  
  def self.basic_aliases
    basic_aliases = {
                       :g        => {:desc => 'Search Google for {query}',      :url=>'http://www.google.com/search?q={query}'},
                       :b        => {:desc => 'Search Bing for {query}',        :url=>'http://www.bing.com/search?q={query}'},
                       :y        => {:desc => 'Search Yahoo! for {query}',      :url=>'search.yahoo.com/search?p={query}'},
                       :gl       => {:desc => 'I am feeling lucky for {query}', :url=>'http://www.google.com/search?btnI=I2+Feeling+Lucky&q={query}'},
                       :gd       => {:desc => 'Open Google Docs or Search Google Docs for {query}', :url=>'https://docs.google.com/?ui%3D1&ltmpl=homepage#search/{query}'},
                       :gi       => {:desc => 'Search Google Images for {query}',:url=>'http://images.google.com/search?q={query}&biw=1276&bih=702&tbm=isch'},
                       :gm       => {:desc => 'Search Google Maps for {query}', :url=>'http://maps.google.com/maps?q={query}'},
                       :gt       => {:desc => 'Translate {query}',              :url=>'http://translate.google.com/?text={query}'},
                       :gr       => {:desc => 'Open Google Reader',             :url=>'http://reader.google.com'},
                       :gml      => {:desc => 'Open GMail',                     :url=>'http://mail.google.com'},
                       :gn       => {:desc => 'Open Google News or Search News for {query}', :url=>'http://www.google.com/search?aq=f&hl=en&gl=au&tbm=nws&btnmeta_news_search=1&q={query}'},
                       :utb      => {:desc => 'Open Youtube or Search Videos for {query}',   :url=>'http://www.youtube.com/results?search_query={query}'},
                       :am       => {:desc => 'Open Amazon or Search Books for {query}',     :url=>'http://www.amazon.com/s?url=search-alias=aps&field-keywords={query}'},
                       :weather  => {:desc => 'Weather for {query}',            :url=>'http://weather.yahoo.com/search/weather?location={query}'},
                       :tw       => {:desc => 'Open Twitter or search users for {query}', :url=>'http://twitter.com/#!/{query}'},                 
                       :twt      => {:desc => 'Search Twitter for {query}',     :url=>'http://twitter.com/#!/search/{query}'}, 
                       :wiki     => {:desc => 'Search Wikipedia for {query}',   :url=>'http://en.wikipedia.org/wiki/{query_}'},
                       :imdb     => {:desc => 'Search IMDB  for {query}',       :url=>'http://www.imdb.com/find?s=all&q={query}'},
                       :rt       => {:desc => 'Search Rotten Tomatoes for {query}', :url=>'http://www.rottentomatoes.com/m/{query_}'},
                       :ebay     => {:desc => 'Search Ebay for {query}',        :url=>'http://www.ebay.com/sch/?_nkw={query}'},
                       :lin      => {:desc => 'Open Linkedin or search users for {query}', :url=>'http://www.linkedin.com/commonSearch?type=people&keywords={query}'},
                       :fb       => {:desc => 'Open Facebook or search users for {query}', :url=>'http://www.facebook.com/search/?q={query}'},
                       :flkr     => {:desc => 'Open Flickr or search images for {query}',  :url=>'http://www.flickr.com/search/?q={query}&w=all'}
                     }
                     #                  :cba      => 'https://www.my.commbank.com.au/netbank/Logon/Logon.aspx',
                     #                  :as       => 'http://www.as.com',
                     #                  :rdoc     => 'http://www.ruby-doc.org/core/classes/{query}.html',
  end
  
  def self.alias?(p_alias)
    first(:alias => p_alias)? true : false
  end
  
  def self.url(p_alias)
    record = first(:alias => p_alias)
    record ? record.url : nil
  end
  
  def self.fallback_url(param, params)
    fallback_url = 'http://www.google.com/search?q={query}'
    puts "param= #{param}"
    query = param
    if params != nil  
      if params.length > 1
        query = query + "+" + params.join("+")
      else
        query = query + "+" + params[0]
      end
      query = URI.escape(query, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
    end
    
    
    inject_query(fallback_url,query.split)
    
  end 
  
  def self.inject_query(url, queries)
     if queries.length == 0 || queries == nil
        remove_param_from_url(url,"{query}","{query_}")
     else
        if url.include? "{query}"
          url.gsub('{query}', build_query_to_replace("+",queries))
        elsif url.include? "{query_}"
          url.gsub('{query_}', build_query_to_replace("_",queries))
        else
          puts "URL= #{url} does not contain any known match for parameters." 
          "http://www.google.com"
        end      
      end
  end
  
  def self.build_query_to_replace(separator, queries)
    if queries.length > 1
      queries.join(separator)
    else
      queries[0]
    end
    
  end
  
  
  def self.remove_param_from_url(url, *matches)
     matches.each do |match|
       puts "match=#{match}"
       url = url.gsub(match,'') # making the URI valid
     end
     uri_split = URI.split(url) 
     uri_split[0] + "://" + uri_split[2] # protocol + domain
  end
  
end

DataMapper.finalize.auto_upgrade!

#DataMapper.finalize.auto_migrate!
