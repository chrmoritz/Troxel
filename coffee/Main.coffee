'use strict'
io = null
dragFiles = null
renderer = null
if window.applicationCache.status != window.applicationCache.UNCACHED
  window.applicationCache.addEventListener 'updateready', ->
    if window.applicationCache.status == window.applicationCache.UPDATEREADY
      $.ajax({url: 'static/Recent_Changes.html', cache: false}).done (html) -> $('#recentChangesDiv').prepend(html)
      $('#updateModal').modal 'show'
      clearInterval updatechecker
  updatechecker = setInterval (-> window.applicationCache.update()), 300000
$('#updateLater').click ->
  updatechecker = setInterval (-> window.applicationCache.update()), parseInt($('#remindUpdateTime').val())
  $('#updateModal').modal 'hide'
window.onpopstate = (e) ->
  if e?.state?
    reload = io? and io.x == e.state.x and io.y == e.state.y and io.z == e.state.z
    io = new IO e.state
    if !io.readonly? or io.readonly == 0
      $('#btnExport').show()
    else
      $('#btnExport').hide()
    $('#btnExportPng').show()
    if reload
      return renderer.reload io
    else
      return renderer = new Renderer io
  io = null
  for hash in decodeURI(window.location.hash).replace('#','').split('&')
    [param, value] = hash.split('=')
    if param == 'm' # load from base64 data
      io = new Base64IO value
      $('#btnExport').hide() if io.readonly == 1
      $('#btnExport').show() if io.readonly == 0
      $('#btnExportPng').show()
      renderer = new Renderer io
      break
    if param == 'b' # load Trove model from blueprint id
      $.getJSON 'static/Trove.json', (data) ->
        model = data[value]
        return unless model?
        io = new Base64IO model
        $('#btnExport').hide()
        $('#btnExportPng').show()
        renderer = new Renderer io
      break
  unless io?
    $('#WebGlContainer').empty()
window.onpopstate()
$('input[type="file"]').change ->
  if $(@).prop('files').length > 1
    dragFiles = $(@).prop('files')
    $('#filetabs li:last a').tab 'show'
    $('#tabdrag ul').empty()
    $('#tabdrag ul').append $ '<li>' + f.name + '</li>' for f in dragFiles
document.addEventListener 'dragover', (e) ->
  e.stopPropagation()
  e.preventDefault()
  e.dataTransfer.dropEffect = 'copy'
document.addEventListener 'drop', (e) ->
  e.stopPropagation()
  e.preventDefault()
  dragFiles = e.dataTransfer.files
  if dragFiles.length > 0
    $('#openModal').modal 'show'
    $('#dragTab').click()
    $('#tabdrag ul').empty()
    $('#tabdrag ul').append $ '<li>' + f.name + '</li>' for f in dragFiles
