require 'spec_helper'

describe "CrewdTestModel" do

	before(:all) do
		# @original_config = Concentric.config
		# Concentric.config = {
		# 	ring_names: {
		# 		master: 0,
		# 		boss: 10,
		# 		pleb: 30,
		# 		anyone: 100
		# 	}
		# }
	end

	after(:all) do
		# Concentric.config = @original_config
	end

	it "attributes described should be available in outer rings" do
		class CrewdTestModel < ActiveRecord::Base
			include Concentric::Model

			allow :pleb, read: [:name,:address]
			allow :pleb, read: [:dob]
			allow :boss, read: [:next_of_kin]

			allow :boss, transmogrify: []
			allow :boss, eliminate: :this

			allow :pleb, [:cough,:sneeze] => [:desk,:outside]
		end

		CrewdTestModel.permitted(:pleb,:read).should == [:address,:dob,:name]
		CrewdTestModel.permitted(:master,:read).should == [:address,:dob,:name,:next_of_kin]
		CrewdTestModel.permitted(:anyone,:read).should == []
		CrewdTestModel.allowed?(:pleb,:read).should == true
		CrewdTestModel.allowed?(:master,:read).should == true
		CrewdTestModel.allowed?(:anyone,:read).should == false

		CrewdTestModel.allowed?(:pleb,:transmogrify).should == false
		CrewdTestModel.allowed?(:boss,:transmogrify).should == false
		CrewdTestModel.allowed?(:master,:transmogrify).should == false

		CrewdTestModel.allowed?(:pleb,:eliminate).should == false
		CrewdTestModel.allowed?(:boss,:eliminate).should == true
		CrewdTestModel.allowed?(:master,:eliminate).should == true

		CrewdTestModel.allowed?(:pleb,:cough).should == true
		CrewdTestModel.allowed?(:pleb,:sneeze).should == true
		CrewdTestModel.allowed?(:boss,:cough).should == true
		CrewdTestModel.allowed?(:boss,:sneeze).should == true
		CrewdTestModel.allowed?(:pleb,:cough,:outside).should == true
		CrewdTestModel.allowed?(:pleb,:cough,:desk).should == true
		CrewdTestModel.allowed?(:pleb,:cough,[:desk,:outside]).should == true
		CrewdTestModel.allowed?(:pleb,:cough,:lunch_room).should == false

		CrewdTestModel.permitted(:pleb,:cough).should == [:desk,:outside]
		CrewdTestModel.permitted(:pleb,:sneeze).should == [:desk,:outside]
	end


	# replace allow_filter with :
	#
	# class TestUser < ActiveRecord::Base
	# 	allow :pleb, [:read,:write] => [:name,:address]
	#   allow :pleb, write: :password, if: :is_self
	#   allow :pleb, write: :phone, unless: :cancelled
	# end
	#
	# it "allow_filter enables custom rules despite heirarchy" do
	# 	class TestUser < ActiveRecord::Base
	# 		self.table_name = 'users'
	#
	# 		include CrewdPolicies::Model
	#
	# 		allow :pleb, [:read,:write] => [:name,:address]
	# 		allow :pleb, write: :password
	# 		allow :boss, [:read,:write] => [:notes]
	# 	end
	#
	# 	class TestUserPolicy < KojacBasePolicy
	# 		allow_filter ability: :write, ring: :boss do |p,fields|   # boss can't write other people's passwords
	# 			fields -= [:password] if p.user.id != p.record.id
	# 			fields
	# 		end
	# 		allow_filter do |p,fields|   # boss can't write other people's passwords
	# 			fields = [] if p.user.id != p.record.id and p.user.ring >= p.record.ring and p.user.ring >= Concentric.lookup_ring(:master)
	# 			fields
	# 		end
	# 	end
	#
	# 	TestUser.permitted(:pleb,:read).should == [:address,:name]
	# 	TestUser.permitted(:boss,:read).should == [:address,:name,:notes]
	# 	TestUser.permitted(:pleb,:write).should == [:address,:name,:password]
	# 	TestUser.permitted(:boss,:write).should == [:address,:name,:notes,:password] # permitted is a concentric method!
	# 	anyone = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:anyone),
	# 		first_name: Faker::Name.first_name,
	# 		last_name:  Faker::Name.last_name,
	#     email: Faker::Internet.email
	# 	)
	# 	pleb = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:pleb),
	# 		first_name: Faker::Name.first_name,
	# 		last_name:  Faker::Name.last_name,
	#     email: Faker::Internet.email
	# 	)
	# 	pleb2 = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:pleb),
	# 		first_name: Faker::Name.first_name,
	# 		last_name:  Faker::Name.last_name,
	#     email: Faker::Internet.email
	# 	)
	# 	boss = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:boss),
	# 		first_name: Faker::Name.first_name,
	# 		last_name:  Faker::Name.last_name,
	#     email: Faker::Internet.email
	# 	)
	# 	master = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:master),
	# 		first_name: Faker::Name.first_name,
	# 		last_name:  Faker::Name.last_name,
	#     email: Faker::Internet.email
	# 	)
	# 	TestUserPolicy.new(pleb,pleb).permitted_attributes(:write).should == [:address,:name,:password]
	# 	TestUserPolicy.new(pleb,pleb2).permitted_attributes(:write).should == []
	# 	TestUserPolicy.new(boss,pleb).permitted_attributes(:write).should == [:address,:name,:notes]
	# 	TestUserPolicy.new(boss,boss).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# 	TestUserPolicy.new(boss,master).permitted_attributes(:write).should == []
	# 	TestUserPolicy.new(master,boss).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# 	TestUserPolicy.new(master,pleb).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# 	TestUserPolicy.new(master,master).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# end


end
