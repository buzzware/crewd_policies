# these methods should actually work on any object with any abilities

module CrewdPolicies::Model

	def self.included(aClass)
		aClass.cattr_accessor :roles_rules
    aClass.roles_rules = {}  # [:sales] => {read: [:name,:address], delete: true}
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

			role_rules = (self.roles_rules[aRole] ||= [])
			conditions = {}
			conditions[:if] = aAbilities.delete(:if) if aAbilities.include?(:if)
			conditions[:unless] = aAbilities.delete(:unless) if aAbilities.include?(:unless)
			aAbilities.each do |abilities, fields|
				abilities = [abilities] unless abilities.is_a?(Array)
				fields = [fields] unless fields==true or fields.is_a?(Array)
				abilities = abilities.map{|a| a.to_s}                   # now an array of strings
				fields = fields.map{|a| a.to_s}.sort unless fields==true     # now an array of strings or true
				next if fields==[]
				abilities.each do |a|
					role_rules << (rule = {})
					rule[:ability] = a
					rule[:conditions] = conditions
					if fields==true  # special "field" value to mean the record or class
						rule[:allowed] = true
					else
						rule[:fields] = fields
					end
				end
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
		# 	roles_rules = self.respond_to?(:roles_rules) && !self.roles_rules.empty? && self.roles_rules
		# 	return [] unless roles_rules
		#
		# 	fields = []
		# 	role_keys = roles_rules.keys.sort
		# 	role_keys.each do |r|
		# 		next unless r == aRole
		# 		next unless role_rec = roles_rules[r]
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
		# 	return [] unless aRole and roles_rules = self.respond_to?(:roles_rules) && self.roles_rules && !self.roles_rules.empty? && self.roles_rules
		#
		# 	role_keys = roles_rules.keys.sort
		# 	role_keys.each do |i|
		# 		next unless i >= aRole
		# 		next unless role_rec = roles_rules[i]
		# 		rra = role_rec[aAbility]
		# 		return true if rra && (!rra.responds_to?(:empty?) || !rra.empty?)
		# 	end
		# 	return false
		# end
	end
end
