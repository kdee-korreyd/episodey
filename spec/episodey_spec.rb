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

				describe "find_by_u_id" do
					it "should return a record" do
						d = Episodey::DB::Media.find_by_u_id('marvels_s01e01')
						d.wont_be_nil.must_equal false
					end
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
			d = Episodey::MediaSet.load_cfg 'spec/config/media_sets/example.cfg'
			d.wont_be_nil.must_equal false
		end

		it "should raise an Exception if u_id is empty" do
			assert_raises Exception do
				d = Episodey::MediaSet.load_cfg 'spec/config/media_sets/example.bad'
			end
		end
	end

	describe "db_to_object" do
		it "should return all corresponding media objects in media attribute" do
			db_media_set = Episodey::DB::MediaSet.find(3)
			ms = Episodey::MediaSet.db_to_object([db_media_set])[0]

			assert_operator ms.media.length, :>, 1
		end
	end

	describe "load_db" do
		it "should return all media sets loaded from the database" do
			d = Episodey::MediaSet.load_db nil
			assert_operator d.length, :>, 1
		end

		it "should replace existing db attributes with media set list passed in if u_id matches" do
			c = Episodey::MediaSet.load_cfg 'spec/config/media_sets/example.cfg'
			d = Episodey::MediaSet.load_db c
			d['elementary'].name.must_equal 'fromconfig'
		end

		it "should merge media set list passed in with media set loaded from db" do
			c = Episodey::MediaSet.load_cfg 'spec/config/media_sets/example.cfg'
			d = Episodey::MediaSet.load_db c
			r = nil
			begin
				r = d['extraexample']
			ensure
				r.wont_be_nil.must_equal false
			end
		end
	end

	describe "add_media" do
		it "should increase the media length by 1" do
			media = Episodey::Media.new
			media.u_id = "test"
			ms = Episodey::MediaSet.new
			c = ms.media.length
			ms.add_media(media)
			ms.media.length.must_equal c+1
			media.media_set.object_id.must_equal ms.object_id
		end

		it "should not re-add media with duplicate u_id" do
			media = Episodey::Media.new
			media.u_id = "test2"

			ms = Episodey::MediaSet.new
			c = ms.media.length
			ms.add_media(media)
			ms.media.length.must_equal c+1 #should add it

			ms.add_media(media)
			ms.media.length.must_equal c+1 #should not have added it again

			media2 = Episodey::Media.new
			media2.u_id = "test2"

			ms.add_media(media2)
			ms.media.length.must_equal c+1 #even a totally new object with the same u_id should be seen as a dup
		end
	end

	describe "find_media" do
		it "should return a media object found by u_id" do
			media = Episodey::Media.new
			media.u_id = "find_me"

			ms = Episodey::MediaSet.new
			ms.add_media(media)

			found = ms.find_media("find_me")
			found.wont_be_nil
			found.class.must_equal Episodey::Media
			found.u_id.must_equal "find_me"
		end
	end

	describe "save" do
		it "should save to the db" do
			r = YAML.load(Episodey::Test.generate_media_set_yaml("testsave_ms"))
			r.save().must_equal true

			d = nil
			begin
				d = Episodey::DB::MediaSet.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
			end
		end

		it "should update db record if @id exists" do
			ms = Episodey::DB::MediaSet.find(3)
			r = Episodey::MediaSet.db_to_object([ms])[0]
			r.name = "example updated"
			r.save

			d = nil
			r.id.must_equal 3 #make sure the id hasn't change mysteriously
			begin
				d = Episodey::DB::MediaSet.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
				d.name.must_equal "example updated"
			end
		end

		it "should return false if the object is not initialized" do
			r = Episodey::MediaSet.new
			r.name = "example"
			r.save().must_equal false
		end

		it "should raise and exception if updating a non-existant id" do
			r = YAML.load(Episodey::Test.generate_media_set_yaml("testsave_ms"))
			r.id = 9999999

			assert_raises Exception do
				r.save
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

		it "should raise an Exception if u_id is empty" do
			assert_raises Exception do
				d = Episodey::Website.load_cfg 'spec/config/websites/example.bad'
			end
		end
	end

	describe "load_db" do
		it "should return all websites loaded from the database" do
			d = Episodey::Website.load_db nil
			assert_operator d.length, :>, 1
		end

		it "should replace existing db attributes with website list passed in if u_id matches" do
			c = Episodey::Website.load_cfg 'spec/config/websites/example.cfg'
			d = Episodey::Website.load_db c
			d['example'].name.must_equal 'fromconfig'
		end

		it "should merge website list passed in with websites loaded from db" do
			c = Episodey::Website.load_cfg 'spec/config/websites/example.cfg'
			d = Episodey::Website.load_db c
			d['extraexample'].wont_be_nil.must_equal false
		end
	end

	describe "html_to_postings" do
		it "should return several records" do
			html = "<a href='http://url1.com'>url1</a><a href='http://url2.com'>url2</a>"
			d = Episodey::Website.html_to_postings html
			assert_operator d.length, :>, 0
		end

		it "should raise exception if argument is nil" do
			assert_raises Exception do
				Episodey::Website.html_to_postings nil
			end
		end

		it "should return an empty array if argument is an empty string" do
			d = Episodey::Website.html_to_postings ""
			d.length.must_equal 0
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
			ensure
				d.wont_be_nil.must_equal false
			end
		end

		it "should update db record if @id exists" do
			r = Episodey::Website.new
			r.id = 2
			r.u_id = "http://exampleupdated.com"
			r.name = "example updated"
			r.urls = {"home": "exampleupdated.com"}
			r.save

			d = nil
			r.id.must_equal 2 #make sure the id hasn't change mysteriously
			begin
				d = Episodey::DB::Website.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
				d.name.must_equal "example updated"
				d.u_id.must_equal "http://exampleupdated.com"
			end
		end

		it "should return false if the object is not initialized" do
			r = Episodey::Website.new
			#r.u_id = nil #no u_id
			r.name = "example"
			r.urls = {"home": "exampleupdated.com"}
			r.save().must_equal false
		end

		it "should raise and exception if updating a non-existant id" do
			r = Episodey::Website.new
			r.id = 9999999
			r.u_id = "http://exampleupdated.com"
			r.name = "example updated"
			r.urls = {"home": "exampleupdated.com"}
			assert_raises Exception do
				r.save
			end
		end
	end

	describe "generate_uri" do
		it "should generate the correct uri" do
			r = Episodey::Website.new
			r.u_id = 'testsave.com'
			r.name = 'Test URI Generation'
			r.urls = {"home": "test_uri_gen.com"}

			#get arg
			r.args = {"pager" => ["get","page"]}
			uri = r.generate_uri("home",1,nil)
			uri.to_s.must_equal "test_uri_gen.com?page=1"
			uri = r.generate_uri("home",2,nil)
			uri.to_s.must_equal "test_uri_gen.com?page=2"

			#get arg with existing get args (should append existing)
			r.urls = {"home": "test_uri_gen.com?garbage=1&tresure=test"}
			uri = r.generate_uri("home",1,nil)
			uri.to_s.must_equal "test_uri_gen.com?page=1&garbage=1&tresure=test"

			#url arg
			r.urls = {"home": "test_uri_gen.com/{searcher}{pager}"}
			r.args = {"pager" => ["url","/page/{x}"]}
			uri = r.generate_uri("home",1,nil)
			uri.to_s.must_equal "test_uri_gen.com/page/1"

			#	w. search
			r.urls = {"home": "test_uri_gen.com/{searcher}{pager}"}
			r.args = {"pager" => ["url","/page/{x}"], "searcher" => ["url","/search/{x}"]}
			uri = r.generate_uri("home",1,"test")
			uri.to_s.must_equal "test_uri_gen.com/search/test/page/1"
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

	describe "db_to_object" do
		it "should convert an Array of Episodey::DB::Media objects to Episodey::Media objects" do
			db_media_list = Episodey::DB::Media.all
			m = Episodey::Media.db_to_object(db_media_list)

			assert_operator m.length, :>, 1
		end

		it "should return corresponding posting objects in posting attribute" do
			db_media = Episodey::DB::Media.find(3)
			m = Episodey::Media.db_to_object([db_media])[0]

			m.posting.wont_be_nil.must_equal false
		end
	end

	describe "object_to_db" do
		it "should convert an Array of Episodey::Media objects to Episodey::DB::Media objects" do
			db_media_list = Episodey::DB::Media.all
			m = Episodey::Media.db_to_object(db_media_list)
			db_m = Episodey::Media.object_to_db(m)
			
			assert_operator db_m.length, :>, 1
			db_m[0].class.must_equal Episodey::DB::Media
		end
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
			r = Episodey::Test.generate_media_object("test1")
			@media_set.add_media(r)
			r.save

			#make sure the media_set is still part of the object
			r.media_set.wont_be_nil.must_equal false

			d = nil
			begin
				d = Episodey::DB::Media.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
			end
		end

		it "should update db record if @id exists" do
			m = Episodey::DB::Media.find(2)
			r = Episodey::Media.db_to_object([m])[0]
			r.name = "example updated"
			r.save

			d = nil
			r.id.must_equal 2 #make sure the id hasn't change mysteriously
			begin
				d = Episodey::DB::Media.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
				d.name.must_equal "example updated"
			end
		end

		it "should return false if the object is not initialized" do
			r = Episodey::Media.new
			r.name = "example"
			r.save().must_equal false
		end

		it "should raise and exception if updating a non-existant id" do
			r = Episodey::Media.new
			r.u_id = "test"
			r.id = 9999999
			r.name = "example updated"
			assert_raises Exception do
				r.save
			end
		end
	end
