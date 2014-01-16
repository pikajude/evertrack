class Tag < ENObject
  class << self
    attr_accessor :statuses

    def all_tags
      client.note_store.listTags(client.token)
    end
  end

  self.statuses = %w[ new started completed accepted rejected resolved ]
end
