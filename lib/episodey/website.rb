require 'nokogiri'

module Episodey
	#website object
	class Website < Episodey::Base
		# @!attribute urls
		#   @return [Hash] information for specific urls on this website
		#     current keys are: [home,rss,shows,movies]
		attr_accessor :urls

		# @!attribute args
		#   @return [Hash] a hash of arrays desribing arguments to be sent to this url [pager, searcher etc]
		attr_accessor :args

		# create {Website} objects from a config file
		# @example example contents of a website .cfg file
		#   [
		#   {
		#     "name": "rlsbb",
		#     "u_id": "rlsbb",
		#     "urls": {
		#       "home": "http://rlsbb.com",
		#       "rss": "http://feeds.feedburner.com/rlsbb/MrCi",
		#       "shows": "http://rlsbb.com/category/tv-shows/",
		#       "movies": "http://rlsbb.com/category/movies/"
		#     },
		#   }
		#   ]
		# @param cfg_path [String] path to website config file to parse.
		# @return [Hash<Website>] list of {Website} objects created.  raises Exception on failure.
		def self.load_cfg(cfg_path)
			websites = {}
			file = File.read(cfg_path)
			json = JSON.parse(file)
			json.each do |site|
				website = self.new
				website.name = site["name"]
				website.u_id = site["u_id"]
				website.urls = site["urls"]
				website.args = site["args"]

				if website.u_id.nil? || website.u_id.empty?
					raise Exception, "Website#u_id cannot be empty"
				end

				websites[website.u_id] = website
			end

			return websites
		end

		# load {Website}s from the database and merge them into website_list.
		# @param website_list [Hash<Website>] the Website list to merge db list with.  in the case of duplicate Website entries (denoted by {#u_id}), website_list has priority. [default => []]
		# @return [Hash<Website>] website_list merged with db info. raises Exception on failure.
		def self.load_db(website_list)
			if website_list.nil?
				website_list = {}
			else
				website_list = website_list.clone
			end

			#get all websites from the db
			db_websites = Episodey::DB::Website.all

			websites = {}
			db_websites.each do |site|
				website = self.db_to_object([site])[0]
		
				if website_list[website.u_id]
					w = website_list[website.u_id]
					website.name = w.name.to_s.empty? ? website.name : w.name
					website.urls = w.urls.empty? ? website.urls : w.urls
					website.args = w.args.empty? ? website.args : w.args

					#remove this from the website list
					website_list.delete(website.u_id)
				end

				websites[website.u_id] = website
			end

			if website_list.length > 0
				websites = websites.merge(website_list)
			end

			return websites
		end

		# converts all records in the db_websites list from active record objects to Episodey::Website objects
		#   notice: this accepts and outputs Arrays not Hashes
		# @param db_websites [Array<Episodey::DB::Website>] the Website list to convert
		# @return [Array<Episodey::Website>] converted list
		def self.db_to_object(db_websites)
			websites = []
			db_websites.each do |site|
				website = self.new
				website.id = site.id
				website.name = site.name
				website.u_id = site.u_id
				website.urls = YAML.load(site.urls_yaml)
				website.args = !site.args_yaml.nil? ? YAML.load(site.args_yaml) : nil
				websites << website
			end

			return websites
		end

		# inverse of {db_to_object}
		# @param website_list [Array<Episodey::Website>] the Website list to convert
		# @return [Array<Episodey::DB::Website>] converted list
		def self.object_to_db(website_list)
			db_websites = []
			website_list.each do |site|
				r = nil
				if site.id.nil? 
					r = Episodey::DB::Website.new
				else
					r = Episodey::DB::Website.find(site.id)
				end
				r.u_id = site.u_id;
				r.name = site.name;
				r.urls_yaml = site.urls.to_yaml;
				r.args_yaml = !site.args.nil? ? site.args.to_yaml : nil;
				db_websites << r
			end
			return db_websites
		end

		# take html and convert it to a list of {Posting}s
		# @param html [String] the html to convert into an array of {Posting}s
		# @return [Array<Posting>] array of postings.  raises Exception on failure.
		def self.html_to_postings(html)
			postings = []
			if html.nil?
				raise Exception, "argument 1 may not be nil"
			elsif html.empty?
				return postings
			end

			#let a module handle this if it wants to
			doc = Nokogiri.HTML(html)
			selected = doc.css("a")

			selected.each do |p|
				if p.attributes && p.attributes['href']
					posting = Episodey::Posting.new(p.attributes['href'].value)
					posting.html = p.inner_html
					postings << posting
				end
			end

			return postings
		end

		# generate a uri for this website given uri_key, page, and search
		# @param uri_key [String] the uri_key to use to generate the uri [eg. home, shows, movies, rss, etc...]
		# @param page [Fixnum] the value to fill in for the pager attribute
		# @param search [String] the value to fill in for the searcher attribute
		# @return [String] the generated uri.  raises Exception on failure.
		def generate_uri(uri_key,page=nil,search=nil)
			query = []
			uri = @urls.has_key?(uri_key.to_s) ? @urls[uri_key.to_s].clone : @urls[uri_key.to_sym].clone

			placeholder = "{x}"
			if !@args.nil? 
				if !page.nil?
					pager = @args["pager"]
					if !pager.nil?
						case pager[0].to_s
						when "get"
							query << "#{pager[1]}=#{page}"
						when "url"
							uri.gsub!(/\/?\{pager\}/,pager[1].sub(placeholder,page.to_s))
						end
					end
				end
				if !search.nil?
					searcher = @args["searcher"]
					if !searcher.nil?
						case searcher[0].to_s
						when "get"
							query << "#{searcher[1]}=#{search}"
						when "url"
							uri.gsub!(/\/?\{searcher\}/,searcher[1].sub(placeholder,search.to_s))
						end
					end
				end
			end

			#remove unused tags from url
			uri.gsub!(/\/?\{pager\}/,"")
			uri.gsub!(/\/?\{searcher\}/,"")

			#split the uri up, this has the byproduct of checking the new url and
			#	breaking up the querystring from the url so that i can rejoin it with 
			#	any newly generate querytring values
			uri = URI(uri)
			if !uri.query.nil? 
				query << uri.query.to_s
			end
			uri = "#{uri.scheme.nil? ? "" : uri.scheme.to_s + "://"}#{uri.host.to_s}#{uri.path.to_s}".chomp("/")

			if !query.empty?
				uri += "?" + query.join("&")
			end
			return URI(uri)
		end

		# prints website information.
		# @return [nil]
		def info
			nl = Episodey.nl
			tab = Episodey.tab
			header = ""
			body = ""
			header += "[#{self.id}] [#{self.u_id}, #{self.name}#{!self.urls.nil? && !self.urls['home'].nil? ? ', '+self.urls['home'] : ''}]#{nl}"
			urls.each do |key,url|
				if key != 'home'
					body += "#{tab}#{key} => #{url}#{nl}"
				end
			end
			puts header.colorize(:light_green) + body.colorize(:light_cyan)
		end

		# save this Website object to the database
		# @return [Boolean] true on success.  false if Website object has not been initialized.  raises Exception on failure.
		def save
			if !self.is_initialized
				return false
			end

			r = Episodey::Website.object_to_db([self])[0]
			r.save

			@id = @id.nil? ? r.id : @id
			return !@id.nil?
		end
	end

	class BulletinBoard < Episodey::Website
	end
end
