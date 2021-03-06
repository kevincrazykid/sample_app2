# this is generated with the following command
# $ rails generate model User name:string email:string
class User < ActiveRecord::Base
  
  # added from listing 11.10, to set up the one to many relationship
  # between microposts and users
  # second part added from listing 11.18
  has_many :microposts, dependent: :destroy
  
  # implemented from listing 12.2, this set up the many-to-many
  # association between follower and followed; note the use of an
  # independent model relationship
  has_many :active_relationships, class_name: "Relationship",
                                  foreign_key: "follower_id",
                                  dependent: :destroy
  # added in listing 12.12; we simply implement the passive_relationships
  # which are analogous to active_relationships
  has_many :passive_relationships, class_name: "Relationship",
                                   foreign_key: "followed_id",
                                   dependent: :destroy
  # we override the default followed because of the awkward pluralization
  has_many :following, through: :active_relationships, source: :followed
  has_many :followers, through: :passive_relationships
  # added in 8.4.1 from listing 8.32, this line simply instantiate and set
  # the remember_token to be accessible from outside the class
  # we also added :activation_token to attr_accessor in listing 10.3
  # we added :reset_token to attr_accessor in listing 10.42
  attr_accessor :remember_token, :activation_token, :reset_token
    
  # we pust this line in at listing 6.31, ensures email uniqueness before
  # save
# before_save { self.email = email.downcase }

  # this is added from listing 10.3; commenting out the previous line,
  # method reference is used instead. Method reference is generally
  # preferred
  before_save :downcase_email
  # this is also added from listing 10.3; note the different method call
  # from before_save; this is because we want to create an
  # activation_digest before a user is created, since each newly signed-up
  # user will require activation. If we used before_save, the callback
  # will happen before the object is saved, which includes both creation
  # and update, but for activation we only want the callback to happen
  # when a user is created
  before_create :create_activation_digest
  
  # this line is put in in section 6.8 to validates for the presence
  # of a name
  
  # this allow user.valid? to be used, and also, to look at the full
  # error message, use user.errors.full_messages
  
# validates :name, presence: true
  # this is the same as validates(:name, presence: true)
# validates :email, presence: true
  # these lines are added in listing 6.16 to validate the length of name
  # and email attribute, to replace the previous two lines
  validates :name, presence: true, length: { maximum: 50 }
  # added from listing 6.21 to validate the format of an email address
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  # last line also checks for uniqueness of the email entry in database
  validates :email, presence: true, length: { maximum: 255 },
                                    format: { with: VALID_EMAIL_REGEX },
                                    uniqueness: { case_sensitive: false }
                                  # uniqueness: true
  # last line alters it so that case-insensitive uniqueness is enforced
  
  # listing 6.28: we added a migration to the model and typed this in:
  # $ rails generate migration add_index_to_users_email
  # this uses a rails method add_index to add an index to the email
  # column of the users table
  # we then execute a migration with the following command:
  # $ bundle exec rake db:migrate
  # the index also prevents a full-table scan (very costly) when finding
  # users by email address
  
  # as per 6.3.1, this line is added to enable password functionality
  # the only requirement for has_secure_password, a predefined rails
  # method, to work, is the addition of an attribute called
  # password_digest to the corresponding User model; to add that we
  # use the following line:
  # rails generate migration add_password_digest_to_users
  # password_digest:string
  has_secure_password
  
  # and finally, checking for length of the password, per listing 6.39
  
  # also, allow_blank: true is added in listing 9.10, to allow for a blank
  # password field when user is editing information and doesn't want to
  # change his password. has_secure_password automatically enforces
  # the presence of a password when a new account is created so no empty
  # password will be allowed in the user signup process
  validates :password, length: { minimum: 6 }, allow_blank: true
  
  # this is a class method for computing the password_digest from bcrypt
  # there are several places where this method can be placed, but since
  # later on we'll be reusing this method in the user model, this suggest
  # that we place the method here in User model, and since we won't
  # necessarily have access to a user object when we're using this method
  # we have to make it a class method
  # added from listing 8.18, returns the hash digest of the given string
  # and set the cost to be low for testing but normal for production
  def User.digest(string)
    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                  BCrypt::Engine.cost
    BCrypt::Password.create(string, cost: cost)
  end
  
  # added in 8.4.1 from listing 8.31, we simply added a method for making
  # tokens for use in remember_digest. similar to the digest method above,
  # because we would like to use the method without a user object, we make
  # this a class method as well
  # returns a random token
  def User.new_token
    # this is a method from the SecureRandom module in the Ruby standard
    # library that returns a random string of length 22 composed of the
    # characters A-Z, a-z, 0-9, and "-" and "_"
    SecureRandom.urlsafe_base64
  end
  
  # remembers a user in the database for use in persistent sessions
  def remember
    # the self is there to ensure assignment sets the user's remember_token
    # as its instance variable, instead of creating a local variable called
    # remember_token
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end
  
  # from 8.4.2, listing 8.33; this is simply a method similar to the
  # authenticate method in bcrypt, which compare the password_digest in
  # database and as generated to authenticate user
  # returns true if the given token 
