require 'abstraction'

module Episodey
	# adding classes to this module can alter the functionality of the Episodey scanner
	module Mod
		# @!attribute active_mods
		#   @!scope class
		#   @return list of all currenly active mods
		@@active_mods = []

		# @abstract the base Mod class.  create mods by inheriting this class and
		#   overwriting this abstract classes methods.
		class Base
			abstract

			# called at the very beginning {Episodey::App#scan}
			#   the scan_cfg may be directly modified from this method.  It will modify the calling instances {Episodey::App#scan_cfg} attribute.
			# @param app [Episodey::App] calling instance
			# @param websites [Array<Episodey::Website>] list of websites available to scan.
			# @param scan_cfg [Episodey::ScanCfg] scan config object
			# @return [Array<Episodey::Website>] if modder wants to run scan on a modified list of websites
			# @return [nil] if modder does not want to modify the website list
			def pre_scan(app,websites,scan_cfg)
			end

			# called at the very end of {Episodey::App#scan}
			# @param app [Episodey::App] calling instance
			# @param media [Episodey::Media] list of media returned by the scan/filter.
			# @return [Array<Episodey::Media>] if modder wants to modify the media list 
			# @return [nil] if modder does not want to modify the website list
			def post_scan(app,media)
			end

			# overrides default {Episodey::Episodey::Website#html_to_postings} functionality during a scan.
			# @param app [Episodey::App] calling instance
			# @param html [String] html to parse for postings
			# @return [Array<Episodey::Posting>] if modder wants to modify the postings list
			# @return [nil] if modder does not want to modify the postings list and would like to continue with default html_to_postings functionality
			def html_to_postings(app,html)
			end

			# overrides the default {Episodey::App#scan} functionality.
			# @param app [Episodey::App] calling instance
			# @param websites [Array<Episodey::Website>] list of websites available to scan.
			# @param scan_cfg [Episodey::ScanCfg] scan config object
			# @return [Array<Episodey::Media>,Boolean] scanned/filtered media list, 
			#   true if the original scan functionality should still run. false if scanning is complete.
			def scan(app,websites,scan_cfg)
			end

			# overrides default {Episodey::Episodey::Media#create_from_posting} functionality during a scan.
			# @param app [Episodey::App] calling instance
			# @param posting [Episodey::Posting] the posting to convert to media
			# @return [Episdoey::Media] if modder wants to convert this posting to media
			# @return [false] if does not want to handle conversion and would still like to skip default create_from_posting functionality.
			# @return [nil] if modder does not want to handle conversion and would like to continue with default create_from_posting functionality.
			def media_from_posting(app,posting)
			end
		end
	end
end
