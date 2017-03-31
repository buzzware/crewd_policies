require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'
require 'standard_exceptions'

module CrewdPolicies
	module Policy

		include ::StandardExceptions::Methods

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

		def all_attributes
			result = []
			record_class.roles_rules.each do |role,rules|
				rules.each do |rule|
					result |= rule[:fields] if rule[:fields]
				end
			end
			result.sort
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

		def unauthorized!(aMessage=nil)
			raise Pundit::NotAuthorizedError,(aMessage || "must be logged in")
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
		  internal_server_error! "roles_rules not found on #{record_class.name}, make sure it has \"include CrewdPolicies::Model\"" unless ra = record_class.roles_rules rescue nil
		  unauthorized! "identity not given" if !identity
		  internal_server_error! "identity must implement has_role?" if !identity.responds_to? :has_role?

		  ability = coalesce_field_ability(aAbility)

		  # for each role in roles_rules, if identity.has_role?(role) && any conditions pass then merge in fields
			result = []
		  ra.each do |role,rules|
				next unless identity.has_role? role
				rules.each do |rule| #ab, fields|
					next unless rule[:ability]==ability
					next unless eval_conditions rule
					result |= rule[:fields]
				end
			end
		  result.sort!
		  result
	  end

		# does the identity have this ability on this record?
		def inner_query_resource(aAbility)
			internal_server_error! "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
			internal_server_error! "roles_rules not found on #{record_class.name}, make sure it has \"include CrewdPolicies::Model\"" unless ra = record_class.roles_rules rescue nil
			unauthorized! "identity not given" if !identity
	    internal_server_error! "identity must implement has_role?" if !identity.respond_to? :has_role?

			aAbility = aAbility.to_s

		  ra.each do |role,rules|
				next unless identity.has_role? role
				rules.each do |rule|
					next unless eval_conditions rule
					next unless rule[:ability]==aAbility
					return true if rule[:allowed]==true or rule[:fields].is_a?(Array) && !rule[:fields].empty?
				end
		  end
			false
		end

		def eval_conditions(aRule)
			return true unless conds = aRule[:conditions]
			if_cond = conds[:if]
			unless_cond = conds[:unless]

			if_cond = if if_cond.is_a? Symbol
				send(if_cond)
			elsif if_cond.is_a? Proc
				if_cond.call()
			elsif if_cond==nil
				true
			else
				if_cond
			end

			unless_cond = if unless_cond.is_a? Symbol
				send(unless_cond)
			elsif unless_cond.is_a? Proc
				unless_cond.call()
			elsif unless_cond==nil
				false
			else
				unless_cond
			end

			!!if_cond and !unless_cond
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

	class ForbiddenError < ::StandardExceptions::Http::Forbidden
		attr_accessor :query, :record, :policy
  end

	::Pundit::NotAuthorizedError.class_eval do
		include ::StandardExceptions::ExceptionInterface
	end
end
