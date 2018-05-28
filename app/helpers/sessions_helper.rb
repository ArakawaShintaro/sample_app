module SessionsHelper
  def log_in(user)
    session[:user_id] = user.id
  end

  def current_user
    # ||=演算子を使うことでメモ化
    # なんどもクエリを発行しなくてよくなる
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    !!current_user
  end

  def log_out
    binding.pry
    session.delete(:user_id)
    @current_user = nil
  end
end
