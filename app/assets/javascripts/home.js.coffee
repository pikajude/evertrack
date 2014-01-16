window.CurrentSprint = ($scope, $sce) ->
  window.scope = $scope
  $scope.isLoading = true
  $scope.noteSet = {}

  $.ajax({
    dataType: "json",
    url: "/sprints/current",
    error: -> $(".loading, .load-error").css({display: "none"})
    success: (response) ->
      $scope.notes = response.notes
      for k, ns of $scope.notes
        $scope.noteSet[note.guid] = note for note in ns
      $scope.isLoading = false
      $scope.$apply()
      $scope.init()
  })

  $scope.init = ->
    $(".issue").draggable({
      start: -> console.log("started"),
      stop: -> console.log("stopped"),
      revert: true,
      revertDuration: 0,
      stack: ".issue"
    })

  $(document).on "click", ".issue a.issue-title", (e) ->
    e.preventDefault()
    i = $(e.target).parents(".issue")
    $scope.collapseAll()
    $scope.expand(i.data("guid"))

  $(document).on "click", ".issue .edit-button", (e) ->
    e.preventDefault()
    $scope.editNote($scope.currentNote)

  $scope.loadStatus = ->
    if $scope.isLoading then "display: block" else "display: none"

  $scope.expand = (guid) ->
    $(".issue[data-guid=#{guid}] .issue-loading").css({
      visibility: "visible"
    })
    $.ajax({
      dataType: "json",
      url: "/sprints/view/#{guid}",
      success: $scope.expandNote
    })

  $scope.collapseAll = () ->
    $(".issue").each (_, _issue) ->
      issue = $(_issue)
      issue.html($scope.issueContents($scope.noteSet[issue.data("guid")], false).toString())

  $scope.expandNote = (note) ->
    $scope.currentNote = note
    $(".issue[data-guid=#{note.guid}]").
      html($scope.issueContents(note, true).toString())
    $scope.$apply()

  # Editing

  $(document).on "click", "#save-btn", (e) ->
    $scope.editor.save()
    $scope.currentNote.content = $scope.editor.exportFile()
    $scope.saveCurrentNote()
    $("#issue-modal").modal("hide")
    $(".issue[data-guid=#{$scope.currentNote.guid}]").html(
      $scope.issueContents($scope.currentNote, true).toString()
    )

  $scope.saveCurrentNote = ->
    $.ajax({
      dataType: "json",
      url: "/sprints/update/#{$scope.currentNote.guid}",
      type: "POST",
      data: $scope.currentNote
      success: (a,b,c) -> debugger,
      error: (a,b,c) -> debugger
    })

  $scope.editNote = (note) ->
    $("#issue-modal").on("shown.bs.modal", (e) ->
      $scope.editor = new EpicEditor({
        basePath: 'epiceditor/',
        theme: {
          base: "epiceditor.css",
          preview: "github.css",
          editor: "epic-light.css"
        },
        focusOnLoad: true,
        parser: $scope.parseHTML,
        textarea: "epicedit-text"
      }).load()
    )
    $("#issue-modal").modal()

  $scope.parseHTML = (str) ->
    marked(str).replace /\[([x ])\]/g, (_, e) ->
      "<input type=checkbox #{if e == "x" then "checked" else ""}>"

  $scope.issueContents = (note, expanded) ->
    entityMap = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#39;",
      "/": "&#x2F;",
    }
    expandedContents = if expanded then note.content else ""
    $sce.trustAsHtml(
      Mustache.render($scope.issueTemplate,
        {
          note: note,
          contents: $scope.parseHTML(note.content or ""),
          expanded: expanded
        }
      )
    )

  $scope.issueTemplate = """
    <h3>
      <a class=issue-title href=#>{{note.title}}</a>
      <img class="issue-loading" src=/assets/loading.gif>
      {{#expanded}}
        <button type=button class="btn btn-default btn-xs edit-button pull-right">
          <span class="glyphicon glyphicon-cog"></span>
          Edit
        </button>
      {{/expanded}}
      {{^expanded}}
        {{#note.assigned_to}}
          <img class="pull-right assignee" src="http://www.gravatar.com/avatar/{{note.assigned_to.hash}}?s=26" alt="{{note.assigned_to.email}}">
        {{/note.assigned_to}}
      {{/expanded}}
    </h3>
    {{#expanded}}
      <textarea id="epicedit-text">{{note.content}}</textarea>
      <div class="note-content">
        {{&contents}}
      </div>
    {{/expanded}}
  """
