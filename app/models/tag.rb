class Tag
  class << self
    attr_accessor :statuses
  end

  self.statuses = %w[ new started completed accepted rejected resolved ]
end
