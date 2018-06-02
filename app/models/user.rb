class User < ApplicationRecord
  #トークンはデータベースに保存せずに実装する必要がある
  attr_accessor :remember_token

  # DBのレイヤーが大文字小文字を区別するアダプターもあるため、小文字に変換する
  before_save { self.email = email.downcase }

  # validation
  validates :name, presence: true, length: { maximum: 50 }
  VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
  validates :email, presence: true, length: { maximum: 255 },
                    format: { with: VALID_EMAIL_REGEX },
                    uniqueness: { case_sensitive: false }
  validates :password,  presence: true, length: { minimum: 6 }, allow_nil: true

  has_secure_password

  class << self
    # 渡された文字列のハッシュ値を返す
    def digest(string)
      cost =  ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                     BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    # ランダムなトークンを返す
    def new_token
      SecureRandom.urlsafe_base64
    end
  end

  #記憶トークンをユーザーと関連付け、トークンに対応する記憶ダイジェストをデータベースに保存
  def remember
    self.remember_token = User.new_token
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  def authenticated?(remember_token)
    return false if remember_digest
    BCrypt::Password.new(remember_digest).is_password?(remember_token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end
end
