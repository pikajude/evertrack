class NotesController < ApplicationController
  respond_to :json

  def view
    @note = cache(["notes", params[:guid]]) do
      Note.find(params[:guid])
    end
    respond_with({
      note: @note,
      assignees: %w[me@joelt.io dan@outright.com trobrock@gmail.com].map do |email|
        User.gravatar email
      end
    })
  end

  def note_url note
    "/sprints/view/#{note.guid}"
  end

  def update
    expire_fragment ["notes", params[:guid]]
    respond_with(Note.update(params))
  end

  def assign
    expire_fragment ["notes", params[:guid]]
    respond_with(Note.assign_to(params[:note], params[:assignee]))
  end
end
