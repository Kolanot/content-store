class RegisterableRoute < Struct.new(:path, :type, :rendering_app)
  include ActiveModel::Validations

  validates :type, inclusion: { in: %w(exact prefix), message: 'must be either "exact" or "prefix"' }
  validates :path, absolute_path: true
  validates :path, :type, :rendering_app, presence: true
end