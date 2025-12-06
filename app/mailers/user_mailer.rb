class UserMailer < ApplicationMailer
  def reset_password(user)
    @user = user

    if @user.reset_password_token.blank?
      @user.generate_password_reset_token!
      @user.reload
    end

    token = @user.reset_password_token
    raise "Missing reset token" if token.blank?

    @reset_url = edit_password_reset_url(id: token)

    mail(
      from: ENV.fetch("DEFAULT_FROM_EMAIL", "projecttravelplanner@gmail.com"),
      to: @user.email,
      subject: "Reset your password"
    )
  end
end