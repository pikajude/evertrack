class Note
  attr_reader :status
  attr_writer :tags

  def self.render_note xml
    Markdevn.to_md(xml)
  end

  def initialize m, tag
    @evnote = m
    @status = tag
  end

  def assignee
    raise "Tags not set." unless @tags
    @tags.find{|tag| tag.name =~ /^assigned:./ }.try{|tag|
      email = tag.name.sub("assigned:", "")
      {
        email: email,
        hash: Digest::MD5.hexdigest(email.strip.downcase)
      }
    }
  end

  def title
    @evnote.title
  end

  def as_json(options)
    {
      guid: @evnote.guid,
      title: @evnote.title,
      assigned_to: assignee
    }
  end
end
