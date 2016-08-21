require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'

module CrewdPolicies
	module Policy

		public

	  attr_reader :identity, :record

		# typical pundit/rails methods

		def create?   # resource level
			inner_query_ability(:create)
		end

		def index?
			inner_query_ability(:index)
		end

		def show?
			inner_query_ability(:read)
		end

		def new?
			inner_query_ability(:create)
		end

		def update?
			inner_query_ability(:write)
		end

		def edit?
			inner_query_ability(:write)
		end

		def destroy?
			inner_query_ability(:destroy)
		end

		%w(write read create update edit show index).each do |m|
			define_method "permitted_attributes_for_#{m}" do
				allowed_attributes(m)
			end
		end

		def permitted_attributes
			inner_query_fields('write')
		end

		# CREWD permission methods

		def read?
			inner_query_ability(:read)
		end

		def write?
			inner_query_ability(:write)
		end

		# utility methods

		def scope
			Pundit.policy_scope!(user, record_class)
		end

		def unauthorized!
			raise Pundit::NotAuthorizedError, "must be logged in"
		end

		def forbidden!(aMessage=nil)
			raise ForbiddenError,(aMessage || "That operation was not allowed")
		end

		def record_class
			record.is_a?(Class) ? record : record.class
		end

		def allowed?(aAbility,aFields=nil)
			if aFields
				pf = allowed_fields(aAbility)
				if aFields.is_a? Array
					aFields = aFields.map(&:to_s)
					return (aFields - pf).empty?
				else
					aFields = aFields.to_s
					return pf.include? aFields
				end
			else
				inner_query_resource(aAbility)
			end
		end

		# fields may be attributes or associations
		def allowed_fields(aAbility)
			inner_query_fields(aAbility)
		end

	  def allowed_attributes(aAbility)
		  result = allowed_fields(aAbility)
		  cls = record_class
			result.delete_if { |f| cls.reflections.has_key? f } if cls.respond_to? :reflections
			result
		end

		def allowed_associations(aAbility=nil)
		  result = allowed_fields(aAbility)
		  cls = record_class
			result.delete_if { |f| !cls.reflections.has_key? f }
			result
		end

		protected   # internal methods below here

		def coalesce_field_ability(aAbility)
			aAbility = aAbility.to_s
			case aAbility
				when 'write','read' then aAbility
				when 'create','update','edit' then 'write'
				when 'show','index' then 'read'
				else
					aAbility
			end
		end


		# what fields does the identity have this ability for ?
	  def inner_query_fields(aAbility)
		  ability = coalesce_field_ability(aAbility)

		  # for each role in roles_rules, if identity.has_role?(role) && any conditions pass then merge in fields
		  raise "roles_rules not found on #{record_class.name}, make sure it has \"include CrewdPolicies::Model\"" unless ra = record_class.roles_rules rescue nil
			result = []
		  ra.each do |role,rules|
				next unless identity.has_role? role
				rules.each do |rule| #ab, fields|
					next unless rule[:ability]==ability
					result |= rule[:fields]
				end
			end
		  result.sort!
		  result
	  end

		# does the identity have this ability on this record?
		def inner_query_resource(aAbility)
			raise "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
			aAbility = aAbility.to_s

			raise "roles_rules not found on #{record_class.name}, make sure it has \"include CrewdPolicies::Model\"" unless ra = record_class.roles_rules rescue nil
		  ra.each do |role,rules|
				next unless identity.has_role? role
				rules.each do |rule|
					next unless rule[:ability]==aAbility
					return true if rule[:allowed]==true or rule[:fields].is_a?(Array) && !rule[:fields].empty?
				end
		  end
			false
		end

		# does the identity have this ability on the record/resource at all?
		def inner_query_ability(aAbility)
			raise "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
			aAbility = aAbility.to_s

			case aAbility
				when 'write','read','update','show','edit'
					inner_query_fields(aAbility).length > 0
				when 'create','destroy','index'
					inner_query_resource(aAbility)
				else
					raise 'this ability is unknown'
			end
		end
	end

	class ForbiddenError < StandardError
		attr_accessor :query, :record, :policy
  end

end

