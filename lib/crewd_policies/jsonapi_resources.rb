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
				attrs = ::Pundit.policy!(nil,subclass._model_class).all_attributes.map(&:to_sym)
				attrs -= [:id]
				subclass.send(:attributes, *attrs) unless attrs.empty?
      end

			def updatable_fields(context)
				::Pundit.policy!(context[:user],_model).permitted_attributes_for_update.map(&:to_sym)
		  end

		  def self.creatable_fields(context)
			  ::Pundit.policy!(context[:user],_model).permitted_attributes_for_create.map(&:to_sym)
		  end
		end

		def fetchable_fields
		  ::Pundit.policy!(context[:user],_model).permitted_attributes_for_read.map(&:to_sym)
		end
	end
end
