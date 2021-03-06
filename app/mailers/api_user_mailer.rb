class ApiUserMailer < ActionMailer::Base
  default :from => "noreply@#{ApiUmbrellaConfig[:default_host]}"

  def signup_email(user)
    @user = user

    mail :subject => "Your #{ApiUmbrellaConfig[:site_name]} API key",
      :to => user.email
  end
end