$('#open').click ->
  cb = ->
    $('#openModal').modal 'hide'
    $('#modeView').click() if $('#modeEdit').parent().hasClass('active')
    if !io.readonly? or io.readonly == 0
      $('#btnExport').show()
    else
      $('#btnExport').hide()
    $('#btnExportPng').show()
    renderer = new Renderer io
    history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
  console.log '##################################################'
  switch $('#filetabs li.active a').attr('href')
    when '#tabdrag'
      if dragFiles[0].name.split('.').pop() == 'zox'
        io = new ZoxelIO dragFiles[0], cb
      else if dragFiles[0].name.split('.').pop() == 'vox'
        io = new MagicaIO dragFiles[0], cb
      else if dragFiles[0].name.split('.').pop() == 'qb'
        files = {}
        for f, i in dragFiles
          switch f.name.substr(-5)
            when '_a.qb' then files.a = f unless files.a?
            when '_t.qb' then files.t = f unless files.t?
            when '_s.qb' then files.s = f unless files.s?
            else files.m = f if f.name.substr(-3) == '.qb'
        if files.m?
          io = new QubicleIO files, cb
        else
          alert "Can't find Qubicle main mesh file!"
      else
        alert "Can't import selected file format."
    when '#tabqb'
      f = $('#fqb').prop('files')[0]
      if f and f.name.split('.').pop() == 'qb'
        io = new QubicleIO {m: f, a: f = $('#fqba').prop('files')[0], t: f = $('#fqbt').prop('files')[0], s: f = $('#fqbs').prop('files')[0]}, cb
      else
        alert 'Please choose at least a valid main mesh Qubicle (.qb) file above!'
    when '#tabvox'
      f = $('#fvox').prop('files')[0]
      if f and f.name.split('.').pop() == 'vox'
        io = new MagicaIO f, cb
      else
        alert 'Please choose a valid Magica Voxel (.vox) file above!'
    when '#tabzox'
      f = $('#fzox').prop('files')[0]
      if f and f.name.split('.').pop() == 'zox'
        io = new ZoxelIO f, cb
      else
        alert 'Please choose a valid Zoxel (.zox) file above!'
    when '#tabjson'
      io = new JsonIO $('#sjson').val()
      cb()
    when '#tabtrove'
      $.getJSON 'static/Trove.json', (data) ->
        model = data[$('#sbtrove').val()]
        return unless model?
        io = new Base64IO model
        $('#openModal').modal 'hide'
        $('#btnExport').hide()
        $('#btnExportPng').show()
        renderer = new Renderer io
        history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#b=' + $('#sbtrove').val()
    when '#tabnew'
      x = parseInt $('#snewX').val()
      y = parseInt $('#snewY').val()
      z = parseInt $('#snewZ').val()
      voxels = []
      if $('#cbnewAp').prop('checked')
        ax = parseInt $('#snewApX').val()
        ay = parseInt $('#snewApY').val()
        az = parseInt $('#snewApZ').val()
        if ax < x && ay < y and az < z
          voxels[az] = []
          voxels[az][ay] = []
          voxels[az][ay][ax] = {r: 255, g: 0, b: 255, a: 250, t: 7, s: 7} # ToDo: correct alpha value for attachment point?
      io = new IO x: x, y: y, z: z, voxels: voxels
      cb()
      $('#modeEdit').click()
  return
$('#openTroveTab').click ->
  i = 0
  blueprints = new Bloodhound({
    datumTokenizer: (bp) -> bp.value.split(/[\[,\],_]/i),
    queryTokenizer: (bp) -> bp.split(/[\s,_]/i),
    limit: 10000,
    prefetch: {
      url: 'static/Trove.json',
      cacheKey: 'TroveBlueprintCache'
      filter: (bps) -> $.map(bps, (base64, bp) ->
        return {value: bp}
      )
    }
  })
  blueprints.initialize()
  $('#sbtrove').typeahead {highlight: true, minLength: 2, hint: false}, {name: 'troveBlueprints', source: blueprints.ttAdapter()}
$('.snewApPos').prop('disabled', true)
$('#cbnewAp').prop('checked', false).change -> $('.snewApPos').prop('disabled', !$(@).prop('checked'))
$('#btnExport').click ->
  $('#exportQb').text('Export as Qubicle (.qb) ...').removeAttr('href')
  $('#exportQba').hide().removeAttr('href')
  $('#exportQbt').hide().removeAttr('href')
  $('#exportQbs').hide().removeAttr('href')
  $('#exportZox').text('Export as Zoxel (.zox) ...').removeAttr('href')
  $('#exportVox').text('Export as Magica Voxel (.vox) ...').removeAttr('href')
  $('#exportBase64Ta').hide()
  $('#exportJsonTa').hide()
