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
 	
 ```ruby	
 class Person < ActiveRecord::Base
   include CrewdPolicies::Model
 end
 ```
 
 
 2) declare constant arrays of field names, grouped to suit your application 
 
 ```ruby
 USER_EDITABLE_FIELDS = [:name,:address]
 ADMIN_FIELDS = [:roles]
 ALL_FIELDS = ADMIN_FIELDS + USER_EDITABLE_FIELDS
 ```
 		
 
 3) declare permissions using *allow()* and your constant arrays in your model
	
 ```ruby
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
 ```
 
 4) include CrewdPolicies::Policy into your ApplicationPolicy or individual model policies. You will also need the Scope inner class defined on your application and/or individual model policies :  
 	
 ```ruby
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
```
		
5) your User or Identity model must have a has_role?(aRole) method
 
 You now have a valid pundit policy that can be used like any other.
 
 **Parameters**
 
 `aRole`: a single string or symbol; or an array of strings and/or symbols
 `aAbilities`: a hash where -
  - `keys` are a single string or symbol; or an array of strings and/or symbols 
  - `values` are true, or a single string or symbol; or an array of strings and/or symbols
 
### Allow Syntax

The allow method is declared as :
 
```ruby
def allow(aRole, aAbilities)
end
```

It is used on the model class as follows :

```ruby
allow <role>, <abilities> => <fields>
```
 
Typical examples :

```ruby
allow :sales, :index => true		# sales role can create any record in scope
allow [:finance, :marketing], [:create,:destroy,:index] => true
allow :sales, :read => :name
allow :sales, :read => [:address,:phone]
allow :reception, [:read,:write] => [:address,:phone]
```
 
### Allow Conditions
 
An allow statement can be made conditional by adding an :if or :unless key.
The value should be a symbol matching the name of a method with no parameters on the policy.
 
For example, we want users to be able to edit their own password :

on model :

```ruby
allow :user, write: :password, if: :is_self?
```

on policy :

```ruby
def is_self?
	record and !record.is_a?(Class) and record.id==identity.id
end
```
  
Note that without the if condition, any user would be able to write any user's password.

### Required allow declarations for a full CRUD policy in Rails

In order to allow full CRUD on a resource in a Rails application, you will need to write allow declarations for each of the following abilities :

| Allow Ability | Example  
| :---          | :---    
| create				| allow :user, create: true
| read					| allow :user, read: %w(name address)
| write					| allow :user, write: %w(name address password)
| destroy				| allow :user, destroy: true
| index					| allow :user, index: true

## Derived Application Requirements 

Typical Rails application policy requirements can then be derived from the above without additional implementation code.

For each of these boolean permissions to return true, the **bold** allow declarations are required. The other declarations are most likely needed according to your application ie there probably isn't much use in create or index without allowing any fields.

Note that for normal Rails CRUD requirements, fields are only declared for read and write

   
| CREWD policy method | >= 1 read fields 	| >=1 write fields 												| true flag 
| :---                |     :---:        	|     :---:        												| :---
| create?   					| 								 	| allow :user, :write => %w(name address) | **allow :user, :create => true**
| read?     					| **allow :user, :read => %w(name address)**
| write?   					|        						| **allow :user, :write => %w(name address)** |
| destroy?  					|        						|       																	| **allow :user, :destroy => true**
| index?    					| allow :user, :read => %w(name address)       						|       																	| **allow :user, :index => true**
   
The above CREWD policy methods are then aliased to provide typical Rails policy methods as follows 

| Rails policy method | CREWD policy method 	| 
| :---                |     :---        	|
| create?   					| create?								 	|
| show?   					| read?								 	|
| update?   					| write?								 	|
| edit?   					| write?								 	|
| index?   					| index?								 	|
| delete?   					| destroy?								 	|
| destroy?   					| destroy?								 	|

Other Pundit conventional Rails methods are also provided :

* the following permitted attributes for "strong parameters" :  
	* permitted_attributes (equivalent to permitted_attributes_for_write) 
	* permitted_attributes_for_write 
	* permitted_attributes_for_read 
	* permitted_attributes_for_create 
	* permitted_attributes_for_update 
	* permitted_attributes_for_edit 
	* permitted_attributes_for_show 
	* permitted_attributes_for_index 

