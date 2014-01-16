class Note
  attr_reader :status

  def self.render_note xml
    debugger
    doc = Nokogiri::XML(xml).css("en-note")
    doc.css("en-todo").each do |todo|
      checked = todo.attr("checked") ? "checked" : ""
      todo.replace("<input type=checkbox #{checked}>")
    end
    doc.inner_html
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
