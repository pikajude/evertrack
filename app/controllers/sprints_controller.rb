class SprintsController < ApplicationController
  respond_to :json

  def current
    require_client
    t = Time.now
    @tags = cache "tags" do
      @client.note_store.listTags(@client.token).select do |tag|
        Tag.statuses.include?(tag.name)
      end
    end
    @notes = Hash[Tag.statuses.map.with_index do |status, i|
      n = cache([t.year, t.wday, "tagged", status]) do
        newer_tags = Tag.statuses[i+1..-1].map{|q| "-tag:#{q}"}.join(" ")
        @client.note_store.findNotesMetadata(
          @client.token,
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
            cache(["tag", tag]) do
              @client.note_store.getTag(@client.token, tag)
            end
          end
          n
        end
      end
      [status, n]
    end]
    @notes.default = []

    respond_with({
      :notes => @notes,
      :tags => @tags
    })
  end

  def view
    require_client
    @note = cache(["notes", params[:guid]]) do
      @client.note_store.getNote(@client.token, params[:guid], true, false, false, false)
    end
    @note.content = Note.render_note(@note.content)
    respond_with(@note)
  end

  private
  def require_client
    @client ||= client
  end

  def client
    token = "S=s1:U=8da82:E=14ad5725935:C=1437dc12d3a:P=1cd:A=en-devtoken:V=2:H=d8f71dc74b011e120ead43dcf1609542"
    t = EvernoteOAuth::Client.new(token: token)
    class << t
      attr_reader :token
    end
    t
  end
end
