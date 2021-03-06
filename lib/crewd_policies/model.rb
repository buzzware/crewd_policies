# these methods should actually work on any object with any abilities

module CrewdPolicies::Model

	def self.included(aClass)
		aClass.class_attribute :roles_rules, instance_predicate: false, instance_accessor: false
    aClass.roles_rules ||= {}   # [:sales] => [
															#               {ability: 'read', fields: [:name,:address]}
															#               {ability: 'destroy', allowed: true}
															#             ]
    aClass.send :extend, ClassMethods
  end

	module ClassMethods

		def dup_roles_rules(aRR)
			aRR.deep_dup  # provided by Rails
		end

		# supports different formats : allow <role>, <abilities> => <attributes>
		#
		# allow :sales, :write => [:name,:address]   ie. sales can write the name and address fields
		def allow(aRole,aAbilities)
			if aRole.is_a? Array
				aRole.each {|r| allow(r,aAbilities.dup) }
				return
			end
			raise ::StandardExceptions::Http::InternalServerError.new "aRole must be a string or a symbol" unless aRole.is_a?(String) or aRole.is_a?(Symbol)
			aRole = aRole.to_s
			raise ::StandardExceptions::Http::InternalServerError.new "aAbilities must be a Hash" unless aAbilities.is_a? Hash # eg. :write => [:name,:address]

			# these lines inherit roles_rules from parent classes, then dup them so the parent doesn't get modified
			superclass_rr = self.superclass && self.superclass.respond_to?(:roles_rules) && self.superclass.roles_rules
			inheriting_rr = self.roles_rules && superclass_rr && (self.roles_rules.equal? superclass_rr)
			self.roles_rules = dup_roles_rules(self.roles_rules) if inheriting_rr

			role_rules = (self.roles_rules[aRole] ||= [])
			conditions = {}
			conditions[:if] = aAbilities.delete(:if) if aAbilities.include?(:if)
			conditions[:unless] = aAbilities.delete(:unless) if aAbilities.include?(:unless)
			aAbilities.each do |abilities, fields|
				abilities = [abilities] unless abilities.is_a?(Array)
				fields = [fields] unless fields==true or fields.is_a?(Array)
				abilities = abilities.map{|a| a.to_s}                       # now an array of strings
				fields = fields.map{|a| a.to_s}.sort unless fields==true    # now an array of strings or true
				next if fields==[]
				abilities.each do |a|
					role_rules << (rule = {})
					rule[:ability] = a
					rule[:conditions] = conditions unless conditions.empty?
					if fields==true  # special "field" value to mean the record or class
						rule[:allowed] = true
					else
						raise ::StandardExceptions::Http::InternalServerError.new "create, destroy and index must have true as a value, not an array of fields" if a=='create' or a=='destroy' or a=='index'
						rule[:fields] = fields
					end
				end
			end
		end
	end
end