$('#exportQb').click ->
  return if io.readonly
  unless $(@).attr('href')?
    [href, hrefa, hreft, hrefs] = new QubicleIO(io).export($('#exportQbComp').prop('checked'))
    filename = $('#exportFilenameQb').val() || 'Model'
    $(@).text('Download main mash (.qb)').attr('download', "#{filename}.qb").attr 'href', href
    $('#exportQba').show().attr('download', "#{filename}_a.qb").attr 'href', hrefa
    $('#exportQbt').show().attr('download', "#{filename}_t.qb").attr 'href', hreft
    $('#exportQbs').show().attr('download', "#{filename}_s.qb").attr 'href', hrefs
$('#exportZox').click ->
  return if io.readonly
  filename = $('#exportFilenameZox').val() || 'Model'
  $(@).text('Download as Zoxel (.zox)').attr('download', "#{filename}.zox").attr 'href', new ZoxelIO(io).export() unless $(@).attr('href')?
$('#exportVox').click ->
  return if io.readonly
  filename = $('#exportFilenameVox').val() || 'Model'
  $(@).text('Download as Magica Voxel (.vox)').attr('download', "#{filename}.vox").attr 'href', new MagicaIO(io).export() unless $(@).attr('href')?
$('#exportBase64').click ->
  return if io.readonly
  $('#exportBase64Ta').val(window.location.toString().split('#')[0] + '#m=' + new Base64IO(io).export($('#exportBase64Ro').prop('checked'))).fadeIn()
$('#exportJson').click ->
  return if io.readonly
  $('#exportJsonTa').val(new JsonIO(io).export($('#exportJsonPret').prop('checked'))).fadeIn()
$('#btnExportPng').click -> renderer.render(true)
$('#ulSavedModels').parent().on 'show.bs.dropdown', (e) ->
  if $(e.relatedTarget).data('tag') == '#ulSavedModels'
    if !io? or io.readonly == 1
      $(@).find('a[data-target=#saveModal]').prop('disabled', true).parent().addClass('disabled')
    else
      $(@).find('a[data-target=#saveModal]').prop('disabled', false).parent().removeClass('disabled')
    $('#ulSavedModels li:gt(6)').remove()
    for i in [0...window.localStorage.length] by 1
      key = window.localStorage.key i
      $('#ulSavedModels').append "<li><a class='openSavedModel' data-model='#{window.localStorage.getItem(key)}'>#{key}</a></li>" unless key.indexOf('__') == 0
    $('#ulSavedModels').append '<li class="disabled"><a>No saved models</a></li>' if $('.openSavedModel').length == 0
  $('.openSavedModel').click ->
    io = new Base64IO $(@).data 'model'
    $('#btnExport').show() if !io.readonly? or io.readonly == 0
    $('#btnExportPng').show()
    history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Toxel', '#m=' + $(@).data 'model'
    renderer = new Renderer io
    $('#ulSavedModels li:eq(1) a').text $(@).text()
$('#saveModelAs').click ->
  return if $('#saveModelName').val().length == 0 or !io? or io.readonly
  window.localStorage.setItem $('#saveModelName').val(), new Base64IO(io).export io.readonly
  $('#saveModal').modal 'hide'
$('#modeView').click ->
  $(@).parent().addClass('active')
  $('#modeEdit').parent().removeClass('active')
  renderer.changeEditMode(false)
  $('#addPanel').fadeOut()
$('#modeEdit').click ->
  return if !io? or io.readonly
  $(@).parent().addClass('active')
  $('#modeView').parent().removeClass('active')
  renderer.changeEditMode(true)
  $('#addPanel').fadeIn()
$('.rotateBtn').click ->
  return unless io?
  switch $(@).data('rotate')
    when  'x' then io.rotateX(true)
    when '-x' then io.rotateX(false)
    when  'y' then io.rotateY(true)
    when '-y' then io.rotateY(false)
    when  'z' then io.rotateZ(true)
    when '-z' then io.rotateZ(false)
  renderer = new Renderer io # ToDo: implement changing dimensions in renderer.reload
  history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