# def authenticated?(remember_token)
    #listing 8.45, updating authenticated? to handle a nil remember digest
#   return false if remember_digest.nil?
    
#   BCrypt::Password.new(remember_digest).is_password?(remember_token)
# end
  
  # added in listing 10.24, and commenting out the previous method, this
  # is a more generalized version of the authenticated? method so as
  # to take into account we now have to use authenticated? for activating
  # a user account as well. Notice that we use the send method along with
  # string interpolation so that the name of the method for making a
  # digest can be passed in as an additional parameter and injected into
  # the method call to call the correct method; we updated the name to
  # reflect the fact this is now a more generic version. Note also that
  # we can pass in symbols or string as the parameter for send
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    # remember all the token and digest uses very similar method; thus
    # we uses the predefined method in BCrypt that compare the two and
    # return true if they match and false otherwise, or false if the
    # digest does not exist
    BCrypt::Password.new(digest).is_password?(token)
  end
  
  # added in 8.4.3, from listing 8.38, this undo the remember method so
  # user can be forgotten and therefore logout; specifically it sets the
  # password_digest value to nil
  def forget
    update_attribute(:remember_digest, nil)
  end
  
  # added from listing 10.3, these are private method only in use within
  # the User model; the method reference is at the top
  # converts email to all lower-case
  def downcase_email
    self.email = email.downcase
  end
  
  # creates and assigns the activation token and digest
  def create_activation_digest
    # remember User.new_token is a class method we defined above
    self.activation_token = User.new_token
    # activation_digest is part of the User model now so it is saved
    # automatically when the user is saved. Also remember, activation_token
    # is now an accessible attribute due to the attr_accessor on top
    # contrast this with remember method above, we don't use
    # update_attribute because this is before user creation and therefore
    # the user does not exist yet in the database
    self.activation_digest = User.digest(activation_token)
  end
  
  # added in listing 10.33, these two helper methods is a refactoring to
  # clean up the code
  def activate
    update_attribute(:activated, true)
    update_attribute(:activated_at, Time.zone.now)
  end
  
  # sends activation email
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end
  
  # added from listing 10.42, this is a helper method that sets the
  # password reset_digest to prepare for password reset
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest, User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end
  
  # added from listing 10.42 as well, this method sends password 
  # reset email out 
  def send_password_reset_email
    UserMailer.password_reset(self).deliver_now
  end
  # added from listing 10.53, this method is a helper method to check
  # if a password reset has expired
  def password_reset_expired?
    # this line meant reset is sent at earlier than two hours ago
    reset_sent_at < 2.hours.ago
  end
  
  # this method is added in listing 11.44; the question mark escape
  # the SQL and prevent a security hole called SQL injection
  # we further modified the feed to produce a final updated version that
  # included the followed feeds
  def feed
    # following_ids is a method predefined by rails; it takes the list of
    # following and convert them to an array of ids refer to 12.3.2
    # further modified in listing 12.46 to push the set logic into the
    # database
    following_ids = "SELECT followed_id FROM relationships
                     WHERE  follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
  end
  # added from listing 12.10
  def follow(other_user)
    active_relationships.create(followed_id: other_user.id)
  end
  def unfollow(other_user)
    active_relationships.find_by(followed_id: other_user.id).destroy
  end
  # include? is a predefined method that is automatically created because
  # of the association we put in
  def following?(other_user)
    following.include?(other_user)
  end
end
