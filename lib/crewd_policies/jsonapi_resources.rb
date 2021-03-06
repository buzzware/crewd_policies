# This is for use with https://github.com/cerebris/jsonapi-resources
# It was developed with https://github.com/venuu/jsonapi-authorization but it may not be required because it doesn't seem to deal with attributes, just scope and record permissions?
# eg.
# class BaseResource < JSONAPI::Resource
#   include JSONAPI::Authorization::PunditScopedResource
#   include CrewdPolicies::JSONAPIResource
#   abstract
# end

module CrewdPolicies
	module JSONAPIResource

		def self.included(aClass)
	    aClass.send :extend, ClassMethods
	  end

		module ClassMethods

			def inherited(subclass)
				super
				cls = subclass._model_class
				attrs = cls.roles_rules.values.flatten.map{|h| h[:fields]}.compact.flatten.uniq.map(&:to_sym) # all fields from all rules
				attrs.delete_if { |f| cls.reflections.has_key? f.to_s } if cls.respond_to? :reflections       # remove associations
				attrs -= [:id]
				subclass.send(:attributes, *attrs) unless attrs.empty?
      end

			def updatable_fields(context)
				p = ::Pundit.policy!(context[:user],_model_class)
				p.allowed_fields(:write).map(&:to_sym)
		  end

		  def creatable_fields(context)
			  p = ::Pundit.policy!(context[:user],_model_class)
			  p.allowed_fields(:write).map(&:to_sym)
		  end
		end

		def fetchable_fields
		  ::Pundit.policy!(context[:user],_model).allowed_fields(:read).map(&:to_sym)   # includes assocations
		end
	end
end
