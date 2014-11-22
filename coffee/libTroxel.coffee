window.Troxel =
  renderBlueprint: (blueprintId, domElement) ->
    $.ajax dataType: 'jsonp', url: 'https://chrmoritz.github.io/Troxel/static/Trove.jsonp', jsonpCallback: 'callback', success: (data) ->
      model = data[blueprintId]
      return Troxel.renderBase64(model, domElement, blueprintId) if model?
      console.warn "blueprintId #{blueprintId} not found"
  renderBase64: (base64, domElement, blueprintId) ->
    @domElement = $(domElement).empty()
    @io = new Base64IO base64
    @renderer = new Renderer @io, true, @domElement
    info = document.createElement('div')
    info.style.position = 'absolute'
    info.style.bottom = '0px'
    info.style.width = '100%'
    info.style.textAlign = 'center'
    link = if blueprintId? then '#b=' + blueprintId else '#m=' + base64
    info.innerHTML = "<a href='http://chrmoritz.github.io/Troxel/#{link}' target='_blank' class='troxelLink'>Open this model in Troxel</a>"
    @domElement.append info
