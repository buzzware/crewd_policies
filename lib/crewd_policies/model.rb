# these methods should actually work on any object with any abilities

module CrewdPolicies::Model

	def self.included(aClass)
		aClass.cattr_accessor :roles_abilities
    aClass.roles_abilities = {}  # [:sales] => {read: [:name,:address], delete: true}
    aClass.send :extend, ClassMethods
  end

	module ClassMethods

		# supports different formats : allow <role>, <abilities> => <attributes>
		#
		# allow :sales, :write => [:name,:address]   ie. sales can write the name and address fields
		def allow(aRole,aAbilities)
			raise "aRole must be a string or a symbol" unless aRole.is_a?(String) or aRole.is_a?(Symbol)
			aRole = aRole.to_s
			raise "aAbilities must be a Hash" unless aAbilities.is_a? Hash # eg. :write => [:name,:address]

			role_rec = (self.roles_abilities[aRole] || {})
			aAbilities.each do |abilities, fields|
				abilities = [abilities] unless abilities.is_a?(Array)
				fields = [fields] unless fields==true or fields.is_a?(Array)
				abilities = abilities.map{|a| a.to_s}
				fields = fields.map{|a| a.to_s} unless fields==true
				next if fields==[]
				abilities.each do |a|
					if fields==true  # special "field" value to mean the record or class
						role_rec[a] = true
					else
						role_fields = role_rec[a]
						role_fields = [] unless role_fields.is_a? Array
						role_fields = role_fields | fields
						role_fields.sort! # optimisation: do this later
						role_rec[a] = role_fields
					end
				end
				self.roles_abilities[aRole] = role_rec
			end
		end

		# Queries the allow data and returns properties that this role has this ability on.
		# Since the identity and any role inheritance is unknown, we can only query roles at face value.
		# !!! Should we even have this method here ?
		# def allowed_fields(aRole,aAbility)
		# 	raise "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
		# 	aAbility = aAbility.to_s
		# 	raise "aRole must be a string or a symbol" unless aRole.is_a?(String) or aRole.is_a?(Symbol)
		# 	aRole = aRole.to_s
		# 	roles_abilities = self.respond_to?(:roles_abilities) && !self.roles_abilities.empty? && self.roles_abilities
		# 	return [] unless roles_abilities
		#
		# 	fields = []
		# 	role_keys = roles_abilities.keys.sort
		# 	role_keys.each do |r|
		# 		next unless r == aRole
		# 		next unless role_rec = roles_abilities[r]
		# 		if af = role_rec[aAbility]
		# 			next if af==true
		# 			fields |= af if af.is_a?(Array)
		# 		end
		# 	end
		# 	fields.sort!
		# 	fields
		# end

		# alias_method :permitted, :allowed_attributes
		#
		# # Query
		# # aFields specifies fields you require to act on
		# # This is no longer used by KojacBasePolicy because it does not observe its filters that operate on fields. It may still provide a faster check when there are no filters applied
		# def allowed?(aRole,aAbility,aFields=nil)
		# 	if aFields
		# 		pf = permitted(aRole,aAbility)
		# 		if aFields.is_a? Array
		# 			return (aFields - pf).empty?
		# 		else
		# 			return pf.include? aFields
		# 		end
		# 	end
		#
		# 	raise "aAbility must be a string or a symbol" unless aAbility.is_a?(String) or aAbility.is_a?(Symbol)
		# 	aAbility = aAbility.to_sym
		# 	raise "aRole must be a string or a symbol" unless aRole.is_a?(String) or aRole.is_a?(Symbol)
		# 	aRole = aRole.to_sym
		# 	return [] unless aRole and roles_abilities = self.respond_to?(:roles_abilities) && self.roles_abilities && !self.roles_abilities.empty? && self.roles_abilities
		#
		# 	role_keys = roles_abilities.keys.sort
		# 	role_keys.each do |i|
		# 		next unless i >= aRole
		# 		next unless role_rec = roles_abilities[i]
		# 		rra = role_rec[aAbility]
		# 		return true if rra && (!rra.responds_to?(:empty?) || !rra.empty?)
		# 	end
		# 	return false
		# end
	end
end
