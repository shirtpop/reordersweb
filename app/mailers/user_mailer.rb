# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def welcome_client
    @user = User.find params[:user_id]
    @password = params[:password]

    mail(
      to: @user.email,
      subject: "Welcome to Our Platform!"
    )
  end
end