$('.moveBtn').click ->
  return unless io?
  switch $(@).data('move')
    when  'x' then io.moveX(true, true)
    when '-x' then io.moveX(false, true)
    when  'y' then io.moveY(true, true)
    when '-y' then io.moveY(false, true)
    when  'z' then io.moveZ(true, true)
    when '-z' then io.moveZ(false, true)
  renderer.reload io
  history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
$('.mirrorBtn').click ->
  return unless io?
  switch $(@).data('mirror')
    when 'x' then io.mirrorX(true)
    when 'y' then io.mirrorY(true)
    when 'z' then io.mirrorZ(true)
  renderer.reload io
  history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
$('.panel-heading').click ->
  span = $(@).find('button span')
  if span.hasClass('glyphicon-minus')
    span.removeClass('glyphicon-minus').addClass('glyphicon-plus')
  else
    span.removeClass('glyphicon-plus').addClass('glyphicon-minus')
  $(@).next().toggle()
$('#ambLightColor').val('#606060').change ->
  return unless io?
  renderer.ambientLight.color = new THREE.Color($(@).val())
  renderer.render()
$('#dirLightColor').val('#ffffff').change ->
  return unless io?
  renderer.directionalLight.color = new THREE.Color($(@).val())
  renderer.render()
$('#dirLightIntensity').val(0.3).change ->
  return unless io?
  renderer.directionalLight.intensity = $(@).val()
  renderer.render()
$('#spotLightColor').val('#ffffff').change ->
  return unless io?
  renderer.spotLight.color = new THREE.Color($(@).val())
  renderer.render()
$('#spotLightIntensity').val(0.7).change ->
  return unless io?
  renderer.spotLight.intensity = $(@).val()
  renderer.render()
$('#dirLightX').val('-0.5')
$('#dirLightY').val('-0.5')
$('#dirLightZ').val('1')
$('#dirLightVector').click ->
  return unless io?
  renderer.directionalLight.position.set(parseFloat($('#dirLightX').val()), parseFloat($('#dirLightY').val()), parseFloat($('#dirLightZ').val())).normalize()
  renderer.render()
$('#addVoxAP').click ->
  $('#addVoxColor').val('#ff00ff')
  $('#addVoxAlpha, #addVoxType, #addVoxSpecular').prop('disabled', true)
$('#addVoxColor').change ->
  switch $(@).val()
    when '#ff00ff' then $('#addVoxAlpha, #addVoxType, #addVoxSpecular').prop('disabled', true)
    else
      $('#addVoxAlpha, #addVoxType, #addVoxSpecular').prop('disabled', false)
      $('#addVoxType').change()
$('#addVoxType').change ->
  switch parseInt($(@).val())
    when 1, 2, 4 then $('#addVoxAlpha').prop('disabled', false)
    when 0, 3 then $('#addVoxAlpha').prop('disabled', true)
$('#addVoxAlpha').val(112)
$('#editVoxNoiseBright').val(0)
$('#editVoxNoiseHSL').val(0)
$('#openResizeModal').click ->
  return unless io?
  $('#resizeX').val(io.x)
  $('#resizeY').val(io.y)
  $('#resizeZ').val(io.z)
$('#resizeBtn').click ->
  return if not io? or io.readonly
  $('#resizeModal').modal 'hide'
  io.resize(parseInt($('#resizeX').val()), parseInt($('#resizeY').val()), parseInt($('#resizeZ').val()))
  renderer = new Renderer io # ToDo: implement changing dimensions in renderer.reload
  history.pushState {voxels: io.voxels, x: io.x, y: io.y, z: io.z}, 'Troxel', '#m=' + new Base64IO(io).export false
$($('.editTool')[0]).parent().button('toggle')
$('#fillSameColor').prop('checked', true)
$('.editTool').change ->
  switch $(@).data('edittool')
    when 1 then $('#fillSameColorDiv').show()
    else $('#fillSameColorDiv').hide()
$('[data-toggle="tooltip"]').tooltip()
