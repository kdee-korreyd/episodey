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
		# @return [Array<Website>] list of {Website} objects created.  raises Exception on failure.
		def self.load_cfg(cfg_path)
		end

		# load {Website}s from the database and merge them into website_list.
		# @param website_list [Array<MediaSet>] the Website list to merge db list with.  in the case of duplicate Website entries (denoted by {#u_id}), website_list has priority. [default => []]j
		# @return [Array<Website>] website_list merged with db info. raises Exception on failure.
		def self.load_db(website_list)
		end

		# take html and convert it to a list of {Posting}s
		# @param html [String] the html to convert into an array of {Posting}s
		# @return [Array<Posting>] array of postings.  raises Exception on failure.
		def self.html_to_postings(html)
			#let a module handle this if it wants to
		end

		# save this Website object to the database
		# @return [Boolean] true on success.  false if Website object has not been initialized.  raises Exception on failure.
		def save
		end
	end

	class BulletinBoard < Episodey::Website
	end
end