end

describe Episodey::Posting do
	describe "db_to_object" do
		it "should convert an Array of Episodey::DB::Posting objects to Episodey::Posting objects" do
			db_posting_list = Episodey::DB::Posting.all
			m = Episodey::Posting.db_to_object(db_posting_list)

			assert_operator m.length, :>, 1
		end
	end

	describe "object_to_db" do
		it "should convert an Array of Episodey::Posting objects to Episodey::DB::Posting objects" do
			db_posting_list = Episodey::DB::Posting.all
			m = Episodey::Posting.db_to_object(db_posting_list)
			db_m = Episodey::Posting.object_to_db(m)
			
			assert_operator db_m.length, :>, 1
			db_m[0].class.must_equal Episodey::DB::Posting
		end
	end

	describe "save" do
		it "should save to the db" do
			r = Episodey::Test.generate_posting_object(nil)
			r.save().must_equal true

			d = nil
			begin
				d = Episodey::DB::Posting.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
			end
		end

		it "should update db record if @id exists" do
			m = Episodey::Test.generate_media_object('oakland')
			p = Episodey::Test.generate_posting_object('oakland')
			m.set_posting(p)
			m.save

			r_id = p.id
			p_db = Episodey::DB::Posting.find(r_id)
			r = Episodey::Posting.db_to_object([p_db])[0]
			r.html = "example updated"
			r.save

			d = nil
			r.id.must_equal r_id #make sure the id hasn't change mysteriously
			begin
				d = Episodey::DB::Posting.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
				d.html.must_equal "example updated"
			end
		end

		it "should return false if the object is not initialized" do
			r = Episodey::Test.generate_posting_object("noinit_test")
			r.url = nil
			r.save().must_equal false
		end

		it "should raise and exception if updating a non-existant id" do
			r = Episodey::Test.generate_posting_object("testsave_posting")
			r.id = 9999999

			assert_raises Exception do
				r.save
			end
		end
	end
