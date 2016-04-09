require 'nokogiri'

module Episodey
	#website object
	class Website < Episodey::Base
		# @!attribute urls
		#   @return [Hash] information for specific urls on this website
		#     current keys are: [home,rss,shows,movies]
		attr_accessor :urls

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
				websites << website
			end
			return websites
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
				posting = Episodey::Posting.new(p.attributes['href'].value)
				posting.html = p.inner_html
				postings << posting
			end

			return postings
		end

		# save this Website object to the database
		# @return [Boolean] true on success.  false if Website object has not been initialized.  raises Exception on failure.
		def save
			if !self.is_initialized
				return false
			end

			r = nil
			if @id.nil? 
				r = Episodey::DB::Website.new
			else
				r = Episodey::DB::Website.find(@id)
			end
			r.u_id = @u_id;
			r.name = @name;
			r.urls_yaml = @urls.to_yaml;
			r.save

			@id = @id.nil? ? r.id : @id
			return !@id.nil?
		end
	end

	class BulletinBoard < Episodey::Website
	end
end
