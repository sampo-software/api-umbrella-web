class AdminGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Mongoid::Userstamp
  include Mongoid::Delorean::Trackable

  # Fields
  field :_id, :type => String, :default => lambda { UUIDTools::UUID.random_create.to_s }
  field :name, :type => String

  # Relations
  has_and_belongs_to_many :api_scopes, :class_name => "ApiScope", :inverse_of => nil
  has_and_belongs_to_many :permissions, :class_name => "AdminPermission", :inverse_of => nil

  # Validations
  validate :validate_permissions

  # Mass assignment security
  attr_accessible :name,
    :permission_ids,
    :api_scope_ids,
    :as => [:admin]

  def can?(permission)
    permissions = self.permission_ids || []
    permissions.include?(permission.to_s)
  end

  private

  def validate_permissions
    unknown_permissions = self.permission_ids - [
      "analytics",
      "user_view",
      "user_manage",
      "admin_manage",
      "backend_manage",
      "backend_publish",
    ]

    if(unknown_permissions.any?)
      errors.add(:permission_ids, "unknown permissions: #{unknown_permissions.inspect}")
    end
  end
end
