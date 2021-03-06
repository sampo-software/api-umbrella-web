class ContactMailer < ActionMailer::Base
  default :from => "noreply@#{ApiUmbrellaConfig[:default_host]}"

  def contact_email(contact)
    @contact = contact

    mail :from => contact.email,
      :subject => "#{ApiUmbrellaConfig[:site_name]} Contact Message from #{contact.email}",
      :to => ApiUmbrellaConfig[:web][:contact_form_email]
  end
end