end

describe Episodey::Notification do
	describe "db_to_object" do
		it "should convert an Array of Episodey::DB::Notification objects to Episodey::Notification objects" do
			db_notification_list = Episodey::DB::Notification.all
			m = Episodey::Notification.db_to_object(db_notification_list)

			assert_operator m.length, :>, 1
		end
	end

	describe "object_to_db" do
		it "should convert an Array of Episodey::Notification objects to Episodey::DB::Notification objects" do
			db_notification_list = Episodey::DB::Notification.all
			m = Episodey::Notification.db_to_object(db_notification_list)
			db_m = Episodey::Notification.object_to_db(m)
			
			assert_operator db_m.length, :>, 1
			db_m[0].class.must_equal Episodey::DB::Notification
		end
	end

	describe "save" do
		it "should save to the db" do
			r = Episodey::Test.generate_notification_object(nil)
			r.save().must_equal true

			d = nil
			begin
				d = Episodey::DB::Notification.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
			end
		end

		it "should update db record if @id exists" do
			r_id = 2;
			ms = Episodey::DB::Notification.find(r_id)
			r = Episodey::Notification.db_to_object([ms])[0]
			r.message = "example updated"
			r.save

			d = nil
			r.id.must_equal r_id #make sure the id hasn't change mysteriously
			begin
				d = Episodey::DB::Notification.find(r.id)
			ensure
				d.wont_be_nil.must_equal false
				d.message.must_equal "example updated"
			end
		end

		it "should return false if the object is not initialized" do
			r = Episodey::Test.generate_notification_object("noinit_test")
			r2 = Episodey::Test.generate_notification_object("noinit_test #2")

			r.subject = nil
			r2.message = nil

			r.save().must_equal false
			r2.save().must_equal false
		end

		it "should raise and exception if updating a non-existant id" do
			r = Episodey::Test.generate_notification_object("testsave_notification")
			r.id = 9999999

			assert_raises Exception do
				r.save
			end
		end
	end

	describe "send" do
		it "should successfully send a notification" do
			n = Episodey::DB::Notification.find(1)
			n = Episodey::Notification.db_to_object([n])[0]
			n.send.must_equal true
		end
	end

	describe "send_grouped" do
		it "should successfully send all unsent notifications (consolidated). 1 notification per user." do
			n = Episodey::DB::Notification.all
			notifications = Episodey::Notification.db_to_object(n)

			r = Episodey::Notification.send_grouped notifications
			r.must_equal 2
		end
	end

	describe "find_unsent" do
		it "should return all unsent notifications" do
			n = Episodey::DB::Notification.find_unsent
			assert_operator n.length, :>, 2
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

