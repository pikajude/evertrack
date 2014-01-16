window.CurrentSprint = ($scope, $sce) ->
  window.scope = $scope
  $scope.isLoading = true
  $scope.noteSet = {}

  $.ajax({
    dataType: "json",
    url: "/sprints/current",
    error: (_1, _2, text) ->
      $(".loading").css({display: "none"})
      $(".load-error").css({display: "block"})
    success: (response) ->
      $scope.notes = response.notes
      for k, ns of $scope.notes
        for note in ns
          $scope.noteSet[note.guid] = note
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

  $(document).on "click", ".issue a", (e) ->
    e.preventDefault()
    i = $(e.target).parents(".issue")
    $scope.collapseAll()
    $scope.expand(i.data("guid"))

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
    $(".issue[data-guid=#{note.guid}]")
      .html($scope.issueContents(note, true).toString())
    $scope.$apply()

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
          expanded: expanded
        }
      )
    )

  $scope.issueTemplate = """
    <h3>
      <a href=#>{{note.title}}</a>
      <img class="issue-loading" src=/assets/loading.gif>
      {{#expanded}}
        <button type=button class="btn btn-default btn-xs pull-right">
          <span class="glyphicon glyphicon-cog"></span>
          Edit
        </button>
      {{/expanded}}
    </h3>
    {{#expanded}}
      <div class="note-content">
        {{&note.content}}
      </div>
    {{/expanded}}
  """
