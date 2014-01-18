class SprintsController < ApplicationController
  respond_to :json

  def current
    begin
      t = Time.now
      @tags = cache("tags") { Tag.all_tags }
      @notes = cache(["sprint", t.year, t.wday]) do
        Note.notes_for_current_sprint
      end
    rescue => e
      p e
      raise e
    end

    respond_with({
      :notes => @notes,
      :tags => @tags
    })
  end
end
