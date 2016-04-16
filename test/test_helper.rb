require "minitest/reporters"
require 'minitest/autorun'
require 'episodey'


#Minitest::Reporters.use!
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
#Minitest::Reporters.use! Minitest::Reporters::ProgressReporter

module Episodey
	module Test
		mattr_accessor :smtp_config do
			{ 
				:address => 'smtp.gmail.com', 
				:port => 587, 
				:domain => 'gmail.com', 
				:user_name => 'user'
				:password => 'pass', 
				:enable_starttls_auto => true, 
				:openssl_verify_mode => 'none' 
			}
		end

		mattr_accessor :debug_email do
			"debug@example.com"
		end

		mattr_accessor :test_data do
			false
		end

		mattr_accessor :app

		def self.generate_notification_object(oid)
			oid = oid.nil? ? "notification-" + rand(99999).to_s : oid
			d = Episodey::Notification.new
			d.user_id = 2
			d.subject = "#{oid}"
			d.message = "#{oid} This is the message"
			d.is_sent = 0
			return d
		end

		def self.generate_posting_object(oid)
			oid = oid.nil? ? "posting-" + rand(99999).to_s : oid
			d = Episodey::Posting.new("http://#{oid}.com")
			d.u_id = "#{oid}"
			d.name = "#{oid}"
			return d
		end

		def self.generate_media_object(oid)
			oid = oid.nil? ? "media-" + rand(99999).to_s : oid
			d = Episodey::TV.new
			d.u_id = "#{oid}_s01e01"
			d.name = "#{oid}_s01e01"
			return d
		end

		def self.generate_media_set_yaml(oid)
			oid = oid.nil? ? "media-set-" + rand(99999).to_s : oid
			return <<-YAMLSTR
