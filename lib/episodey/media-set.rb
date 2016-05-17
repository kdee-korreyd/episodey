module Episodey
	#holds a list of related media & metadata for that related media
	class MediaSet < Episodey::Base
		# @!attribute search
		#   @return [Array<String>] strings represent regular expressions used to determine if a {Episodey::Posting} is part of this media set.
		attr_accessor :search

		# @!attribute search_url_keys
		#   @return [Array<String>] array of {Website} url keys you would need to search to find this media
		attr_accessor :search_url_keys

		# @!attribute id_format_string
		#   @return [String] a format string used to create a uniform u_id for any {Episodey::Media} to be added to this media set.
		attr_accessor :id_format_string

		# @!attribute default_media_class
		#   @return [String] class of new {Episodey::Media} objects added to this MediaSet.
		attr_accessor :default_media_class

		# @!attribute media
		#   @return [Array<Episodey::Media>] list of Media objects assiciated with this MediaSet
		attr_accessor :media

		# constructor
		# @return [Episodey::MediaSet] new MediaSet
		def initialize
			@media = []
		end



		# add a new {Episodey::Media} object to this MediaSets {#media} attribute.
		# @param media [Episodey::Media] the Media object to add.
		# @return [Episodey::Media] the media object added.  raises Exception on failure.
		def add_media(media)
			#add only if it doesnt already exist here
			if @media.find {|m| m.u_id == media.u_id}.nil?
				@media << media
				media.media_set = self
			end
			return media
		end

		# create {MediaSet}s objects from a config file
		# @example example contents of a media_set .cfg file
		#   [
		#   {
		#     "name": "elementary",
		#     "u_id": "elementary",
		#     "default_media_class": "Episode",
		#     "search_url_keys": ["home","shows"],
		#     "search": [
		#       "elementary.*s(\d{1,2})[^\d]*(\d{1,2})",
		#       "elementary.*season(\d{1,2})[ ]*episode(\d{1,2})"
		#     ],
		#     "id_format_string": "elementary_s%02de%02d"
		#   }
		#   ]
		# @param cfg_path [String] path to media set config file to parse.
		# @return [Hash<MediaSet>] hash of {MediaSet}s objects created.  raises Exception on failure.
		def self.load_cfg(cfg_path)
			media_sets = {}
			file = File.read(cfg_path)
			json = JSON.parse(file)
			json.each do |ms|
				media_set = self.new
				media_set.name = ms["name"]
				media_set.u_id = ms["u_id"]
				media_set.search = ms["search"]
				media_set.search_url_keys = ms["search_url_keys"]
				media_set.default_media_class = ms["default_media_class"]
				media_set.id_format_string = ms["id_format_string"]

				if media_set.u_id.nil? || media_set.u_id.empty?
					raise Exception, "MediaSet#u_id cannot be empty"
				end

				media_sets[media_set.u_id] = media_set
			end
			return media_sets
		end

		# load {MediaSet}s from the database and merge them into media_set_list.  Also loads corresponding media into the MediaSet.
		# @param media_set_list [Array<MediaSet>] the MediaSet list to merge db list with.  in the case of duplicate MediaSet entries (denoted by {#u_id}), media_set_list has priority. [default => []]j
		# @return [Array<MediaSet>] media_set_list merged with db info. raises Exception on failure.
		def self.load_db(media_set_list)
			if media_set_list.nil?
				media_set_list = {}
			else
				media_set_list = media_set_list.clone
			end

			#get all media_sets from the db
			db_media_sets = Episodey::DB::MediaSet.all

			media_sets = {}
			db_media_sets.each do |ms|
				media_set = self.db_to_object([ms])[0]
		
				if media_set_list[media_set.u_id]
					m = media_set_list[media_set.u_id]
					media_set.name = m.name.to_s.empty? ? media_set.name : m.name
					media_set.search = m.search.empty? ? media_set.search : m.search
					media_set.search_url_keys = m.search_url_keys.empty? ? media_set.search_url_keys : m.search_url_keys
					media_set.default_media_class = m.default_media_class.to_s.empty? ? media_set.default_media_class : m.default_media_class
					media_set.id_format_string = m.id_format_string.to_s.empty? ? media_set.id_format_string : m.id_format_string

					#remove this from the media_set list
					media_set_list.delete(media_set.u_id)
				end

				media_sets[media_set.u_id] = media_set
			end

			if media_set_list.length > 0
				media_sets = media_sets.merge(media_set_list)
			end

			return media_sets
		end


		# converts all records in the db_media_set_list list from active record objects to Episodey::MediaSet objects
		#   notice: this accepts and outputs Arrays not Hashes
		# @param db_media_set_list [Array<Episodey::DB::MediaSet>] the MediaSet list to convert
		# @return [Array<Episodey::MediaSet>] converted list
		def self.db_to_object(db_media_set_list)
			media_sets = db_media_set_list.map do |ms|
				media_set = YAML.load(ms.object_yaml)
				media_set.id = ms.id
				
				#store corresponding media
				media_list = Episodey::DB::Media.where(media_set_id: media_set.id)
				Episodey::Media.db_to_object(media_list).each do |m|
					media_set.add_media(m)
				end

				media_set
			end
			return media_sets
		end

		# inverse of {db_to_object}
		# @param media_set_list [Array<Episodey::MediaSet>] the MediaSet list to convert
		# @return [Array<Episodey::DB::MediaSet>] converted list
		def self.object_to_db(media_set_list)
			db_media_sets = media_set_list.map do |ms|
				r = nil
				if ms.id.nil? 
					r = Episodey::DB::MediaSet.new
				else
					r = Episodey::DB::MediaSet.find(ms.id)
				end
				r.u_id = ms.u_id
				r.name = ms.name
				r.default_media_type = ms.default_media_class
				r.search_regex_json = ms.search.to_json
				r.identity_format_str = ms.id_format_string

				#dont store media with yaml, media will load from references
				tmp_media = ms.media
				ms.media = []
				r.object_yaml = ms.to_yaml
				ms.media = tmp_media
				r
			end
			return db_media_sets
		end

		# checks if str belongs to this media set by using {#search} expressions
		# @param str [String] string to check against this media set
		# @param regex_opts [Fixnum] one or more of the constants Regexp::EXTENDED, Regexp::IGNORECASE, and Regexp::MULTILINE, or-ed together. Otherwise, if options is not nil or false, the regexp will be case insensitive. defaults to case insensitive
		# @param media [Episodey::Media] options param which will update media.u_id if there is a match
		# @return [Boolean] true if it belongs to this media set, false if it doesn't
		def matches?(str,regex_opts=true,media=nil)
			@search.each do |s|
				re = Regexp.new(s,regex_opts)
				m = str.match(re)
				if m
					media.u_id = @id_format_string % m.to_a.drop(1) if !media.nil?
					return true
				end
			end
			return false
		end

		# search this media set for a particular Media object
		# @param media_u_id [Integer] the u_id for the media you want to find
		# @return [Episodey::Media] if the media object was found in this media set.
		# @return [nil] if media not found
		def find_media(media_u_id)
			if !@media.nil? 
				return @media.find { |m| m.u_id == media_u_id }
			end
			return nil
		end
		alias_method :find_media_by_u_id, :find_media

		# prints media set information (and optionally its media list).
		# @param include_media_list [Boolean] if true then the media_list for each set is printed as well
		# @return [nil]
		def info(include_media_list=false)
			nl = Episodey.nl
			tab = Episodey.tab
			media_count = !@media.nil? ? @media.length : 0
			header = "[#{self.id}] [#{self.u_id}, #{self.name}, #{media_count} Episodes]#{nl}"
			print header.colorize(:light_green)

			if include_media_list
				self.list_media
			end
			puts nl
		end

		# prints media list.
		# @return [nil]
		def list_media
			nl = Episodey.nl
			tab = Episodey.tab
			@media.each do |m|
				print tab + m.info(2)
			end
		end

		# returns true if this media-set is not currently saved to the database
		# @return [Boolean] true on if object is new, false if it isn't
		def is_new?
			return false if !@id.nil?
			if Episodey::DB::MediaSet.find_by_u_id(@u_id)
				return false
			end

			return true
		end

		# save this MediaSet & its Media list to the database
		#
		# @param new_only [Boolean] true if it should only save new media sets
		#
		# @return [Boolean] true on success.  false if MediaSet object has not been initialized.  raises Exception on failure.
		def save(new_only=false)
			if !self.is_initialized
				return false
			end

			if !new_only || (new_only && self.is_new?)
				r = Episodey::MediaSet.object_to_db([self])[0]
				r.save

				@id = @id.nil? ? r.id : @id
			end

			#save media list
			@media.each do |m|
				m.save new_only
			end
			
		
			return !@id.nil?
		end
	end
end
