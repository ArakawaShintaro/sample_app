class User < ApplicationRecord
  has_many :microposts, dependent: :destroy

  #トークンはデータベースに保存せずに実装する必要がある
  attr_accessor :remember_token, :activation_token, :reset_token

  # DBのレイヤーが大文字小文字を区別するアダプターもあるため、小文字に変換する
  before_save :downcase_email
  before_create :create_activation_digest

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
    # DBから盗まれないようにダイジェスト（ハッシュ）化する必要がある
    update_attribute(:remember_digest, User.digest(remember_token))
  end

  # 渡されたトークンがダイジェストと一致したらtrueを返す
  # sendでremember、activationどちらも使用できるように抽象化
  def authenticated?(attribute, token)
    digest = send("#{attribute}_digest")
    return false if digest.nil?
    BCrypt::Password.new(digest).is_password?(token)
  end

  def forget
    update_attribute(:remember_digest, nil)
  end

  # アカウントを有効にする
  def activate
    update_attribute(:activated, true)
    update_attribute(:activated_at, Time.zone.now)
  end

  # 有効化用のメールを送信する
  def send_activation_email
    UserMailer.account_activation(self).deliver_now
  end

  # パスワード再設定の属性を設定する
  def create_reset_digest
    self.reset_token = User.new_token
    update_attribute(:reset_digest, User.digest(reset_token))
    update_attribute(:reset_sent_at, Time.zone.now)
  end

  def send_password_reset_email
     UserMailer.password_reset(self).deliver_now
  end

  def password_reset_expired?
    reset_sent_at < 2.hours.ago
  end

  def feed
    Micropost.where("user_id = ?", id)
  end

  private

    def downcase_email
      self.email = email.downcase
    end

    def create_activation_digest
      self.activation_token  = User.new_token
      self.activation_digest = User.digest(activation_token)
    end
end
