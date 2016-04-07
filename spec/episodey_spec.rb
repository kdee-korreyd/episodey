require_relative "../test/test_helper"

describe Episodey::DB do
	describe "after initialization" do
		before do
		end

		describe "db_adapter" do
			it "should equal 'sqlite3'" do
				Episodey::DB.db_adapter.must_equal('sqlite3') 
			end
		end
		describe "db_name" do
			it "should equal 'default.db'" do 
				Episodey::DB.db_name.must_equal('test/test.db') 
			end
		end
	end

	describe "after DB.sqlite_update_schema" do
		before do
			#get a db handler
			@db = SQLite3::Database.open Episodey::DB.db_name
		end

		after do
			#puts "closing db"
			#close db
			@db.close if @db
		end

		describe "db schema" do
			it "should have created all tables" do
				@db.execute( "select * from websites" )
				@db.execute( "select * from media_sets" )
				@db.execute( "select * from media" )
				@db.execute( "select * from postings" )
				@db.execute( "select * from notifications" )
				@db.execute( "select * from users" )
			end
		end

		describe "active record" do
			before do
				if !Episodey::Test.test_data
					#Episodey::Test.test_data = true
					#Episodey::Test.create_test_data
				end
			end

			describe "sqlite3: PRAGMA foreign_keys" do
				it "should be enabled" do
					rows = ActiveRecord::Base.connection.execute( "PRAGMA foreign_keys" )
					rows[0]['foreign_keys'].must_equal(1)
				end
			end

			it "should allow cascading deletes" do
				Episodey::DB::MediaSet.delete(1)
				assert_raises ActiveRecord::RecordNotFound do
					Episodey::DB::Posting.find(1)
				end
			end

			it "should allow insert" do
				d = nil
				begin
					d = Episodey::DB::MediaSet.find(2)
				ensure
					d.wont_be_nil.must_equal false
				end
			end
			
			it "should allow update" do
				d = Episodey::DB::MediaSet.find(2)
				d.name = 'changed'
				d.save

				d = nil
				begin
					d = Episodey::DB::MediaSet.find(2)
				ensure
					d.wont_be_nil.must_equal false
					d.name.must_equal 'changed'
				end
			end

			describe Episodey::DB::Website do
				it "should be able to create an instance" do
					d = Episodey::DB::Website.new
					d.wont_be_nil.must_equal false
				end
			end
			describe Episodey::DB::MediaSet do
				it "should be able to create an instance" do
					d = Episodey::DB::MediaSet.new
					d.wont_be_nil.must_equal false
				end
			end
			describe Episodey::DB::Media do
				it "should be able to create an instance" do
					d = Episodey::DB::Media.new
					d.wont_be_nil.must_equal false
				end
			end
			describe Episodey::DB::Posting do
				it "should be able to create an instance" do
					d = Episodey::DB::Posting.new
					d.wont_be_nil.must_equal false
				end
			end
			describe Episodey::DB::Notification do
				it "should be able to create an instance" do
					d = Episodey::DB::Notification.new
					d.wont_be_nil.must_equal false
				end
			end
			describe Episodey::DB::User do
				it "should be able to create an instance" do
					d = Episodey::DB::User.new
					d.wont_be_nil.must_equal false
				end
			end
		end
	end
end


describe Episodey::MediaSet do
	describe "load_cfg" do
		it "should return media sets loaded from a config file" do
			d = Episodey::MediaSet.load_cfg 'spec/config/media_sets/elementary.cfg'
			d.wont_be_nil.must_equal false
		end
	end

	describe "load_db" do
		it "should load several records from the db" do
			d = Episodey::MediaSet.load_db nil
			assert_operator d.length, :>, 0
		end

		it "should load corresponding media list" do
			d = Episodey::MediaSet.load_db nil
			assert_operator d[0].media.length, :>, 0
		end
	end

	describe "add_media" do
		it "should increase the media length by 1" do
			ms = Episodey::MediaSet.new
			c = ms.media.length
			ms.add_media(Episodey::Media.new)
			ms.media.length.must_equal c+1
		end
	end

	describe "save" do
		it "should save to the db" do
			r = Episodey::MediaSet.new
			r.u_id = 'testing_save'
			r.name = 'Testing Save'
			r.search = ['testsumpn']
			r.id_format_string = ['testsumpn_s(01)e(01)']
			r.default_media_class = 'TV'
			r.save

			d = nil
			begin
				d = Episodey::DB::MediaSet.find(r.id)
			rescue
				d.wont_be_nil.must_equal false
			end
		end
	end
end

