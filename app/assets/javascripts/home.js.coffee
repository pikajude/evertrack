window.CurrentSprint = ($scope, $sce) ->
  window.scope = $scope
  $scope.isLoading = true
  $scope.noteSet = {}


  # Utilities

  $scope.parseHTML = (str) ->
    marked(str).replace /\[([x ])\]/g, (_, e) ->
      "<input type=checkbox #{if e == "x" then "checked" else ""}>"

  $scope.issue = (guid) -> $(".issue[data-guid=#{guid}]")

  $scope.loadStatus = ->
    if $scope.isLoading then "display: block" else "display: none"

  $scope.setCurrentNote = (note) ->
    $scope.currentNote = note
    $scope.noteSet[note.guid] = note


  # Initialization

  $.ajax
    dataType: "json"
    url: "/sprints/current"
    error: ->
      $(".loading").css display: "none"
      $(".load-error").css display: "block"
    success: (response) ->
      $scope.notes = response.notes
      for k, ns of $scope.notes
        $scope.noteSet[note.guid] = note for note in ns
      $scope.isLoading = false
      $scope.$apply()
      $scope.init()

  $scope.init = ->
    $(".issue").draggable
      start: -> console.log("started")
      stop: -> console.log("stopped")
      revert: true
      revertDuration: 0
      stack: ".issue"


  # Expanding

  $(document).on "click", ".issue a.issue-title", (e) ->
    e.preventDefault()
    i = $(e.target).parents ".issue"
    $scope.collapseAll()
    $scope.expand i.data("guid")

  $scope.expand = (guid) ->
    $scope.issue(guid).find(".issue-loading").css visibility: "visible"
    $.ajax
      dataType: "json",
      url: "/notes/view/#{guid}",
      success: $scope.expandNote


  # Collapsing

  $scope.collapseAll = ->
    $(".issue").each (_, _issue) ->
      issue = $(_issue)
      issue.html $scope.issueContents($scope.noteSet[issue.data("guid")], false).toString()

  $scope.expandNote = (resp) ->
    $scope.setCurrentNote(resp.note)
    $scope.currentNote.assignees = resp.assignees
    $scope.issue($scope.currentNote.guid).html(
      $scope.issueContents($scope.currentNote, true).toString()
    )
    $scope.$apply()


  # Assigning

  $(document).on "click", ".issue li .assign-link", (e) ->
    e.preventDefault()
    unless $(this).parent("li").hasClass "disabled"
      assignee = $(this).data "assign"
      guid = $(this).data "assign-to"
      $scope.assignTo guid, assignee

  $scope.assignTo = (guid, ass) ->
    $.ajax
      dataType: "json"
      url: "/notes/assign/#{$scope.currentNote.guid}"
      type: "POST"
      data:
        note: $scope.currentNote
        assignee: ass
      success: (note) ->
        $scope.setCurrentNote(note)
        $scope.issue(note.guid).html($scope.issueContents(note, false).toString())
      error: -> debugger


  # Editing

  $scope.editNote = (note) ->
    $("#issue-modal").on "shown.bs.modal", (e) ->
      $scope.editor = new EpicEditor(
        basePath: 'epiceditor/'
        theme:
          base: "epiceditor.css"
          preview: "github.css"
          editor: "epic-light.css"
        focusOnLoad: true
        parser: $scope.parseHTML
        textarea: "epicedit-text"
      ).load()
    $("#issue-modal").modal()

  $(document).on "click", ".issue .edit-button", (e) ->
    e.preventDefault()
    $scope.editNote $scope.currentNote


  # Saving

  $scope.saveCurrentNote = ->
    refr = $scope.issue($scope.currentNote.guid).find ".issue-refreshing"
    refr.css display: "block"
    $.ajax
      dataType: "json"
      url: "/notes/update/#{$scope.currentNote.guid}"
      type: "POST"
      data: $scope.currentNote
      success: (a,b,c) ->
        $scope.issue(a.guid).html $scope.issueContents(a, true).toString()
      error: (a,b,c) -> debugger

  $(document).on "click", "#save-btn", (e) ->
    $scope.editor.save()
    $scope.currentNote.content = $scope.editor.exportFile()
    $scope.saveCurrentNote()
    $("#issue-modal").modal("hide")


  # Closing

  $(document).on "click", ".issue .close-button", (e) ->
    e.preventDefault()
    $scope.collapseAll()

  $scope.issueContents = (note, expanded) ->
    entityMap =
      "&": "&amp;"
      "<": "&lt;"
      ">": "&gt;"
      '"': "&quot;"
      "'": "&#39;"
      "/": "&#x2F;"
    expandedContents = if expanded then note.content else ""
    for a, i in (note.assignees or [])
      note.assignees[i].current =
        note.assigned_to and a.email == note.assigned_to.email
    $sce.trustAsHtml(
      Mustache.render $scope.issueTemplate,
        note: note
        contents: $scope.parseHTML(note.content or "")
        expanded: expanded
    )

  $scope.issueTemplate = """
  {{#note.type}}
    <div class="issue-bar issue-bar-{{note.type}}"></div>
  {{/note.type}}
    <div class="issue-refreshing"></div>
    <div class="issue-header">
      <h3>
        {{#note.assigned_to}}
          <img class="pull-right assignee" src="http://www.gravatar.com/avatar/{{note.assigned_to.hash}}?s=26" alt="{{note.assigned_to.email}}">
        {{/note.assigned_to}}
        <a class=issue-title href=#>{{note.title}}</a>
        <img class="issue-loading" src=/assets/loading.gif>
      </h3>
      {{#expanded}}
        <div class="button-bar">
          <button type=button class="btn btn-default btn-xs edit-button">
            <span class="glyphicon glyphicon-cog"></span>
          </button>
          <div class="btn-group">
            <button type=button class="btn btn-success btn-xs assign-button dropdown-toggle" data-toggle="dropdown">
              <span class="glyphicon glyphicon-user"></span>
              {{#note.assigned_to.email}}
                {{note.assigned_to.email}}
              {{/note.assigned_to.email}}
              {{^note.assigned_to.email}}
                not assigned
              {{/note.assigned_to.email}}
              <span class="caret"></span>
            </button>
            <ul class="dropdown-menu" role="menu">
              {{#note.assignees}}
                {{#current}}
                  <li class="disabled"><a href=# class="assign-link" data-assign="{{email}}" data-assign-to="{{note.guid}}">{{email}}</a></li>
                {{/current}}
                {{^current}}
                  <li><a href=# class="assign-link" data-assign="{{email}}" data-assign-to="{{note.guid}}">{{email}}</a></li>
                {{/current}}
              {{/note.assignees}}
            </ul>
          </div>
          <button type=button class="btn btn-default btn-xs close-button pull-right">
            <span class="glyphicon glyphicon-remove"></span>
          </button>
        </div>
        <hr/>
      {{/expanded}}
    </div>
    {{#expanded}}
      <textarea id="epicedit-text">{{note.content}}</textarea>
      <div class="note-content">
        {{&contents}}
      </div>
    {{/expanded}}
  """
