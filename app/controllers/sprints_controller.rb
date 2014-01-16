class SprintsController < ApplicationController
  respond_to :json

  def current
    require_client
    t = Time.now
    @tags = cache("tags") { Tag.all_tags }
    @notes = cache(["sprint", t.year, t.wday]) do
      Note.notes_for_current_sprint
    end

    respond_with({
      :notes => @notes,
      :tags => @tags
    })
  end

  def view
    require_client
    @note = cache(["notes", params[:guid]]) do
      Note.find(params[:guid])
    end
    respond_with(@note)
  end

  def update
    respond_with(Note.update(params))
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
