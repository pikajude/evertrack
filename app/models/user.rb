class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  def self.gravatar email
    {
      email: email,
      hash: Digest::MD5.hexdigest(email.strip.downcase)
    }
  end
end
