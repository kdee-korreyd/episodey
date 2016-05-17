####################################################################
#BUGS & FIXES      
####################
#2016-04-07 - korreyd - 
#	bug: page 1 returns nothing during scan to some websites
#	fix [episodey.rb]: allowed following redirects [only 1 will be followed for now]
#
#2016-04-07 - korreyd - 
#	bug: incorrect media being returned and Media @u_id/@name mismatch
#	fix [media-set.rb]: had = instead of == in MediaSet.find_media comparison
#
#2016-05-16 - korreyd - 
#	bug: sqlite db interaction is pretty slow
#	proposed solution: create db indexes & surround sqlite interaction within a transation
####################################################################
require 'active_support/all'

#the main Episodey module
module Episodey
	# @!attribute nl
	#   @return [String] global newline
	mattr_accessor :nl do
		"\n"
	end
	# @!attribute tab
	#   @return [String] global tab
	mattr_accessor :tab do
		" "*3
	end

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

		# get all scannable websites.  scannable websites are determined by xreffing {#scan_cfg} with {#websites}
		# @return [Hash<Episodey::Website>] hash of {Episodey::Website}s. key => {Base#u_id}. raise Exception on failure.
		def get_scannable_websites
			scannable = {}
			@websites.each do |k,v|
				@scan_cfg.websites.each do |regex|
					re = Regexp.new(regex)
					if v.u_id.match(re)
						scannable[v.u_id] = v
						break
					end
				end
			end
			return scannable
		end

		# get all scannable media_sets.  scannable media_sets are determined by xreffing {#scan_cfg} with {#media_sets}
		# @return [Hash<Episodey::MediaSet>] hash of {Episodey::MediaSet}s. key => {Base#u_id}. raise Exception on failure.
		def get_scannable_media_sets
			scannable = {}
			@media_sets.each do |k,v|
				@scan_cfg.media_sets.each do |regex|
					re = Regexp.new(regex)
					if v.u_id.match(re)
						scannable[v.u_id] = v
						break
					end
				end
			end
			return scannable
		end

		# scan websites specified in scan config for media sets specified in 
		# scan config.  Loads {#new_media} with any new media found by the scan.
		# Also adds notifications about new media to {#new_notifications}
		# @return [Array<Object>] this instances {#new_media} attribute. raise Exception on failure.
		def scan
			new_media = []
			scannable_w = self.get_scannable_websites
			scannable_ms = self.get_scannable_media_sets
			page_limit = Episodey::Session.config_get_page_limit
			page_limit = 1 if page_limit < 1

			#only scan the keys necessary to find the media we want
			search_url_keys = {}
			@media_sets.each do |k,v|
				v.search_url_keys.each do |url_key|
					search_url_keys[url_key] = true
				end
			end

			#crawl sites and get postings	
			already_searched = {}
			postings = []
			scannable_w.each do |site_id,site|
				search_url_keys.each do |url_key,ignored|
					if site.urls[url_key] && !already_searched[site.urls[url_key]]
						(1..page_limit).each do |page|
							uri = site.generate_uri(url_key,page,nil)
							res = Net::HTTP.get_response(uri)

							#follow up to 1 redirect
							case res 
								when Net::HTTPRedirection then
									res = Net::HTTP.get_response(URI(res['location']))
							end
							html = res.body #[bug] not checking for errors in res

							postings.concat(Episodey::Website.html_to_postings(html))
							already_searched[site.urls[url_key]] = true
						end
					end
				end
			end

			#convert postings to media
			media_list = {}
			scannable_ms.each do |ms_id,ms|
				media_list[ms.u_id] = []
				postings.each do |posting|
					#[bug] since .matches updates the media.u_id I end up creating a bunch of
					#new Media objects that i never use (when they dont match)
					#  added if media.nil? and reset media to nil after its used so I don't keep recreating it when not necessary
					media = Episodey::Media.new if media.nil?
					if ms.matches?(posting.html,true,media)
						media.set_posting(posting)
						media.name = media.u_id
						media_list[ms.u_id] << media
						media = nil
					end
				end
			end

			#remove any media which we already have
			#check against @media_sets and against the db for media with the same u_id	
			media_list.each do |ms_k,ms_v|
				ms_v.each do |m|
					keep = true
					#check db first because this can be done with a quick query
					if Episodey::DB::Media.find_by_u_id(m.u_id)
						keep = false
					end

					#currently checks only media in the same media set
					#in reaility media.u_id should be uniqe across all media no matter the media set
					if keep && !@media_sets[ms_k].nil? && !@media_sets[ms_k].media.nil?
						if @media_sets[ms_k].find_media_by_u_id(m.u_id)
							keep = false
						end
					end

					if keep
						@media_sets[ms_k].add_media(m)
						new_media << m
					end
				end
			end

			@new_media = [] if @new_media.nil?
			@new_media.concat new_media

			@new_notifications = [] if @new_notifications.nil?
			@new_notifications.concat self.create_notifications(@new_media)
			#puts @new_notifications.to_yaml

			return @new_media
		end

		# use the notify() method of each {Episodey::Media} object in the media_list param to generate notifications.
		# results are appended to {#new_notifications}
		# @param media_list [Array<Episodey::Media>] array of {Episodey::Media}. [default => {#new_media}]
		# @return [Array<Episodey::Notification>] array of {Episodey::Notification}s returned by the notify() calls. raise Exception on failure.
		def create_notifications(media_list)
			notifications = []
			media_list.each do |m|
				n = m.notify
				notifications << n if n
			end
			return notifications
		end

		
		# [bug], the functionality this method would have provided is already handled by {#scan}
		# done in #scan get matched media from the list passed in.  matched media is determined by xreffing {#scan_cfg} with
		# the media list passed in to the media_list param
		# @param media_list [Array<Episodey::Media>] array of {Episodey::Media} to check for matches on. [default => {#new_media}]
		# @return [Array<Episodey::Media>] array of {Episodey::Media}. raise Exception on failure.
		def get_matched_media(media_list)
		end

		# [bug], the functionality this method would have provided is already handled by {#scan}
		# return a list of media from media_list param with any records which are already saved
		# to the database excluded.  
		#
		# note: Media records must have a valid {Episodey::Media#media_set} value set in order to be able to properly check the database for duplicates.
		# @param media_list [Array<Episodey::Media>] array of {Episodey::Media} to check for duplicates on. [default => {#new_media}]
		# @return [Array<Episodey::Media>] array of {Episodey::Media} with duplicates excluded. raise Exception on failure.
		def remove_media_duplicates(media_list)
		end

		# sends out any unsent notifications.  grouped means notificaion records will be 
		# consolidated and sent per user.  Each user receives 1 email.
		# @param new_only [Boolean] true if only new notifications should be sent
		# @param save [Boolean] true if notifications should be saved
		#
		# sends from both {#new_notifications} and any notifications saved in the db
		# @return [Array] list of [Episodey::Notification] objects which were sent
		def send_notifications_grouped(new_only=false,save=false)
			if !new_only
				db_n = Episodey::DB::Notification.find_unsent
				db_n = Episodey::Notification.db_to_object(db_n)
			end
			n = (db_n || []) + (@new_notifications || [])

			begin
				r = Episodey::Notification.send_grouped(n)

				#save notifications
				Episodey::Notification.save_all(n, new_only) if save
			rescue
				n = []
			end

			return n
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
		#     cfg_type options are: [scan, website, media_set]
		#   @param cfg_type [String] the type of config file you are loading.
		#   @param cfg_path [String] path to config file (not directory) for the specified cfg_type.
		#
		# @return [Episodey::ScanCfg] created {Episodey::ScanCfg} object.  raises Exception on failure.
		def load(*args)
			cfg_path = nil
			cfg_type = nil
			scan_cfg_path = ""
			websites_cfg_path = ""
			media_sets_cfg_path = ""

			if ( args.length == 1 )
				cfg_path = args[0]
			elsif ( args.length == 2 )
				cfg_path = args[1]
				cfg_type = args[0]
			else
				raise Exception,"Wrong number of arguments"
			end

			#load configs
			if ( cfg_type.nil? )	
				scan_cfg_path = cfg_path
				websites_cfg_path = "#{scan_cfg_path}/websites"
				media_sets_cfg_path = "#{scan_cfg_path}/media_sets"
				websites = {}
				media_sets = {}

				#scan
				if File.exists?("#{scan_cfg_path}/scan.cfg")
					@scan_cfg = Episodey::ScanCfg.new("#{scan_cfg_path}/scan.cfg")
				end

				#websites
				w_config_count = 0
				Dir.foreach(websites_cfg_path) do |f| 
					if !File.directory?(f) && !f.match(/.cfg$/).nil? 
						websites.merge! Episodey::Website.load_cfg("#{websites_cfg_path}/#{f}")
						w_config_count += 1
					end
				end

				#media sets
				ms_config_count = 0
				Dir.foreach(media_sets_cfg_path) do |f| 
					if !File.directory?(f) && !f.match(/.cfg$/).nil? 
						media_sets.merge! Episodey::MediaSet.load_cfg("#{media_sets_cfg_path}/#{f}")
						ms_config_count += 1
					end
				end

				#load db info
				@websites = Episodey::Website.load_db(websites)
				@media_sets = Episodey::MediaSet.load_db(media_sets)
			else	
				if File.exists?(cfg_path)
					case cfg_type
					when "scan"
						@scan_cfg = Episodey::ScanCfg.new(cfg_path)
					when "website"
						@websites = {} if @websites.nil?
						@websites.merge! Episodey::Website.load_cfg(cfg_path)
					when "media_set"
						@media_sets = {} if @media_sets.nil?
						@media_sets.merge! Episodey::MediaSet.load_cfg(cfg_path)
					else
						raise Exception, "Unknown config type given."
					end
				else
					raise Exception, "The given config file does not exist"
				end
			end
		end

		# save current session (media sets/media, websites) to db
		#  this method will not save notifications
		#
		# @param types [Array] list of object types to save [media,media-sets,websites,all]
		# @param new_only [Boolean] true if it should only save new objects
		#
		# @return [Hash] depicting a count of how many of each type were saved
		def save(types=["all"],new_only=false)
			r = {media_sets:0,media:0,websites:0}

			if !(types & ["all","media-sets","media"]).empty?
				if !@media_sets.nil?
					@media_sets.each do |key,ms|
						ms.save new_only
						r[:media_sets] += 1
						r[:media] += (ms.media || []).length
					end
				end
			end

			if !(types & ["all","websites"]).empty?
				if !@websites.nil?
					@websites.each do |key,w|
						w.save new_only
						r[:websites] += 1
					end
				end
			end

			return r
		end

		# runs {#save} and then runs {#clear}
		# @return [Hash] depicting a count of how many of each type were saved see {#save}
		def flush
			r = self.save
			self.clear_scan_data
			return r
		end

		# clear out any currently saved scan information.
		# reinitializes {#new_media} and {#new_notifications}
		# @return [nil]
		def clear_scan_data
			@new_media = nil
			@new_notifications = nil
		end
		alias_method :clear, :clear_scan_data

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

		# checks to see if this object is initialize.  this is the most basic initialization check.
		#   you may just override this method to change the init check for any subclass which inherits {Base}
		# @return [Boolean] true if initialized, false if not initialized
		def is_initialized
			if self.u_id.to_s.empty?
				return false
			end	
			return true
		end
	end

	#ScanCfg parses and hold scan config
	class ScanCfg
		# @!attribute media_sets
		#   @return [Array<String>] regex list of media set to search (by {Base#u_id})
		attr_accessor :media_sets

		# @!attribute websites
		#   @return [Array<String>] regex list of websites to search (by {Base#u_id})
		attr_accessor :websites

		# constructor
		# @param cfg_path [String] path to config file (actual file, not the directory)
		# @return [ScanCfg] new ScanCfg instance
		def initialize(cfg_path)
			self.load(cfg_path)
		end

		# initialize ScanCfg with contents of cfg_path
		# @param cfg_path [String] path to config file (actual file, not the directory)
		# @return [ScanCfg] new ScanCfg instance
		def load(cfg_path)
			file = File.read(cfg_path)
			d = JSON.parse(file)
			@media_sets = d["media_sets"]
			@websites = d["websites"]
			return self
		end
	end

	# create a new episodey object
	# @return [Episodey::App] a new episodey object
	def self.Episodey
		self::App.new
	end

	#this module holds information about the active user
	module Session
		mattr_accessor :email_on do
			false
		end

		mattr_accessor :config do
			{}			
		end

		mattr_accessor :user

		# set the currently active user by id
		# @param id [Integer] the user id to set as the active user
		# @return [Episodey::DB::User] if user was set successfully
		# @return [false] if the user could not be found 
		def self.set_user_by_id(id)
			begin
				user = Episodey::DB::User.find(id)
			rescue Exception => e
				return false
			end

			self.user = user
			return user
		end

		# set the currently active user by email address
		# @param email [String] the email to set as the active user
		# @return [Episodey::DB::User] if user was set successfully
		# @return [false] if the user could not be found 
		def self.set_user_by_email(email)
			begin
				user = Episodey::DB::User.find_by_email(email)
			rescue Exception => e
				return false
			end

			self.user = user
			return user
		end

		# load config file into {#config}.  if path is nil it will look for episodey.yml in the exe directory
		# @param path [String] path to the episodey config file (.yml format) to load.  nil for default.
		# @return [Hash] populated {Episodey::Session.config}.  raises Exeption if config file not found
		def self.load_config(path=nil)
			path = "./episodey.yml" if path.nil?
			self.config = YAML.load(File.read(path))
		end

		# [bug] page_limit should be moved to ScanCfg
		# gets the page limit from the config options
		# @return [Integer] page limit
		def self.config_get_page_limit
			return !self.config[:options].nil? && !self.config[:options][:page_limit].nil? ? self.config[:options][:page_limit] : 1
		end
	end
end

require 'mail'
require 'net/http'
require 'colorize'
require_relative 'episodey/user'
require_relative 'episodey/db'
require_relative 'episodey/media'
require_relative 'episodey/media-set'
require_relative 'episodey/posting'
require_relative 'episodey/website'
require_relative 'episodey/notification'


