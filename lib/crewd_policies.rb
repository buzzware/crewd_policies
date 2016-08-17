require "crewd_policies/version"
require "crewd_policies/model"
require "crewd_policies/policy"

module CrewdPolicies
  # Your code goes here...
end

#concentric
#
#Assists implementation of ring level security (http://en.wikipedia.org/wiki/Ring_(computer_security)) with Rails 4 (or Rails 3 with gem) Strong Parameters.
#
#Ring Level Security is a simpler alternative to Role Based Security. Rings are arranged in a concentric hierarchy from most-privileged innermost Ring 0 to the least privileged highest ring number. Users have their own ring level which gives them access to that ring and below.
#
#For example, a sysadmin could have Ring 0, a website manager ring 1, a customer ring 2, and anonymous users ring 3. A customer would have all the capabilities of anonymous users, and more. Likewise, a website manager has all the capabilities of a customer, and more etc.
#
#This inheritance of capabilities of outer rings, and the simple assigning of users to rings, makes security rules less repetitive and easier to write and maintain, minimising dangerous mistakes.
#
#This gem does not affect or replace or prevent the standard strong parameters methods from being used in parallel, it merely generates arguments for the standard strong parameters methods.
#
#
#
#BASIC_FIELDS = [:name, :address]
#
#class Deal
#  ring 1, :write, BASIC_FIELDS
#  ring 1, :write, :phone
#  ring 1, :delete
#  ring 2, :read, BASIC_FIELDS
#end
#
#
#class DealsController
#
#  def update
#    ring_fields(:write,model)
#    if ring_can(:write,model,:name)
#    if ring_can(:delete,model)
#    model.update(params.permit( ring_fields(:write,model) ))
#  end
#
#end

# Update: 2015-03-26
#
# * Extracted ConcentricPolicy from Kojac
# * Concentric is now a way of creating Pundit policies based on ConcentricPolicy. It allows shorthand ring security for
# simple scenarios, then allow_filter for refinement and arbitrary complex logic to be implemented
# * Concentric works on the simple idea that there are 4 basic abilities: read, write, create and delete.
# * Read and write apply primarily to fields; create and delete apply to records.
# * Creating a record requires the ability to create the record, then normally you require the ability to write some fields.
# * In order to read a record, you need the ability to read at least one field
# * In order to write to a record, you need the ability to write at least one field
# * In order to delete a record, you need the ability to delete the record
# * With Concentric you first use the ring and
#
# implement Pundit Policy classes and methods (eg. update? show?) by querying these 4 abilities
#
# class Concentric
#
# 	cattr_accessor :config
#
# 	def self.lookup_ring(aRingName)
# 		return nil if !aRingName
# 		return aRingName if aRingName.is_a?(Fixnum)
# 		if ring_names = Concentric.config[:ring_names]
# 			return ring_names[aRingName.to_sym]
# 		else
# 			return nil
# 		end
# 	end
#
# 	def self.ring_name(aRing)
# 		ring_names = Concentric.config[:ring_names]
# 		ring_names.key(aRing)
# 	end
#
# 	def self.ring_text(aRing)
# 		return 'none' if !aRing
# 		ring_name(aRing).to_s.humanize
# 	end
# end
