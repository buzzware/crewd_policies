require 'active_support/core_ext/class/attribute'
require 'active_support/core_ext/string/inflections'
require 'pundit'

module CrewdPolicies
	# optional
	class BasePolicy
		include Policy

		attr_reader :identity, :record

		def initialize(identity, record)
	     @identity = identity
	     @record = record
		end

		def model_class
	    @policy_class ||= self.class.name.sub(/Policy$/,'').safe_constantize  # record ? record.class
	   end

		def scope
	     Pundit.policy_scope!(identity, model_class)
	   end

		class Scope
	     attr_reader :identity, :scope

	    def initialize(identity, scope)
	      @identity = identity
	      @scope = scope
	    end

	    def model_class
	      @policy_class ||= (self.class.name.sub(/Policy::Scope$/,'').safe_constantize or @scope)
	    end

			def resolve
				scope
			end
		end
	end
end
