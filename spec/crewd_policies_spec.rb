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

	it "attributes described on model with allow should be queryable from policy" do

		class Identity < Struct.new(:roles)
			def has_role?(aRole)
				roles.include? aRole
			end
		end

		class CrewdTestModel
      include ActiveModel::Model
			include CrewdPolicies::Model

			allow :pleb, read: [:name,:address]
			allow :pleb, read: [:dob]
			allow :boss, read: [:next_of_kin]

			allow :boss, transmogrify: []
			allow :boss, eliminate: true

			allow :pleb, [:cough,:sneeze] => [:desk,:outside]
		end

		class CrewdTestModelPolicy < CrewdPolicies::BasePolicy
		end

		pleb = Identity.new(%w(pleb))
		boss = Identity.new(%w(pleb boss))
		master = Identity.new(%w(pleb boss master))
		anyone = Identity.new([])

		pleb_policy = Pundit.policy!(pleb,CrewdTestModel.new)
		boss_policy = Pundit.policy!(boss,CrewdTestModel.new)
		master_policy = Pundit.policy!(master,CrewdTestModel.new)
		anyone_policy = Pundit.policy!(anyone,CrewdTestModel.new)

		pleb_policy.allowed_attributes(:read).should == %w(address dob name)
		pleb_policy.read?.should == true
		master_policy.read?.should == true
		master_policy.permitted_attributes_for_read.should == %w(address dob name next_of_kin)
		anyone_policy.permitted_attributes_for_read.should == []
		anyone_policy.read?.should == false

		pleb_policy.allowed?(:transmogrify).should == false
		boss_policy.allowed?(:transmogrify).should == false
		master_policy.allowed?(:transmogrify).should == false

		pleb_policy.allowed?(:eliminate).should == false
		boss_policy.allowed?(:eliminate).should == true
		master_policy.allowed?(:eliminate).should == true

		pleb_policy.allowed?(:cough).should == true
		pleb_policy.allowed?(:sneeze).should == true
		boss_policy.allowed?(:cough).should == true
		boss_policy.allowed?(:sneeze).should == true
		pleb_policy.allowed?(:cough,:outside).should == true
		pleb_policy.allowed?(:cough,:desk).should == true
		pleb_policy.allowed?(:cough,[:desk,:outside]).should == true
		pleb_policy.allowed?(:cough,:lunch_room).should == false

		pleb_policy.allowed_attributes(:cough).should == %w(desk outside)
		pleb_policy.allowed_attributes(:sneeze).should == %w(desk outside)
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
