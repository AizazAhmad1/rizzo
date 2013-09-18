# AutoComplete
#
# TODO: - there's a bug with accented characters, they aren't being highlighted
#         (http://instanceof.me/post/17455522476/accent-folding-javascript as a possible solution)
#       - possibly cancel an existing XHR if typing continues and the last one hasn't returned yet
#       - put the classes into a config object
#       - abstract the XHR code to a separate library
#
# Arguments:
#   _args (An object containing)
#     id        : [string] The target form element
#     uri       : [string] The search endpoint
#     listOnly  : [boolean] (Optional) Flag whether to only show the list of results
#     scope     : [string] (Optional) Value to specify as the scope of the search
#
# Example:
#  args =
#    id: 'my_search'
#    uri: '/search'
#    scope: 'homepage'
#
#  new AutoComplete(args)
#
# Dependencies:
#   None

required = if window.lp.isMobile then 'jsmin' else 'jquery'

define [required, 'lib/extends/events'], ($, EventEmitter) ->

  class AutoComplete

    for key, value of EventEmitter
      @prototype[key] = value

    CONFIG = {
      threshold: 3,
      map: {
        title: 'title',
        type: 'type',
        uri: 'uri'
      }
    }

    constructor: (@args) ->
      @$el = $("##{@args.id}")
      @init() unless @$el.length is 0

    init: ->
      if @args.responseMap
        @responseMap = @args.responseMap
      else
        @responseMap = CONFIG.map

      @_addEventHandlers()
      @showingList = false
      @throttled = false

    _addEventHandlers: ->
      @$el.on 'input', (e) =>
        @_searchFor e.currentTarget.value

      @$el.on 'keydown', (e) =>
        if @showingList
          @_handleKeypress e

      # @$el.on 'blur', =>
      #   if @showingList
      #     @_hideList()

      # @$el.on 'focus', =>
      #   if @showingList
      #     @_unhideList()

      @$el.parent().on 'click', (e) =>
        target = e.target
        if target.tagName == 'A'
          # only set the input element value if the link goes nowhere
          if target.getAttribute('href') == '#'
            e.preventDefault()
            @_setValue target.textContent
            if @responseMap.slug
              @_setSlug target.parentNode.getAttribute('data-slug')
            @_removeResults()

    _setValue: (text) ->
      if lp.isMobile
        @$el.value = text
      else
        @$el[0].value = text

    _setSlug: (text) ->
      document.getElementById('hotel-search-slug').value = text

    _handleKeypress: (e) ->
      if e.keyCode == 40 # down arrow
        e.preventDefault()
        @_highlightDown()
      if e.keyCode == 38 # up arrow
        e.preventDefault()
        @_highlightUp()
      if e.keyCode == 13 # enter
        if @args.listOnly
          location.href = @resultsList.childNodes[@currentHighlight].firstChild.href # aaargh!!!
        else
          e.preventDefault()
          @_selectHighlighted()
      if e.keyCode == 27
        @_removeResults()

    _highlightDown: ->
      if @currentHighlight >= 0
        @_updateHighlight @currentHighlight+1, @currentHighlight
      else
        @currentHighlight = 0
        @_updateHighlight @currentHighlight

    _highlightUp: ->
      resultsLength = @resultsList.childNodes.length

      if @currentHighlight < resultsLength
        @_updateHighlight @currentHighlight-1, @currentHighlight
      else
        @currentHighlight = resultsLength-1
        @_updateHighlight @currentHighlight

    _updateHighlight: (newActive, oldActive) ->
      results = @resultsList.childNodes

      if newActive >= results.length
        newActive = results.length-1

      if newActive < 0
        newActive = 0

      @currentHighlight = newActive
      results[oldActive].className = '' if oldActive >= 0 and oldActive != newActive
      results[newActive].className = 'autocomplete__active'

    _selectHighlighted: ->
      currentItem = @resultsList.childNodes[@currentHighlight]
      @_setValue currentItem.textContent
      if @responseMap.slug
        @_setSlug currentItem.getAttribute('data-slug')
      @_removeResults()

    # _hideList: ->
    #   body = $('body')
    #   body.removeClass 'hero-search-results-displayed'
    #   body.addClass 'hero-search-results-hidden'

    # _unhideList: ->
    #   body = $('body')
    #   body.removeClass 'hero-search-results-hidden'
    #   body.addClass 'hero-search-results-displayed'

    _slothify: (searchTerm) ->
      if searchTerm.toLowerCase() == "sloth"
        @trigger('sloth/add')
        @slothified = true
      else
        if @slothified is true
          $('#js-card-holder').trigger('sloth/remove')
          @slothified = false

    _searchFor: (searchTerm)  ->
      threshold = @args.threshold || CONFIG.threshold
      if searchTerm && searchTerm.length >= threshold
        @searchTerm = searchTerm
        @_slothify(searchTerm)
        if not @throttled
          @_doRequest @searchTerm
      else if @showingList
        @_removeResults()
        @_slothify(searchTerm)

    _doRequest: ->
      myRequest = new XMLHttpRequest()
      myRequest.addEventListener 'readystatechange', =>
        if myRequest.readyState == 4
          if myRequest.status == 200
            @_updateUI JSON.parse myRequest.responseText

      myRequest.open 'get', @_generateURI(@args.uri, @args.scope)
      myRequest.setRequestHeader 'Accept', '*/*'
      myRequest.send()
      @throttled = true
      window.setTimeout =>
        @throttled = false
      , 200

    _generateURI: (searchURI, scope) ->
      uri = "#{searchURI}#{@searchTerm}"
      uri += "?scope=#{scope}" if scope
      uri

    _removeResults: ->
      results = $('.autocomplete__results')
      @showingList = false
      results.remove() if results
      $('body').removeClass 'hero-search-results-displayed'
      @showingList = false

    _updateUI: (searchResults) ->
      if @showingList
        @_removeResults()

      @resultsList = @_createList searchResults
      @$el.after @resultsList # aka insertAfter
      @showingList = true
      @currentHighlight = undefined
      $('body').addClass 'hero-search-results-displayed'

    _createList: (results) ->
      resultItems = (@_createListItem item for item in results)
      resultItems = resultItems.slice(0, @args.results) if @args.results
      list = document.createElement 'UL'
      list.className = 'autocomplete__results'
      list.appendChild listItem for listItem in resultItems
      list

    _createListItem: (item) ->
      listItem = document.createElement 'LI'
      listItem.appendChild @_createAnchor(item)
      if @responseMap.slug
        listItem.setAttribute 'data-slug', item.slug
      listItem

    _createAnchor: (item) ->
      anchor = document.createElement 'A'
      anchor.href = if @responseMap.uri then item[@responseMap.uri] else '#'
      anchor.className = 'autocomplete__result'

      if @responseMap.type
        anchor.className += " autocomplete__result__type icon--#{item[@responseMap.type]}--white--before"

      if @searchTerm
        anchor.innerHTML = @_highlightText item[@responseMap.title], @searchTerm
      else
        anchor.innerHTML = item[@responseMap.title]
      anchor

    _highlightText: (text, term) ->
      regex = new RegExp term, 'ig'
      text.replace regex, "<b>$&</b>"