describe Episodey::Website do
	describe "load_cfg" do
		it "should return websites loaded from a config file" do
			d = Episodey::Website.load_cfg 'spec/config/websites/example.cfg'
			d.wont_be_nil.must_equal false
		end
	end

	describe "html_to_postings" do
		it "should return several records" do
			html = "<a href='http://url1.com'>url1</a><a href='http://url2.com'>url2</a>"
			d = Episodey::Website.html_to_postings html
			assert_operator d.length, :>, 0
		end
	end

	describe "save" do
		it "should save to the db" do
			r = Episodey::Website.new
			r.u_id = 'testsave.com'
			r.name = 'Test Save'
			r.urls = {"home": "testsave.com"}
			r.save

			d = nil
			begin
				d = Episodey::DB::Website.find(r.id)
			rescue
				d.wont_be_nil.must_equal false
			end
		end
	end
end

describe Episodey::Media do
	before do
		#get the test media set
		m = Episodey::DB::MediaSet.find(3)
		@media_set = Episodey::MediaSet.new
		@media_set.id = m.id
		@media_set.name = m.name
		@media_set.u_id = m.u_id
		@media_set.default_media_class = m.default_media_type
		@media_set.id_format_string = m.identity_format_str
	end

	describe "set_posting" do
		it "should set posting reference and should update postings media reference" do
			p = Episodey::Posting.new "http://cfp.com"
			p.html = "<a href='http://url1.com'>url1</a>"
			m = Episodey::Media.new
			m.set_posting p

			m.posting.object_id.must_equal p.object_id
			p.media.object_id.must_equal m.object_id
		end
	end

	describe "notify" do
		it "should return a new Notification object" do
			r = Episodey::Media.new
			r.u_id = 'testsave_s01e01'
			r.name = 'Test Save Season 1 Episode 1'
			r.media_set = @media_set
			n = r.notify
			n.class.must_equal Episodey::Notification
		end
	end

	describe "save" do
		it "should save to the db" do
			r = Episodey::Media.new
			r.u_id = 'testsave_s01e01'
			r.name = 'Test Save Season 1 Episode 1'
			r.media_set = @media_set
			#r.posting = @posting
			r.save

			d = nil
			begin
				d = Episodey::DB::Media.find(r.id)
			rescue
				d.wont_be_nil.must_equal false
			end
		end
	end
end

describe Episodey::Posting do
	describe "save" do
		it "should save to the db" do
			r = Episodey::Posting.new "http://url1.com"
			r.html = "<a href='http://url2.com'>url2</a>"
			r.media = @media
			#r.posting = @posting
			r.save

			d = nil
			begin
				d = Episodey::DB::Posting.find(r.id)
			rescue
				d.wont_be_nil.must_equal false
			end
		end
	end
end

describe Episodey::Notification do
	describe "save" do
		it "should save to the db" do
			r = Episodey::Notification.new
			r.subject = "test"
			r.message = "this is just a test notification"
			#r.user = @user
			#r.media = @media
			r.save

			d = nil
			begin
				d = Episodey::DB::Notification.find(r.id)
			rescue
				d.wont_be_nil.must_equal false
			end
		end
	end

	describe "send" do
		it "should successfully send a notification" do
			u = Episodey::User.new 'Test', 'kdeebug.info@gmail.com'

			m = Episodey::Media.new
			m.u_id = 'testsave_s01e01'
			m.name = 'Test Save Season 1 Episode 1'

			n = Episodey::Notification.new
			n.subject = "test"
			n.message = "this is just a test notification"
			n.media = m
			n.user = u

			n.send.must_equal true
		end
	end

	describe "send_grouped" do
		it "should successfully send all unsent notifications (consolidated). 1 notification per user." do
			u = Episodey::User.new 'Test', 'kdeebug.info@gmail.com'
			u2 = Episodey::User.new 'Test2', 'korreyd@abstractspacecraft.com'

			m = Episodey::Media.new
			m.u_id = 'testsave_s01e01'
			m.name = 'Test Save Season 1 Episode 1'

			notifications = []
			n = Episodey::Notification.new
			n.subject = "test"
			n.message = "this is just a test notification"
			n.media = m
			n.user = u
			notifications  << n
			n = Episodey::Notification.new
			n.subject = "test2"
			n.message = "this is just a test notification2"
			n.media = m
			n.user = u
			notifications  << n
			n = Episodey::Notification.new
			n.subject = "test"
			n.message = "this is just a test notification"
			n.media = m
			n.user = u2
			notifications  << n
			n = Episodey::Notification.new
			n.subject = "test2"
			n.message = "this is just a test notification2"
			n.media = m
			n.user = u2
			notifications  << n

			r = Episodey::Notification.send_grouped notifications
			r.must_equal 2
		end
	end
end

describe Episodey::User do
	describe "save" do
		it "should save to the db" do
			r = Episodey::User.new 'Test', 'kdeebug.info@gmail.com'
			r.save

			d = nil
			begin
				d = Episodey::DB::User.find(r.id)
			rescue
				d.wont_be_nil.must_equal false
			end
		end
	end
end

describe Episodey::ScanCfg do
	describe "load" do
		it "should load scan config" do
			d = Episodey::ScanCfg.new 'spec/config/scan.cfg'
			d.wont_be_nil.must_equal false
		end
	end
end


