#the main Episodey module
module Episodey
	#App is an episody instance, multiple instances are allowed
	class App
		# @!attribute new_media
		#   @return [Array] a list of new media available after {#scan}.
		attr_accessor :new_media

		# @!attribute new_notifications
		#   @return [Array] a list of unsaved notifications.
		attr_accessor :new_notifications

		# @!attribute websites
		#   this hash combines websites saved in the db along with any websites 
		#   specified in loaded website config files. 
		#   @return [Hash] all websites available to episodey instance. key = {Base#u_id}.
		attr_accessor :websites

		# @!attribute media_sets
		#   this hash combines media sets saved in the db along with any media sets 
		#   specified in loaded media set config files.
		#   @return [Hash] all websites available to episodey instance. key = {Base#u_id}.
		attr_accessor :media_sets

		# @!attribute scan_cfg
		#   ScanCfg object initialized with {#load}
		#   @return [Episodey::ScanCfg] 
		attr_accessor :scan_cfg

		# scan websites specified in scan config for media sets specified in 
		# scan config.  Loads {#new_media} with any new media found by the scan.
		# Also adds notifications about new media to {#new_notifications}
		# @return [Array<Object>] this instances {#new_media} attribute. raise Exception on failure.
		def scan
		end

		# clear out any currently saved scan information.
		# reinitializes {#new_media} and {#new_notifications}
		# @return [nil]
		def clear_scan_data
		end
		alias_method :clear, :clear_scan_data

		# sends out any unsent notifications.  grouped means notificaion records will be 
		# consolidated and sent per user.  Each user receives 1 email.
		#
		# sends from both {#new_notifications} and any notifications saved in the db
		# @return [nil]
		def send_notifications_grouped
		end
		alias_method :notify, :send_notifications_grouped

		# prints the contents of the media_list provided
		# @param media_list [Array] the media list to print. [default => {#new_media}]
		# @return [nil]
		def list_media(media_list)
		end
		alias_method :list, :list_media

		# prints media set information (with optional media_list).
		# if media_set is nil then all media sets will be printed.
		# @param media_set [Episodey::MediaSet] the media set to print info for. [default => all media sets]
		# @param include_media_list [Boolean] if true then the media_list for each set is printed as well
		# @return [nil]
		def print_media_set(media_set, include_media_list)
		end
		alias_method :info, :print_media_set

		# @overload load(cfg_path)
		#   initialize an {Episodey::App} object with config and database info. includes scan config, websites, and media sets.
		#   {#scan_cfg} is set to result.
		#     the config directory should contain: 
		#       scan.cfg
		#       media_sets/*.cfg 
		#       websites/*.cfg
		#
		#     multiple media_set and website configs are allowed.
		#   @param cfg_path [String] path to config directory.
		#
		# @overload load(cfg_type,cfg_path)
		#   initialize an {Episodey::App} specific config and/or database info.
		#     cfg_type options are: [scan, web, media_set]
		#   @param cfg_type [String] the type of config file you are loading.
		#   @param cfg_path [String] path to config file (not directory) for the specified cfg_type.
		#
		# @return [Episodey::ScanCfg] created {Episodey::ScanCfg} object.  raises Exception on failure.
		def load(*args)
		end

		# save current session (media sets/media, websites, notifications) to db
		# @return [nil]
		def save
		end

		# runs {#save} and then runs {#clear}
		# @return [nil]
		def flush
		end

		# enable a mod
		# @return [nil]
		def enmod
		end

		# disable a mod
		# @return [nil]
		def dismod
		end

		# list all available mods. optionally may list only enabled mods.
		# @param enabled_only [Boolean] if true then only list enabled mods
		# @return [nil]
		def list_mods(enabled_only)
		end

		# list all enabled mods.  same as {#list_mods}(true).
		# @return [nil]
		def list_enmods
		end

		# get all scannable websites.  scannable websites are determined by xreffing {#scan_cfg} with {#websites}
		# @return [Hash<Episodey::Website>] hash of {Episodey::Website}s. key => {Base#u_id}. raise Exception on failure.
		def get_scannable_websites
		end

		# get matched media from the list passed in.  matched media is determined by xreffing {#scan_cfg} with
		# the media list passed in to the media_list param
		# @param media_list [Array<Episodey::Media>] array of {Episodey::Media} to check for matches on. [default => {#new_media}]
		# @return [Array<Episodey::Media>] array of {Episodey::Media}. raise Exception on failure.
		def get_matched_media(media_list)
		end

		# return a list of media from media_list param with any records which are already saved
		# to the database excluded.  
		#
		# note: Media records must have a valid {Episodey::Media#media_set} value set in order to be able to properly check the database for duplicates.
		# @param media_list [Array<Episodey::Media>] array of {Episodey::Media} to check for duplicates on. [default => {#new_media}]
		# @return [Array<Episodey::Media>] array of {Episodey::Media} with duplicates excluded. raise Exception on failure.
		def remove_media_duplicates(media_list)
		end

		# use the notify() method of each {Episodey::Media} object in the media_list param to generate notifications.
		# results are appended to {#new_notifications}
		# @param media_list [Array<Episodey::Media>] array of {Episodey::Media}. [default => {#new_media}]
		# @return [Array<Episodey::Notification>] array of {Episodey::Notification}s returned by the notify() calls. raise Exception on failure.
		def create_notifications(media_list)
		end

		# this is just an example of how to document an options hash
		#
		# @param [Hash] opts the options to create a message with.
		# @option opts [String] :subject The subject
		# @option opts [String] :from ('nobody') From address
		# @option opts [String] :to Recipient email
		# @option opts [String] :body ('') The email's body
		def hash_options_example(opts = {}) end
	end

	#Base is the base class for episodey objects
	class Base
		# @!attribute id
		#   @return [Integer] the id for this Object in the Episodey database's corresponding table.  nil if this is not in the database.
		attr_accessor :id

		# @!attribute name
		#   @return [String] human readable name of this object.
		attr_accessor :name

		# @!attribute u_id
		#   the u_id is a string used to quickly refer to this particular object
		#   @return [String] unique identifier for this media set
		attr_accessor :u_id
	end

	# create a new episodey object
	# @return [Episodey::App] a new episodey object
	def Episodey
		self.App.new
	end
end
