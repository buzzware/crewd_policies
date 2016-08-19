# CrewdPolicies

CrewdPolicies enables conventional Pundit (https://github.com/elabs/pundit) policies to be written using an opinionated pattern based on declarative Create, Read, Execute (optional), Write and Destroy (CREWD) permissions for each resource. Conventional pundit create?, show?, update? and destroy? permissions are automatically derived from these, as well as permitted_attributes/strong parameters.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'crewd_policies'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install crewd_policies

## Usage

The happy path that CREWD policies enables is as follows :

 1) include CrewdPolicies::Model into your models
 	eg.
 	
 	class Person < ActiveRecord::Base
 		include CrewdPolicies::Model
 	end
 
 
 2) declare constant arrays of field names, grouped to suit your application 
 	eg. 
 		USER_EDITABLE_FIELDS = [:name,:address]
 		ADMIN_FIELDS = [:roles]
 		ALL_FIELDS = ADMIN_FIELDS + USER_EDITABLE_FIELDS
 		
 
 3) declare permissions using *allow()* and your constant arrays in your model
	eg.
	 
 	class Customer < ActiveRecord::Base
 		include CrewdPolicies::Model
 		
 		PUBLIC_FIELDS = [:name]
 		USER_EDITABLE_FIELDS = [:name,:address]
 		ADMIN_FIELDS = [:roles]
 		ALL_FIELDS = ADMIN_FIELDS + USER_EDITABLE_FIELDS
 		 		
 		allow :sales, :create => :this
 		allow :sales, :read => ALL_FIELDS
 		allow :sales, :write => USER_EDITABLE_FIELDS
 		
 		allow :admin, :write => ALL_FIELDS
 		allow :admin, :destroy => :this 		
 	end
 
 	4) include CrewdPolicies::Policy into your ApplicationPolicy or individual model policies. You will also need the Scope inner class defined on your application and/or individual model policies :  
 	
		class ApplicationPolicy < Struct.new(:identity, :subject)
			include CrewdPolicies::Policy
			
			class Scope < Struct.new(:identity, :scope)
				def resolve
					scope.where(...your criteria...)
				end
			end		
		end 	
 	 	
		class CustomerPolicy < Struct.new(:identity, :subject)	
		end
		
	5) your User or Identity model must have a has_role?(aRole) method
 
 You now have a valid pundit policy that can be used like any other.
 
### Allow Syntax

The allow method is declared as :
 
def allow(
	aRole,			# a single string or symbol; or an array of strings and/or symbols
	aAbilities	# a hash where :
							#		* keys are a single string or symbol; or an array of strings and/or symbols 
							#		* values are true, or a single string or symbol; or an array of strings and/or symbols
)

It is used on the model class as follows :

allow <role>, <abilities> => <fields>
 
Typical examples :

* allow :sales, :index => true		# sales role can create any record in scope
* allow [:finance, :marketing], [:create,:destroy,:index] => true
* allow :sales, :read => :name
* allow :sales, :read => [:address,:phone]
* allow :reception, [:read,:write] => [:address,:phone]
 
### Controller Examples

def index	
	@posts = authorize policy_scope!(Post)
	# use per post @attributes = @post.attributes.slice permitted_attributes(@post)
end

def show	
	@post = authorize policy_scope!(Post).find(params[:id])
	@attributes = @post.attributes.slice permitted_attributes(@post)
end

def create
	pars = params.require(:post).permit policy!(Post).permitted_attributes
	@post = authorize policy_scope!(Post).create!(pars)	
end

def update
	@post = authorize policy_scope!(Post).find(params[:id])
	pars = params.require(:post).permit policy!(Post).permitted_attributes
  @post.update_attributes(pars)
  @post.save!
end

def destroy
	@post = authorize policy_scope!(Post).find(params[:id])
	@post.destroy!
end
 
## Core Assumptions

CREWD Policies builds policies based on the core assumption that by declaring the following permissions, a complete permissions system can be derived by code for 90+% of models down to the field level : 

	1. scope for the resource 
	1. create for the resource 
	1. readable fields
	1. writeable fields  
	1. delete for a record
	1. normal Rails model validations for validating field values

Expanding on the above :

1. The relevant policy scope should be used as a normal practice for all operations, unless there is a good reason. Rails scopes limit access for select, update and delete queries; and set default values for insert queries. The other permissions assume the proper scope has been applied.

