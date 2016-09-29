class Offense < ActiveRecord::Base
  validates :description, presence: true
end
