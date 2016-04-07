require "minitest/reporters"
require 'minitest/autorun'
require 'episodey'


#Minitest::Reporters.use!
Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
#Minitest::Reporters.use! Minitest::Reporters::ProgressReporter

module Episodey
	module Test
		mattr_accessor :test_data do
			false
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
				:u_id => 'elementary',
				:name => 'Elementary',
				:search_regex_json => [
					'elementary.*',
					'elementary.season*'
				].to_json,
				:identity_format_str => 'elementary.s(01)e(01)',
				:object_yaml => {:test => 1}.to_yaml
			)
			Episodey::DB::MediaSet.create(
				:u_id => 'new_girl',
				:name => 'New Girl',
				:search_regex_json => [
					'new.girl.*',
					'new.girl.season*'
				].to_json,
				:identity_format_str => 'new.girl.s(01)e(01)',
				:object_yaml => {:test => 2}.to_yaml
			)
			Episodey::DB::MediaSet.create(
				:u_id => 'media_testing',
				:name => 'Media Testing',
				:search_regex_json => [
					'm.t.*',
					'm.t.s*'
				].to_json,
				:identity_format_str => 'm.t.s(01)e(01)',
				:object_yaml => {:test => 3}.to_yaml
			)

			#media
			ActiveRecord::Base.connection.execute( "DELETE from media" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='media'" )
			Episodey::DB::Media.create(
				:u_id => 'elementary_s01e01',
				:name => 'Elementary s01e01',
				:media_set_id => 1,
				:media_type => 'TV',
				:object_yaml => {:test => 1}.to_yaml
			)
			Episodey::DB::Media.create(
				:u_id => 'newgirl_s01e01',
				:name => 'NewGirl s01e01',
				:media_set_id => 2,
				:media_type => 'TV',
				:object_yaml => {:test => 2}.to_yaml
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

			#users
			ActiveRecord::Base.connection.execute( "DELETE from users" )
			ActiveRecord::Base.connection.execute( "DELETE from sqlite_sequence where name='users'" )

			ActiveRecord::Base.connection.execute( "VACUUM" )
		end
	end
end

if !Episodey::Test.test_data
	Episodey::Test.test_data = true

	Episodey::DB.db_name = 'test/test.db'

	#update schema
	Episodey::DB.sqlite_update_schema
	#connect active record to db
	Episodey::DB.active_record_connect
	#recreated some data
	Episodey::Test.create_test_data
end
