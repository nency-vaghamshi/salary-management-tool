module HasUniqueCode
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :code, presence: true, uniqueness: true
  end
end
