# ruby
class UserMailer < ApplicationMailer
  def reset_password(user)
    @user = user
    @reset_url = edit_password_reset_url(@user.reset_password_token)
    mail(to: @user.email, subject: 'Reset your password')
  end
end
