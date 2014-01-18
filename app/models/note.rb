class Note < ENObject
  attr_reader :status

  def self.model_name
    ActiveModel::Name.new(Note)
  end

  class Evernote::EDAM::Type::Note
    def self.model_name
      ActiveModel::Name.new(::Note)
    end
  end

  class << self
    def render_note xml
      Markdevn.to_md(xml)
    end

    def find(guid)
      n = client.note_store.getNote(client.token, guid, true, false, false, false)
      n.content = Note.render_note(n.content)
      Note.new(n, client.note_store.getNoteTagNames(client.token, guid))
    end

    def update(ps)
      params = ps.select do |k,v|
        %w[guid title content tagGuids].include?(k)
      end
      params["content"].strip!
      params["content"] = Markdevn.from_md(params["content"])
      note = Evernote::EDAM::Type::Note.new(params)
      client.note_store.updateNote(client.token, note)
      note.content = Note.render_note(note.content)
      Note.new(note, client.note_store.getNoteTagNames(client.token, params["guid"]))
    end

    def assign_to(note, ass)
      ps = note.select do |k,v|
        %w[guid title].include?(k)
      end
      n = Evernote::EDAM::Type::Note.new(ps)
      n.tagNames = note[:tags].reject do |tag|
        tag =~ /^assigned:/
      end
      n.tagNames << "assigned:#{ass}"
      client.note_store.updateNote(client.token, n)
      Note.new(n, n.tagNames)
    end

    def notes_for_current_sprint
      tags = Tag.statuses.map.with_index do |status, i|
        newer_tags = Tag.statuses[i+1..-1].map{|q| "-tag:#{q}" }.join(" ")
        n = client.note_store.findNotesMetadata(
          client.token,
          Evernote::EDAM::NoteStore::NoteFilter.new(words: "tag:#{status} #{newer_tags}"),
          0,
          10,
          Evernote::EDAM::NoteStore::NotesMetadataResultSpec.new(
            includeTitle: true,
            includeTagGuids: true
          )
        ).notes.map do |no|
          Note.new(no, client.note_store.getNoteTagNames(client.token, no.guid))
        end
        [status, n]
      end
      h = Hash[tags]
      h.default = []
      h
    end
  end

  def initialize m, tags
    @evnote = m
    @tags = tags
    @status = tags.find{|x|Tag.statuses.include?(x)}
  end

  def assignee
    tag_with_name("assigned", &User.method(:gravatar))
  end

  def type
    tag_with_name "type"
  end

  def tag_with_name n, &blk
    raise "Tags not set." unless @tags
    @tags.find{|tag| tag =~ /^#{n}:./ }.try do |tag|
      newname = tag.sub(/^#{n}:/, "")
      if block_given?
        blk.call newname
      else
        newname
      end
    end
  end

  def title
    @evnote.title
  end

  def guid
    @evnote.guid
  end

  def as_json(options)
    {
      guid: @evnote.guid,
      title: @evnote.title,
      assigned_to: assignee,
      content: @evnote.try(:content),
      type: type,
      tags: @tags
    }
  end
end