describe Episodey::App do
	before do
		@app = Episodey::App.new
	end

	describe "load" do
		it "should populate App website, media_sets, and scan_cfg" do
			@app.load "spec/config"
			@app.scan_cfg.wont_be_nil
			assert_operator @app.scan_cfg.websites.length, :>, 0
			assert_operator @app.scan_cfg.media_sets.length, :>, 0

			@app.websites.wont_be_nil
			assert_operator @app.websites.length, :>, 0

			@app.media_sets.wont_be_nil
			assert_operator @app.media_sets.length, :>, 0
		end

		it "should load scan only if cfg_type='scan'" do
			@app.load "scan","spec/config/scan.cfg"
			@app.scan_cfg.wont_be_nil
			assert_operator @app.scan_cfg.websites.length, :>, 0
			assert_operator @app.scan_cfg.media_sets.length, :>, 0

			@app.websites.must_be_nil
			@app.media_sets.must_be_nil
		end

		it "should load websites only if cfg_type='website'" do
			@app.load "website","spec/config/websites/example.cfg"
			@app.websites.wont_be_nil
			assert_operator @app.websites.length, :>, 0

			@app.scan_cfg.must_be_nil
			@app.media_sets.must_be_nil
		end

		it "should load media_sets only if cfg_type='media_set'" do
			@app.load "media_set","spec/config/media_sets/example.cfg"
			@app.media_sets.wont_be_nil
			assert_operator @app.media_sets.length, :>, 0

			@app.scan_cfg.must_be_nil
			@app.websites.must_be_nil
		end

		it "should raise an Exception if an invalid cfg_type was given" do
			assert_raises Exception do
				@app.load "SCHmedia_set","spec/config/media_sets/example.cfg"
			end
		end

		it "should raise an Exception if cfg_type given and file does not exist" do
			assert_raises Exception do
				@app.load "media_set","some_nonexistant_file.bad"
			end
		end
	end

	describe "get_scannable_websites" do
		it "should return scannable websites based on loaded scan_cfg" do
			@app.load "spec/config"
			scannable = @app.get_scannable_websites
			scannable.wont_be_nil	
			scannable.wont_be_empty
		end
	end

	describe "scan" do
		it "should populate new_media" do
			@app.load "spec/config"
			@app.scan
			#puts @app.new_media.to_yaml
			@app.new_media.wont_be_nil
			@app.new_media.wont_be_empty
		end
	end
end

describe Episodey::ScanCfg do
	describe "load" do
		it "should load scan config" do
			d = Episodey::ScanCfg.new 'spec/config/scan.cfg'
			d.wont_be_nil
			d.media_sets.wont_be_nil
			d.websites.wont_be_nil
		end
	end
end


describe Episodey::Session do
end
