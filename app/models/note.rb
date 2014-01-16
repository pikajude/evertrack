class Note
  attr_reader :status

  def self.render_note xml
    Markdevn.to_md(xml)
  end

  def initialize m, tag
    @evnote = m
    @status = tag
  end

  def title
    @evnote.title
  end

  def as_json(options)
    {guid: @evnote.guid, title: @evnote.title}
  end
end