1. create? permission requires : 
	1. a resource level permission (ie. "Can this role create customers at all?")
	1. field level _write_ permissions (ie. "When creating customers, what fields can be provided by this role?"
	1. field values that pass the normal Rails model validations - this is left to the user and out of the scope of this gem.
	
1. read? permission requires :
	1. at least 1 readable field
	
1. write? permission requires :
	1. at least 1 writeable field
	1. field values that pass the normal Rails model validations - this is left to the user and out of the scope of this gem.

1. destroy? permission requires :
	1. a record level permission (ie. "Can this role destroy this customer?")

## User/Identity Model Assumptions

1. *User or Identity Model* : Traditional Rails applications have a User model which maps to a database table of users. An emerging architecture pattern uses JSON Web Tokens (http://jwt.io) to represent an identity managed by an external provider. Applications then will typically need an additional model eg. Person for attaching persisted data to that provided by the identity token. I have had success creating an Identity model; not backed by the database but created in memory by decoding the JWT. It then has methods for loading a Person model if required. This is how we intend to do things in future, and so the property name I am using here is "identity", but I also use an alias of user pointing referring to it.

2. *identity.has_role?(aRole)* : In order to interrogate the roles assigned the identity has, the method has_role?(aRole) must be implemented to receive a role string or symbol, and return true or false. 

## Derived Application Requirements 

Typical Rails application policy requirements can then derived or simply aliases from the above, without additional implementation, including :
  
* show?
* update?
* index?
* delete?
* selectable attributes
* permitted attributes for "strong parameters"

This should meet the access control needs for the vast majority of Rails projects.  

## Why Pundit::NotAuthorizedError is misleading

Pundit defines this error, and raises it when the authorize method rejects a query. Unfortunately, in this case, Pundit users could easily assume they should return the HTTP status "401 Unauthorized", but this would be against the definition for this status code.
 
 "The request has not been applied because it lacks valid authentication credentials for the target resource" - https://httpstatuses.com/401
 
Failing pundit checks rarely has anything to do with a lack of credentials, the failure is more likely a case of 
  
 "The server understood the request but refuses to authorize it." - https://httpstatuses.com/403

It gets even worse if you follow a pattern in your client of forcing a logout of the user when they receive a 401, which makes sense when 401 is used correctly. The result is that attempting anything not allowed by a policy causes the user to be logged out, when they should simply be shown an alert and given the opportunity to correct the error or do something else while maintaining their session.

Pundit does have this in the README https://github.com/elabs/pundit#rescuing-a-denied-authorization-in-rails, but it is easily missed and naming mismatch is still likely to trip up new users.

https://github.com/elabs/pundit/issues/412

As an initial mitigation, crewd-policies provides the CrewdPolicies::ForbiddenError exception and the forbidden! method.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To experiment with this gem, run `bin/console` for an interactive prompt.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/crewd_policies. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Notes

SuperPundit

=== public methods

| Pundit method | Center-aligned | Right-aligned |
| :---         |     :---:      |          ---: |
| create?   | git status     | git status    |
| read?     | git diff       | git diff      |



create? - resource_create? & model validation (RESOURCE LEVEL)
read? - in scope & >0 readable attributes (FIELD LEVEL)
write? - in scope & >0 writeable attributes & model validation (FIELD LEVEL)
destroy? - in scope & record_destroy? (RECORD LEVEL)

aliases :
show?
update?
index?
delete?


=== protected methods implemented for each resource

Policy.new(identity,Model).resource_create?	// from the model for roles
Policy.new(identity,model).record_destroy?	// from the model for roles
Policy.new(identity,model).read_attributes  // from the model for roles
Policy.new(identity,model).write_attributes  // from the model for roles
Scope.exists?


On Model :

allow [:staff,:provider_admin], write: EDITABLE_FIELDS, read: ALL_FIELDS
allow :staff, [:create] => :this
allow :dealer_admin, [:destroy] => :this

! Still need code override eg. for reading all records but only writing own, but perhaps we can add when clause :

allow :staff, [:destroy] => :this, when: ->(identity,model) { !model.published }
OR
allow :staff, [:destroy] => :this, when: :staff_can_destroy? # def staff_can_destroy? on policy


