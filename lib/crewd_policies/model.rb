module CrewdPolicies::Model

	def self.included(aClass)
		aClass.cattr_accessor :roles_abilities
    aClass.roles_abilities = {}  # [:sales] => {read: [:name,:address], delete: true}
    aClass.send :extend, ClassMethods
  end

	module ClassMethods

		# supports different formats :
		# allow :sales, :write => [:name,:address]   ie. sales can write the name and address fields
		# allow :sales, :read                        ie. sales can read this model
		# allow :sales, [:read, :create, :destroy]   ie. sales can read, create and destroy this model
		def allow(aRole,aAbilities)
			raise "aRole must be a string or a symbol" unless aRole.is_a?(String) or aRole.is_a?(Symbol)
			aRole = aRole.to_sym
			raise "aAbilities must be a Hash" unless aAbilities.is_a? Hash # eg. :write => [:name,:address]

			role_rec = self.roles_abilities[aRole]
			aAbilities.each do |abilities, fields|
				abilities = [abilities] unless abilities.is_a?(Array)
				fields = [fields] unless fields.is_a?(Array)
				next if fields.empty?
				abilities.each do |a|
					a = a.to_sym
					role_rec ||= {}
					if fields==[:this]
						role_rec[a] = true unless role_rec[a].to_nil
					else
						role_fields = role_rec[a]
						role_fields = [] unless role_fields.is_a? Array
						role_fields = role_fields + fields.map(&:to_sym)
						role_fields.uniq!
						role_fields.sort!
						role_rec[a] = role_fields
					end
				end
				self.roles_abilities[aRole] = role_rec
			end
		end

		# returns properties that this ring can use this ability on
		def permitted(aRole,aAbility)
			raise "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
			aAbility = aAbility.to_sym
			raise "aRole must be a string or a symbol" unless aRole.is_a?(String) or aRole.is_a?(Symbol)
			aRole = aRole.to_sym
			return [] unless aRole and roles_abilities = self.respond_to?(:roles_abilities) && self.roles_abilities.to_nil

			fields = []
			role_keys = roles_abilities.keys.sort
			role_keys.each do |i|
				next unless i >= aRole
				next unless role_rec = roles_abilities[i]
				if af = role_rec[aAbility]
					next if af==true
					fields += af if af.is_a?(Array)
				end
			end
			fields.uniq!
			fields.sort!
			fields
		end

		# Query
		# aFields specifies fields you require to act on
		# This is no longer used by KojacBasePolicy because it does not observe its filters that operate on fields. It may still provide a faster check when there are no filters applied
		def allowed?(aRole,aAbility,aFields=nil)
			if aFields
				pf = permitted(aRole,aAbility)
				if aFields.is_a? Array
					return (aFields - pf).empty?
				else
					return pf.include? aFields
				end
			end

			raise "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
			aAbility = aAbility.to_sym
			raise "aRole must be a string or a symbol" unless aRole.is_a?(String) or aRole.is_a?(Symbol)
			aRole = aRole.to_sym
			return [] unless aRole and roles_abilities = self.respond_to?(:roles_abilities).to_nil && self.roles_abilities

			role_keys = roles_abilities.keys.sort
			role_keys.each do |i|
				next unless i >= aRole
				next unless role_rec = roles_abilities[i]
				return true if role_rec[aAbility].to_nil
			end
			return false
		end
	end
end
