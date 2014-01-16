class Note < ENObject
  attr_reader :status
  attr_writer :tags

  class << self
    def render_note xml
      Markdevn.to_md(xml)
    end

    def find(guid)
      n = client.note_store.getNote(client.token, guid, true, false, false, false)
      n.content = Note.render_note(n.content)
      n
    end

    def update(ps)
      params = ps.select do |k,v|
        %w[guid title content tagGuids].include?(k)
      end
      client.note_store.updateNote(
        client.token,
        Evernote::EDAM::Type::Note.new(params)
      )
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
          n = Note.new(no, status)
          n.tags = no.tagGuids.map do |tag|
            client.note_store.getTag(client.token, tag)
          end
          n
        end
        [status, n]
      end
      h = Hash[tags]
      h.default = []
      h
    end
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