--- !ruby/object:Episodey::MediaSet
media: []
name: #{oid}
u_id: #{oid}
default_media_class: Episode
id_format_string: #{oid}_%02de%02d
search:
- #{oid}.*s(d{1,2})[^d]*(d{1,2})
- #{oid}.*season(d{1,2})[ ]*episode(d{1,2})
search_url_keys:
- home
- shows
YAMLSTR
		end

		def self.create_test_data
			puts "creating test DATA"

			#websites
			ActiveRecord::Base.connection.execute( "DELETE from websites" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='websites'" )
			Episodey::DB::Website.create(
				:u_id => 'test',
				:name => 'Test',
				:urls_yaml => {
					:home => 'http://test.com',
					:shows => 'http://test.com/shows',
					:movies => 'http://test.com/movies',
					:rss => 'http://test.com/rss'
				}.to_yaml
			)
			Episodey::DB::Website.create(
				:u_id => 'example',
				:name => 'Example',
				:urls_yaml => {
					:home => 'http://example.com',
					:shows => 'http://example.com/shows',
					:movies => 'http://example.com/movies',
					:rss => 'http://example.com/rss'
				}.to_yaml
			)

			#media sets
			ActiveRecord::Base.connection.execute( "DELETE from media_sets" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='media_sets'" )
			Episodey::DB::MediaSet.create(
				:u_id => 'new_girl',
				:name => 'New Girl',
				:search_regex_json => [
					'new.girl.*',
					'new.girl.season*'
				].to_json,
				:identity_format_str => 'new.girl.s(01)e(01)',
				:object_yaml => Episodey::Test.generate_media_set_yaml(nil)
			)
			Episodey::DB::MediaSet.create(
				:u_id => 'elementary',
				:name => 'Elementary',
				:search_regex_json => [
					'elementary.*',
					'elementary.season*'
				].to_json,
				:identity_format_str => 'elementary.s(01)e(01)',
				:object_yaml => Episodey::Test.generate_media_set_yaml("elementary")
			)
			Episodey::DB::MediaSet.create(
				:u_id => 'media_testing',
				:name => 'Media Testing',
				:search_regex_json => [
					'm.t.*',
					'm.t.s*'
				].to_json,
				:identity_format_str => 'm.t.s(01)e(01)',
				:object_yaml => Episodey::Test.generate_media_set_yaml(nil)
			)

			#media
			ActiveRecord::Base.connection.execute( "DELETE from media" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='media'" )
			m = Episodey::Test.generate_media_object("elementary")
			Episodey::DB::Media.create(
				:u_id => m.u_id,
				:name => m.name,
				:media_set_id => 1,
				:media_type => m.class.name[/::([^:]+)$/,1],
				:object_yaml => m.to_yaml
			)
			m = Episodey::Test.generate_media_object("newgirl")
			Episodey::DB::Media.create(
				:u_id => m.u_id,
				:name => m.name,
				:media_set_id => 3,
				:media_type => m.class.name[/::([^:]+)$/,1],
				:object_yaml => m.to_yaml
			)
			m = Episodey::Test.generate_media_object("blacklist")
			Episodey::DB::Media.create(
				:u_id => m.u_id,
				:name => m.name,
				:media_set_id => 3,
				:media_type => m.class.name[/::([^:]+)$/,1],
				:object_yaml => m.to_yaml
			)
			m = Episodey::Test.generate_media_object("marvels")
			Episodey::DB::Media.create(
				:u_id => m.u_id,
				:name => m.name,
				:media_set_id => 3,
				:media_type => m.class.name[/::([^:]+)$/,1],
				:object_yaml => m.to_yaml
			)

			#postings
			ActiveRecord::Base.connection.execute( "DELETE from postings" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='postings'" )
			Episodey::DB::Posting.create(
				:media_id => 1,
				:link => 'http://elementary.com/elementary',
			)
			Episodey::DB::Posting.create(
				:media_id => 2,
				:link => 'http://elementary.com/elementaryagain',
			)
			Episodey::DB::Posting.create(
				:media_id => 3,
				:link => 'http://elementary.com/elementaryagain2',
			)
			Episodey::DB::Posting.create(
				:media_id => 4,
				:link => 'http://elementary.com/elementaryagain3',
			)

			#users
			ActiveRecord::Base.connection.execute( "DELETE from users" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='users'" )
			Episodey::DB::User.create(
				:name => "Scanlan Shorthalt",
				:email => "scanlan@shorthald.com"
			)
			Episodey::DB::User.create(
				:name => "Grog Strongjaw",
				:email => "grog@strongjaw.com"
			)

			#notifications
			ActiveRecord::Base.connection.execute( "DELETE from notifications" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='notifications'" )
			n = Episodey::Test.generate_notification_object(nil)
			Episodey::DB::Notification.create(
				:user_id => n.user_id,
				:media_id => n.media_id,
				:subject => n.subject,
				:message => n.message,
				:is_sent => n.is_sent,
			)
			n = Episodey::Test.generate_notification_object(nil)
			Episodey::DB::Notification.create(
				:user_id => n.user_id,
				:media_id => n.media_id,
				:subject => n.subject,
				:message => n.message,
				:is_sent => n.is_sent,
			)
			n = Episodey::Test.generate_notification_object(nil)
			Episodey::DB::Notification.create(
				:user_id => 1,
				:media_id => n.media_id,
				:subject => n.subject,
				:message => n.message,
				:is_sent => n.is_sent,
			)

			ActiveRecord::Base.connection.execute( "VACUUM" )
		end
	end
end

if !Episodey::Test.test_data
	Episodey::Test.test_data = true
	Episodey::Test.app = Episodey::App.new
	Episodey::DB.db_name = 'test/test.db'

	#update schema
	Episodey::DB.sqlite_update_schema
	#connect active record to db
	Episodey::DB.active_record_connect
	#debug set user
	Episodey::Session.set_user_by_id(1)
	#recreated some data
	Episodey::Test.create_test_data
end
