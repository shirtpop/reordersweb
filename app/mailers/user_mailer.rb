# app/mailers/user_mailer.rb
class UserMailer < ApplicationMailer
  def welcome_client
    @user = User.find params[:user_id]
    @password = params[:password]

    mail(
      to: @user.email,
      subject: "Ordering company swag just got way easier (and 100% free) 🚀"
    )
  end
end
