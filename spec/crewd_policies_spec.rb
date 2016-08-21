require 'spec_helper'

context "allow attributes on model then check policy" do

	context "simple attribute examples" do

		class IdentityA < Struct.new(:roles)
			def has_role?(aRole)
				roles.include? aRole
			end
		end

		let (:junior) { IdentityA.new(%w(junior)) }
		let (:junior2) { IdentityA.new(%w(junior)) }
		let (:boss) { IdentityA.new(%w(junior boss)) }
		let (:master) { IdentityA.new(%w(junior boss master)) }
		let (:anyone) { IdentityA.new([]) }

		class CrewdTestModel
			include ActiveModel::Model
			include CrewdPolicies::Model

			allow :junior, read: [:name,:address]
			allow :junior, read: [:dob]
			allow :boss, read: [:next_of_kin]

			allow :boss, transmogrify: []
			allow :boss, eliminate: true

			allow :junior, [:cough,:sneeze] => [:desk,:outside]
		end

		class CrewdTestModelPolicy < CrewdPolicies::BasePolicy
		end

		let (:junior_policy) { Pundit.policy!(junior,CrewdTestModel.new) }
		let (:boss_policy) { Pundit.policy!(boss,CrewdTestModel.new) }
		let (:master_policy) { Pundit.policy!(master,CrewdTestModel.new) }
		let (:anyone_policy) { Pundit.policy!(anyone,CrewdTestModel.new) }

		it "check" do

			junior_policy.allowed_attributes(:read).should == %w(address dob name)
			junior_policy.read?.should == true
			master_policy.read?.should == true
			master_policy.permitted_attributes_for_read.should == %w(address dob name next_of_kin)
			anyone_policy.permitted_attributes_for_read.should == []
			anyone_policy.read?.should == false

			junior_policy.allowed?(:transmogrify).should == false
			boss_policy.allowed?(:transmogrify).should == false
			master_policy.allowed?(:transmogrify).should == false

			junior_policy.allowed?(:eliminate).should == false
			boss_policy.allowed?(:eliminate).should == true
			master_policy.allowed?(:eliminate).should == true

			junior_policy.allowed?(:cough).should == true
			junior_policy.allowed?(:sneeze).should == true
			boss_policy.allowed?(:cough).should == true
			boss_policy.allowed?(:sneeze).should == true
			junior_policy.allowed?(:cough,:outside).should == true
			junior_policy.allowed?(:cough,:desk).should == true
			junior_policy.allowed?(:cough,[:desk,:outside]).should == true
			junior_policy.allowed?(:cough,:lunch_room).should == false

			junior_policy.allowed_attributes(:cough).should == %w(desk outside)
			junior_policy.allowed_attributes(:sneeze).should == %w(desk outside)
		end
	end

	context "conditional attribute examples" do

		class IdentityB < Struct.new(:id,:roles)
			#include ActiveModel::Model
			include CrewdPolicies::Model

			def has_role?(aRole)
				roles.include? aRole
			end

			allow :junior, read: %w(name address)
			allow :junior, write: %w(name address password), if: :is_self?
			allow :boss, [:read,:write] => [:notes], :if => :is_subordinate?
			allow :master, [:read,:write] => %w(name address)
		end

		let (:junior) { IdentityB.new(1,%w(junior)) }
		let (:junior2) { IdentityB.new(2,%w(junior)) }
		let (:boss) { IdentityB.new(3,%w(junior boss)) }
		let (:master) { IdentityB.new(4,%w(junior boss master)) }
		let (:anyone) { IdentityB.new(5,[]) }

		class IdentityBPolicy < CrewdPolicies::BasePolicy
			def is_self?
				@identity==@record
			end

			def is_subordinate?
				identity.has_role?('master') && !record.has_role?('master') or
				identity.has_role?('boss') && !record.has_role?('boss')
			end
		end

		it "check" do
			Pundit.policy!(junior,junior).is_self?.should == true
			Pundit.policy!(boss,junior).is_subordinate?.should == true
			Pundit.policy!(master,junior).is_subordinate?.should == true

			Pundit.policy!(junior,junior).permitted_attributes_for_read.should == %w(address name)
			Pundit.policy!(junior,junior).permitted_attributes_for_write.should == %w(address name password)
			Pundit.policy!(junior,junior2).permitted_attributes_for_read.should == %w(address name)
			Pundit.policy!(junior,junior2).permitted_attributes_for_write.should == []
			Pundit.policy!(boss,junior).permitted_attributes_for_write.should == %w(notes)
			Pundit.policy!(boss,boss).permitted_attributes_for_write.should == %w(address name password)
			Pundit.policy!(boss,master).permitted_attributes_for_write.should == []
			Pundit.policy!(boss,master).permitted_attributes_for_read.should == %w(address name)
			Pundit.policy!(master,boss).permitted_attributes_for_write.should == %w(address name notes)
			Pundit.policy!(master,junior).permitted_attributes_for_write.should == %w(address name notes)
			Pundit.policy!(master,master).permitted_attributes_for_write.should == %w(address name password)
		end
	end

	# replace allow_filter with :
	#
	# class TestUser < ActiveRecord::Base
	# 	allow :junior, [:read,:write] => [:name,:address]
	#   allow :junior, write: :password, if: :is_self
	#   allow :junior, write: :phone, unless: :cancelled
	# end
	#
	#it "allow_filter enables custom rules despite heirarchy" do
	# 	class TestUser < ActiveRecord::Base
	# 		self.table_name = 'users'
	#
	# 		include CrewdPolicies::Model
	#
	# 		allow :junior, [:read,:write] => [:name,:address]
	# 		allow :junior, write: :password
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
	# 	TestUser.permitted(:junior,:read).should == [:address,:name]
	# 	TestUser.permitted(:boss,:read).should == [:address,:name,:notes]
	# 	TestUser.permitted(:junior,:write).should == [:address,:name,:password]
	# 	TestUser.permitted(:boss,:write).should == [:address,:name,:notes,:password] # permitted is a concentric method!
	# 	anyone = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:anyone),
	# 		first_name: Faker::Name.first_name,
	# 		last_name:  Faker::Name.last_name,
	#     email: Faker::Internet.email
	# 	)
	# 	junior = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:junior),
	# 		first_name: Faker::Name.first_name,
	# 		last_name:  Faker::Name.last_name,
	#     email: Faker::Internet.email
	# 	)
	# 	junior2 = TestUser.create!(
	# 		ring: Concentric.lookup_ring(:junior),
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
	# 	TestUserPolicy.new(junior,junior).permitted_attributes(:write).should == [:address,:name,:password]
	# 	TestUserPolicy.new(junior,junior2).permitted_attributes(:write).should == []
	# 	TestUserPolicy.new(boss,junior).permitted_attributes(:write).should == [:address,:name,:notes]
	# 	TestUserPolicy.new(boss,boss).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# 	TestUserPolicy.new(boss,master).permitted_attributes(:write).should == []
	# 	TestUserPolicy.new(master,boss).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# 	TestUserPolicy.new(master,junior).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# 	TestUserPolicy.new(master,master).permitted_attributes(:write).should == [:address,:name,:notes,:password]
	# end


end