This should meet the access control needs for the vast majority of Rails projects.  
  
### Controller Examples

```ruby
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
```
 
## Core Assumptions

CREWD Policies builds policies based on the core assumption that by declaring the following permissions, a complete permissions system can be derived by code for 90+% of models down to the field level : 

	- scope for the resource 
	- create for the resource 
	- readable fields
	- writeable fields  
	- delete for a record
	- normal Rails model validations for validating field values

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

1. *User or Identity Model* : Traditional Rails applications have a User model which maps to a database table of users. An emerging architecture pattern uses JSON Web Tokens (http://jwt.io) to represent an identity managed by an external provider. Applications then will typically need an additional model eg. `Person` for attaching persisted data to that provided by the identity token. I have had success creating an `Identity` model; not backed by the database but created in memory by decoding the JWT. It then has methods for loading a `Person` model if required. This is how we intend to do things in future, and so the property name I am using here is `identity`, but I also use an alias of user pointing referring to it.

2. `identity.has_role?(aRole)` : In order to interrogate the roles assigned the `identity` has, the method `has_role?(aRole)` must be implemented to receive a role string or symbol, and return true or false. 

## Why Pundit::NotAuthorizedError is misleading

`Pundit` defines this error, and raises it when the authorize method rejects a query. Unfortunately, in this case, Pundit users could easily assume they should return the HTTP status `401 Unauthorized`, but this would be against the definition for this status code.
 
 > "The request has not been applied because it lacks valid authentication credentials for the target resource" - https://httpstatuses.com/401
 
Failing pundit checks rarely has anything to do with a lack of credentials, the failure is more likely a case of 
  
 > "The server understood the request but refuses to authorize it." - https://httpstatuses.com/403

It gets even worse if you follow a pattern in your client of forcing a logout of the user when they receive a 401, which makes sense when 401 is used correctly. The result is that attempting anything not allowed by a policy causes the user to be logged out, when they should simply be shown an alert and given the opportunity to correct the error or do something else while maintaining their session.

Pundit does have this in the README https://github.com/elabs/pundit#rescuing-a-denied-authorization-in-rails, but it is easily missed and naming mismatch is still likely to trip up new users.

https://github.com/elabs/pundit/issues/412

As an initial mitigation, crewd-policies provides the `CrewdPolicies::ForbiddenError` exception and the `forbidden!` method.

## Development

After checking out the repo, to install dependencies run:

    bin/setup

Then, run tests with:

    rake spec

For an  interactive prompt that will allow you to experiment, you can also run

    bin/console

To install this gem onto your local machine, run 

    bundle exec rake install
    
To release a new version, update the version number in `version.rb`, and then run

    bundle exec rake release

`rake release` will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

To experiment with this gem with interactive prompt, run

     bin/console

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



`create?` - resource_create? & model validation (RESOURCE LEVEL)
`read?` - in scope & >0 readable attributes (FIELD LEVEL)
`write?` - in scope & >0 writeable attributes & model validation (FIELD LEVEL)
`destroy?` - in scope & record_destroy? (RECORD LEVEL)

aliases :
`show?`
`update?`
`index?`
`delete?`


=== protected methods implemented for each resource

```ruby
Policy.new(identity,Model).resource_create?	// from the model for roles
Policy.new(identity,model).record_destroy?	// from the model for roles
Policy.new(identity,model).read_attributes  // from the model for roles
Policy.new(identity,model).write_attributes  // from the model for roles
Scope.exists?
```


On Model :

```ruby
allow [:staff,:provider_admin], write: EDITABLE_FIELDS, read: ALL_FIELDS
allow :staff, [:create] => :this
allow :dealer_admin, [:destroy] => :this
```

! Still need code override eg. for reading all records but only writing own, but perhaps we can add when clause :

```ruby
allow :staff, [:destroy] => :this, when: ->(identity,model) { !model.published }
```

OR

```ruby
allow :staff, [:destroy] => :this, when: :staff_can_destroy? # def staff_can_destroy? on policy
```