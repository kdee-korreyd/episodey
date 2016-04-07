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
=begin
			media_sets = {}
			file = File.read(cfg_path)
			p = JSON.parse(file)
			p.each do |ms|
				m = self.new
				m.name = ms["name"]
				m.u_id = ms["u_id"]
				m.search = ms["search"]
				m.search_url_keys = ms["search_url_keys"]
				m.default_media_class = ms["default_media_class"]
				m.id_format_string = ms["id_format_string"]
				media_sets[m.u_id] = m
			end
			return media_sets
=end
		end

		# load {MediaSet}s from the database and merge them into media_set_list.  Also loads corresponding media into the MediaSet.
		# @param media_set_list [Array<MediaSet>] the MediaSet list to merge db list with.  in the case of duplicate MediaSet entries (denoted by {#u_id}), media_set_list has priority. [default => []]j
		# @return [Array<MediaSet>] media_set_list merged with db info. raises Exception on failure.
		def self.load_db(media_set_list)
=begin
			ms = []
			d = Episodey::DB::MediaSet.all
			d.each do |x|
				m = Episodey::MediaSet.new
				m.name = x.name
				m.u_id = x.u_id
				m.media << [Episodey::Media.new]
				ms << m
			end
			return ms
=end
		end

		# prints media set information (and optionally its media list).
		# @param include_media_list [Boolean] if true then the media_list for each set is printed as well
		# @return [nil]
		def info(include_media_list)
		end

		# prints media list.
		# @return [nil]
		def list_media
		end

		# save this MediaSet & its Media list to the database
		# @return [Integer] number of MediaSets saved. raises Exception on failure.
		def save
=begin
			Episodey::DB::MediaSet.create(
				:u_id => self.u_id,
				:name => self.name,
				:default_media_type => self.default_media_class,
				:search_regex_json => self.search.to_json,
				:identity_format_str => self.id_format_string,
				:object_yaml => self.to_yaml
			)
=end
		end
	end
end
