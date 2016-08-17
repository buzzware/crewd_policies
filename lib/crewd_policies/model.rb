# see http://yehudakatz.com/2009/11/12/better-ruby-idioms/ re class and instance methods and modules

module Concentric::Model

	def self.included(aClass)
		aClass.cattr_accessor :rings_abilities
    aClass.rings_abilities = {}  # [1] => {read: [:name,:address], delete: true}
    aClass.send :extend, ClassMethods
  end

	module ClassMethods

		# supports different formats :
		# allow :sales, :write => [:name,:address]   ie. sales can write the name and address fields
		# allow :sales, :read                        ie. sales can read this model
		# allow :sales, [:read, :create, :destroy]   ie. sales can read, create and destroy this model
		def allow(aRing,aAbilities)
			#aRing.each {|r| ring(r,aAbilities)} and return if aRing.is_a? Array shouldn't need this because of ring system
			aRing = Concentric.lookup_ring(aRing)
			raise "aRing must be a number or a symbol defined in Concentric.config.ring_names" if !aRing.is_a?(Fixnum)
			raise "aAbilities must be a Hash" unless aAbilities.is_a? Hash # eg. :write => [:name,:address]

			ring_rec = self.rings_abilities[aRing]
			aAbilities.each do |abilities, fields|
				abilities = [abilities] unless abilities.is_a?(Array)
				fields = [fields] unless fields.is_a?(Array)
				next if fields.empty?
				abilities.each do |a|
					a = a.to_sym
					ring_rec ||= {}
					if fields==[:this]
						ring_rec[a] = true unless ring_rec[a].to_nil
					else
						ring_fields = ring_rec[a]
						ring_fields = [] unless ring_fields.is_a? Array
						ring_fields = ring_fields + fields.map(&:to_sym)
						ring_fields.uniq!
						ring_fields.sort!
						ring_rec[a] = ring_fields
					end
				end
				self.rings_abilities[aRing] = ring_rec
			end
		end

		# deprecated
		def ring(aRing,aAbilities)
			allow(aRing,aAbilities)
		end

		# returns properties that this ring can use this ability on
		def permitted(aRing,aAbility)
			aRing = Concentric.lookup_ring(aRing)
			raise "aRing must be a number or a symbol defined in Concentric.config.ring_names" if !aRing.is_a?(Fixnum)
			return [] unless aRing and rings_abilities = self.respond_to?(:rings_abilities) && self.rings_abilities.to_nil

			fields = []
			ring_keys = rings_abilities.keys.sort
			ring_keys.each do |i|
				next unless i >= aRing
				next unless ring_rec = rings_abilities[i]
				if af = ring_rec[aAbility.to_sym]
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
		def allowed?(aRing,aAbility,aFields=nil)
			if aFields
				pf = permitted(aRing,aAbility)
				if aFields.is_a? Array
					return (aFields - pf).empty?
				else
					return pf.include? aFields
				end
			end

			aRing = Concentric.lookup_ring(aRing)
			return [] unless aRing and rings_abilities = self.respond_to?(:rings_abilities).to_nil && self.rings_abilities

			ring_keys = rings_abilities.keys.sort
			ring_keys.each do |i|
				next unless i >= aRing
				next unless ring_rec = rings_abilities[i]
				return true if ring_rec[aAbility.to_sym].to_nil
			end
			return false
		end

		# deprecated
		def ring_can?(aRing,aAbility,aFields=nil)
			allowed?(aRing,aAbility,aFields)
		end

	end

end
