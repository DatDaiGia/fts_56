class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  devise :omniauthable, omniauth_providers: [:facebook]
  devise :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :activities, dependent: :destroy
  has_many :exams, dependent: :destroy
  has_many :results, through: :exams
  has_many :questions, dependent: :destroy

  class << self
    def from_omniauth auth
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.email = auth.info.email
        user.password = Devise.friendly_token[0,20]
        user.username = auth.info.username
      end
    end

    def new_with_session params, session
      super.tap do |user|
        if data = session["devise.facebook_data"] &&
            session["devise.facebook_data"]["extra"]["raw_info"]
          user.email = data["email"] if user.email.blank?
        end
      end
    end
  end

  def self.from_omniauth access_token
    data = access_token.info
    user = User.where(:email => data["email"]).first
    unless user
      user = User.create(name: data["name"],
        email: data["email"],
        password: Devise.friendly_token[0,20]
      )
    end
    user
  end
end
