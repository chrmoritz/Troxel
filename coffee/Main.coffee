'use strict'
require('bootstrap/dist/css/bootstrap.css')
require('bootstrap/dist/css/bootstrap-theme.css')
require('./Main.css')
IO = require('./IO.coffee')
Base64IO = require('./Troxel.io.coffee')
JsonIO = require('./JSON.io.coffee')
QubicleIO = require('./Qubicle.io.coffee')
MagicaIO = require('./Magica.io.coffee')
ZoxelIO = require('./Zoxel.io.coffee')
Editor = require('./Editor.coffee')
TroveCreationsLint = require('./TroveCreationsLint.coffee')
THREE = require('three')
JSZip = require('jszip')
Bloodhound = require('typeahead')
$ = require('bootstrap')
Promise = require('bluebird')
Promise.config({longStackTraces: true, warnings: true})

io = null
dragFiles = null
editor = null
bpDB = {version: [1, 0]}
anchorBP = null
$.getJSON("https://troxel.js.org/trove-blueprints/index.json")
  .done (data) ->
    if data.version[0] == bpDB.version[0] and data.version[1] == bpDB.version[1]
      v = parseInt(window.localStorage.getItem('_BpDB_latestVersion') || 0)
      f = parseInt(window.localStorage.getItem('_BpDB_formatMajor') || bpDB.version[0])
      t = window.localStorage.getItem('_BpDB_latestTag')
      unless f == bpDB.version[0] # A major format upgrade of the BpDB is needed
        alert("The Trove Blueprints Datebase is outdated and must be recreated using and updated format.).
               Troxel will now clean all remaining artifacts up, reload the page and recreate a basic Trove Blueprints Datebase (only latest tag)!")
        deleteAndRecreateDB()
      bpDB.installRequest = JSON.parse(window.localStorage.getItem('_BpDB_installRequest') || '[]')
      bpDB.removeRequest = JSON.parse(window.localStorage.getItem('_BpDB_removeRequest') || '[]')
      bpDB.installLatestTag = data.latest unless v > 0 and t? and t == data.latest
      # first visit or no successfull import yet or new tag available or install request or remove request
      v++ if v == 0 or !t? or t != data.latest or bpDB.installRequest.length > 0 or bpDB.removeRequest.length > 0
    else
      alert("Warning: You are using an outdated version of Troxel which is no longer compatible with the newest Trove Blueprints Datebase format.
            You have to update Troxel to the latest version to continue getting updates for the Trove Blueprints Datebase!")
      v = parseInt(window.localStorage.getItem('_BpDB_latestVersion') || 1)
    prepareBpDB(window.indexedDB.open('Trove-Blueprints', parseInt(v)), v) # parseInt because of IE oddness
  .fail ->
    v = parseInt(window.localStorage.getItem('_BpDB_latestVersion') || 1)
    prepareBpDB(window.indexedDB.open('Trove-Blueprints', parseInt(v)), v)
prepareBpDB = (request, v) ->
  request.onerror = (e) ->
    console.warn(e.target.error)
    switch e.target.error.name
      when "VersionError"
        alert("The Trove Blueprints Datebase is corrupted (maybe your browser has run out of profile disk space or you deleted part of it manually).
               Troxel will now clean all remaining artifacts up, reload the page and recreate a basic Trove Blueprints Datebase (only latest tag)!")
        deleteAndRecreateDB()
      when "QuotaExceededError" then alert("The Trove Blueprints Datebase run out of disk space.
                                            Try to allow Troxel to use more disk space or remove older Blueprint Databases and reload the page to use it again!")
      when "UnknownError" then alert("The Trove Blueprints Datebase couldn't be loaded because of an error with your Browser or hard disk.
                                      Try to fix all issues with your Browser profile to use it again!")
  request.onblocked = (e) ->
    alert("The Trove Blueprints Datebase needs to be updated. Please close (or reload) all other opened tabs with Troxel or any other subproject hostet on troxel.js.org!")
  request.onupgradeneeded = (e) ->
    bpDB.doingUpgrade = true
    window.localStorage.setItem('_BpDB_latestVersion', v) # ToDo: test blocking upgrade scenario
    # ToDo: implement bpDB.installRequest and bpDB.removeRequest
    # ToDo: Check if bpDB.installRequest or bpDB.installLatestTag already exist and bpDB.removeRequest doesn not exist
    db = e.target.result
    db.createObjectStore(bpDB.installLatestTag, {autoIncrement: false}) # out-of-line keys
    $.getJSON("https://troxel.js.org/trove-blueprints/#{bpDB.installLatestTag}.json").done (bps) ->
      transaction = db.transaction(bpDB.installLatestTag, "readwrite")
      objectStore = transaction.objectStore(bpDB.installLatestTag)
      bar = $('#UpdateProgress').show().children().width('0%')
      keys = Object.keys(bps)
      len = keys.length
      i = 0
      addNext = ->
        for j in [0..Math.min(100 - 2, len - i - 2)] by 1
          objectStore.add(bps[keys[i + j]], keys[i + j])
        unless i + j >= len
          objectStore.add(bps[keys[i + j]], keys[i + j]).onsuccess = addNext
          i += 100
          bar.width("#{i * 100 / len}%")
        else
          bar.width("100%")
      addNext()
      transaction.oncomplete = (e) ->
        $('#UpdateProgress').fadeOut()
        bpDB.latestTag = bpDB.installLatestTag # ToDo: Set bpDB.latestTag if only install/remove request (read from localStroage or calcualte from DB?)
        window.localStorage.setItem('_BpDB_formatMajor', bpDB.version[0])
        window.localStorage.setItem('_BpDB_latestTag', bpDB.latestTag)
        # ToDo: unset _BpDB_installRequest and _BpDB_removeRequest in localStorage
        delete bpDB.installRequest if bpDB.installRequest?
        delete bpDB.installRequest
        delete bpDB.removeRequest
        useBpDB(db)
      transaction.onerror = (e) ->
        console.warn(e.target.error)
        switch e.target.error.name
          when "QuotaExceededError" then alert("The Trove Blueprints Datebase run out of disk space.
                                                Try to allow Troxel to use more disk space or remove older Blueprint Databases and reload the page to use it again!")
          when "UnknownError" then alert("The Trove Blueprints Datebase couldn't be loaded because of an error with your Browser or hard disk.
                                          Try to fix all issues with your Browser profile to use it again!")
  request.onsuccess = (e) ->
    return if bpDB.doingUpgrade?
    window.localStorage.setItem('_BpDB_latestVersion', v)
    db = e.target.result
    bpDB.latestTag = window.localStorage.getItem('_BpDB_latestTag')
    unless bpDB.latestTag? # try to recover latestTag if offline or incompatible format
      for objs in db.objectStoreNames
        bpDB.latestTag = objs if not bpDB.latestTag? or objs > bpDB.latestTag
      window.localStorage.setItem('_BpDB_latestTag', bpDB.latestTag) if bpDB.latestTag?
    if bpDB.latestTag?
      useBpDB(db)
    else
      alert("The local Trove Blueprints Datebase does not exist and all Trove Blueprint related features won't be available.
             Try going online and or updating Troxel to fix this and be able use all Trove Blueprint related features again!")
deleteAndRecreateDB = ->
  DBDeleteRequest = window.indexedDB.deleteDatabase('Trove-Blueprints')
  DBDeleteRequest.onerror = ->
    alert("Error: An error occurred while cleaning up all remaining artifacts of the Trove Blueprints Datebase.
          Please try to delete all offline data used by troxel.js.org in your brower settings manually and reload the page!")
  DBDeleteRequest.onsuccess = ->
    window.localStorage.removeItem('_BpDB_latestVersion')
    window.localStorage.removeItem('_BpDB_formatMajor')
    window.localStorage.removeItem('_BpDB_latestTag')
    window.localStorage.removeItem('_BpDB_installRequest')
    window.localStorage.removeItem('_BpDB_removeRequest')
    location.reload()
useBpDB = (db) ->
  db.onversionchange = (e) ->
    db.close()
    alert("The Trove Blueprints Datebase was updated in another browser tab. This page will be reloaded now!")
    location.reload()
  db.onerror = (e) -> console.warn(e.target.error)
  bpDB.db = db
  if anchorBP?
    openBp(anchorBP)
openBp = (b) ->
  return unless bpDB.db?
  transaction = bpDB.db.transaction(bpDB.latestTag, "readonly")
  objectStore = transaction.objectStore(bpDB.latestTag)
  request = objectStore.get(b.toLowerCase())
  request.onerror = (e) ->
    console.warn(e.target.error)
    $('#WebGlContainer').empty()
    editor = null
  request.onsuccess = (e) ->
    if e.target.result? # if undefined -> not found
      io = new Base64IO e.target.result
      $('#btnExport').hide()
      $('#btnExportPng').show()
      if editor?
        editor.reload io.voxels, io.x, io.y, io.z, true, false
      else
        editor = new Editor io
      replaceStateOfHistory({voxels: io.voxels, x: io.x, y: io.y, z: io.z, readonly: true}, '#b=' + value.toLowerCase())
    else
      $('#WebGlContainer').empty()
      editor = null

window.onpopstate = (e) ->
  if e?.state?
    reload = io?
    resize = io.x != e.state.x or io.y != e.state.y or io.z != e.state.z
    io = new IO e.state
    if !io.readonly? or io.readonly == 0
      $('#btnExport').show()
    else
      $('#btnExport').hide()
    $('#btnExportPng').show()
    if reload
      return editor.reload io.voxels, io.x, io.y, io.z, resize, false
    else
      return editor = new Editor io
  io = null
  for hash in decodeURI(window.location.hash).replace('#', '').split('&')
    [param, value] = hash.split('=')
    if param == 'm' # load from base64 data
      io = new Base64IO value
      $('#btnExport').hide() if io.readonly == 1
      $('#btnExport').show() if io.readonly == 0
      $('#btnExportPng').show()
      if editor?
        editor.reload io.voxels, io.x, io.y, io.z, true, false
      else
        editor = new Editor io
      break
    if param == 'b' # load Trove model from blueprint id
      if bpDB.db?
        return openBp(value)
      else
        return anchorBP = value
  unless io?
    # ToDo: improve this
    $('#WebGlContainer').empty()
    editor = null
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
pushStateToHistory = (io, link) ->
  try
    history.pushState io, 'Troxel', link
  catch # reached the quota limit of the state object (640k on firefox)
    history.pushState null, 'Troxel', link
replaceStateOfHistory = (io, link) ->
  try # Try to add a state object to the current history state (if below limit)
    history.replaceState io, 'Troxel', link
$('#open').click ->
  cb = (mio) ->
    if mio.APpos? and $('#ImportRestorAP').prop('checked')
      APpos = mio.APpos
      mio.voxels[APpos[2]] = [] unless mio.voxels[APpos[2]]?
      mio.voxels[APpos[2]][APpos[1]] = [] unless mio.voxels[APpos[2]][APpos[1]]?
      if mio.voxels[APpos[2]][APpos[1]][APpos[0]]?
        unless mio.voxels[APpos[2]][APpos[1]][APpos[0]].t == 7
          console.warn 'Skip importing AP because already existing voxel at some postion. Model most likely not exported from Trove.'
      else
        mio.voxels[APpos[2]][APpos[1]][APpos[0]] = {r: 255, g: 0, b: 255, a: 250, t: 7, s: 7}
    if io? and $('#ImportMerge').prop('checked')
      offsets = {x: parseInt($('#QbMergeOffX').val()), y: parseInt($('#QbMergeOffY').val()), z: parseInt($('#QbMergeOffZ').val())}
      io.merge mio, offsets, $('#ImportAPrelativeOffsets').prop('checked')
    else
      io = mio
    $('#openModal').modal 'hide'
    $('#modeView').click() if $('#modeEdit').parent().hasClass('active')
    if !io.readonly? or io.readonly == 0
      $('#btnExport').show()
    else
      $('#btnExport').hide()
    $('#btnExportPng').show()
    if editor?
      editor.reload io.voxels, io.x, io.y, io.z, true, false
    else
      editor = new Editor io
    ioo = {voxels: io.voxels, x: io.x, y: io.y, z: io.z}
    base64 = new Base64IO(ioo).export false
    pushStateToHistory(ioo, '#m=' + base64)
  console.log '##################################################'
  switch $('#filetabs li.active a').attr('href')
    when '#tabdrag'
      if dragFiles[0].name.split('.').pop() == 'zox'
        fr = new FileReader()
        fr.onloadend = (e) -> cb(new ZoxelIO(e.target.result))
        console.log("reading file with name: #{dragFiles[0].name}")
        fr.readAsText dragFiles[0]
      else if dragFiles[0].name.split('.').pop() == 'vox'
        fr = new FileReader()
        fr.onloadend = (e) -> cb(new MagicaIO(e.target.result))
        console.log("reading file with name: #{dragFiles[0].name}")
        fr.readAsArrayBuffer dragFiles[0]
      else if dragFiles[0].name.split('.').pop() == 'qb'
        files = new Array(4)
        for f, i in dragFiles
          switch f.name.substr(-5)
            when '_a.qb' then files[1] = f unless files[1]?
            when '_t.qb' then files[2] = f unless files[2]?
            when '_s.qb' then files[3] = f unless files[3]?
            else files[0] = f if !files[0]? and f.name.substr(-3) == '.qb'
        if files[0]?
          Promise.map(files, (qb) ->
            return null unless qb?
            return new Promise (resolve, reject) ->
              fr = new FileReader()
              fr.onloadend = (e) -> resolve(e.target.result)
              fr.onerror = (e) -> reject(e.target.error)
              console.log("reading file with name: #{qb.name}")
              fr.readAsArrayBuffer qb
          ).then((abs) -> cb(new QubicleIO(abs)))
        else
          alert "Can't find Qubicle main mesh file!"
      else
        alert "Can't import selected file format."
    when '#tabqb'
      f = $('#fqb').prop('files')[0]
      if f and f.name.split('.').pop() == 'qb'
        Promise.map([f, $('#fqba').prop('files')[0], $('#fqbt').prop('files')[0], $('#fqbs').prop('files')[0]], (qb) ->
          return null unless qb?
          return new Promise (resolve, reject) ->
            fr = new FileReader()
            fr.onloadend = (e) -> resolve(e.target.result)
            fr.onerror = (e) -> reject(e.target.error)
            console.log("reading file with name: #{qb.name}")
            fr.readAsArrayBuffer qb
        ).then((abs) -> cb(new QubicleIO(abs)))
      else
        alert 'Please choose at least a valid main mesh Qubicle (.qb) file above!'
    when '#tabvox'
      f = $('#fvox').prop('files')[0]
      if f and f.name.split('.').pop() == 'vox'
        fr = new FileReader()
        fr.onloadend = (e) -> cb(new MagicaIO(e.target.result))
        console.log("reading file with name: #{f.name}")
        fr.readAsArrayBuffer f
      else
        alert 'Please choose a valid Magica Voxel (.vox) file above!'
    when '#tabzox'
      f = $('#fzox').prop('files')[0]
      if f and f.name.split('.').pop() == 'zox'
        fr = new FileReader()
        fr.onloadend = (e) -> cb(new ZoxelIO(e.target.result))
        console.log("reading file with name: #{f.name}")
        fr.readAsText f
      else
        alert 'Please choose a valid Zoxel (.zox) file above!'
    when '#tabjson'
      cb(new JsonIO $('#sjson').val())
    when '#tabtrove'
      return unless bpDB.db?
      tag = $('#cbbtag').val()
      tag = bpDB.latestTag if tag == 'latest'
      transaction = bpDB.db.transaction(tag, "readonly")
      objectStore = transaction.objectStore(tag)
      request = objectStore.get($('#sbtrove').val().toLowerCase())
      request.onerror = (e) -> console.warn(e.target.error)
      request.onsuccess = (e) ->
        model = e.target.result
        return unless model?
        if io? and $('#ImportMerge').prop('checked')
          offsets = {x: parseInt($('#QbMergeOffX').val()), y: parseInt($('#QbMergeOffY').val()), z: parseInt($('#QbMergeOffZ').val())}
          io.merge new Base64IO(model), offsets, $('#ImportAPrelativeOffsets').prop('checked')
          link = '#m=' + new Base64IO(io).export true, 2
        else
          io = new Base64IO model
          link = '#b=' + $('#sbtrove').val().toLowerCase()
        $('#openModal').modal 'hide'
        $('#modeView').click() if $('#modeEdit').parent().hasClass('active')
        $('#btnExport').hide()
        $('#btnExportPng').show()
        if editor?
          editor.reload io.voxels, io.x, io.y, io.z, true, false
        else
          editor = new Editor io
        pushStateToHistory({voxels: io.voxels, x: io.x, y: io.y, z: io.z, readonly: true}, link)
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
          voxels[az][ay][ax] = {r: 255, g: 0, b: 255, a: 250, t: 7, s: 7}
      cb(new IO x: x, y: y, z: z, voxels: voxels)
      $('#modeEdit').click()
  return
$('#openTroveTab').click ->
  return unless bpDB.db?
  unless $('#cbbtag').data('troxel-filled')
    for objs in bpDB.db.objectStoreNames
      $('#cbbtag').append("<option value=\"#{objs}\">#{objs} (#{new Date(objs).toLocaleDateString()})</option>")
    $('#cbbtag').data('troxel-filled', true)
    $('#cbbtag').change()
$('#cbbtag').change ->
  tag = $('#cbbtag').val()
  tag = bpDB.latestTag if tag == 'latest'
  $('#sbtrove').typeahead('destroy')
  $('#sbtrove').typeahead {highlight: false, minLength: 2, hint: true}, {
    name: 'troveBlueprints'
    async: true
    limit: 1000
    source: (q, scb, cb) ->
      transaction = bpDB.db.transaction(tag, "readonly")
      objectStore = transaction.objectStore(tag)
      q = q.toLowerCase()
      if objectStore.openKeyCursor? # Chrome, Firefox
        request = objectStore.openKeyCursor(window.IDBKeyRange.bound(q, q + '\uffff'))
      else # IE, Edge (less performant than keyCursor but not supported on IE, Edge)
        request = objectStore.openCursor(window.IDBKeyRange.bound(q, q + '\uffff'))
      result = []
      request.onerror = (e) -> (console.warn(e.target.error); cb(result))
      request.onsuccess = (e) ->
        cursor = e.target.result
        if cursor?
          result.push(cursor.key)
          cursor.continue()
        else
          cb(result)
    displayKey: (s) -> s
  }
$('.snewApPos').prop('disabled', true)
$('#cbnewAp').prop('checked', false).change -> $('.snewApPos').prop('disabled', !$(@).prop('checked'))
blobURLs = []
$('#exportModal').on 'hide.bs.modal', ->
  $('#exportQb').text('Export as Qubicle (*.qb, main map) ...').removeAttr('href')
  $('#exportQba').text('Export as alpha material map (*_a.qb) ...').removeAttr('href')
  $('#exportQbt').text('Export as type material map (*_t.qb) ...').removeAttr('href')
  $('#exportQbs').text('Export as specular material map (*_s.qb) ...').removeAttr('href')
  $('#exportQbzip').text('Export as material map archive (.zip: 4x .qb) ...').removeAttr('href')
  $('#exportZox').text('Export as Zoxel (.zox) ...').removeAttr('href')
  $('#exportVox').text('Export as Magica Voxel (.vox) ...').removeAttr('href')
  $('#exportBase64Ta').hide()
  $('#exportJsonTa').hide()
  URL.revokeObjectURL(bURL) for bURL in blobURLs
  blobURLs = []
$('#exportQbzip').click ->
  return if io.readonly
  unless $(@).attr('href')?
    [qb, qba, qbt, qbs] = new QubicleIO(io).export($('#exportQbComp').prop('checked'))
    filename = $('#exportFilenameQb').val() || 'Model'
    zip = new JSZip()
    zip.file("#{filename}.qb", qb)
    zip.file("#{filename}_a.qb", qba)
    zip.file("#{filename}_t.qb", qbt)
    zip.file("#{filename}_s.qb", qbs)
    comp = if $('#exportQbZipComp').prop('checked') then 'DEFLATE' else 'STORE'
    href = URL.createObjectURL(zip.generate({type:"blob", compression: comp}), {type: 'application/zip'})
    blobURLs.push(href)
    $('#exportQbzip').text('Download material map archive (.zip: 4x .qb)').attr('download', "#{filename}.zip").attr('href', href)
$('.exportQb').click ->
  return if io.readonly
  unless $(@).attr('href')?
    qbmaps = new QubicleIO(io).export($('#exportQbComp').prop('checked'))
    [href, hrefa, hreft, hrefs] = qbmaps.map (m) -> URL.createObjectURL(new Blob([m], {type: 'application/octet-binary'}))
    blobURLs.push(href, hrefa, hreft, hrefs)
    filename = $('#exportFilenameQb').val() || 'Model'
    $('#exportQb').text('Download main map (.qb)').attr('download', "#{filename}.qb").attr('href', href)
    $('#exportQba').text('Download alpha material map (*_a.qb)').attr('download', "#{filename}_a.qb").attr('href', hrefa)
    $('#exportQbt').text('Download type material map (*_t.qb)').attr('download', "#{filename}_t.qb").attr('href', hreft)
    $('#exportQbs').text('Download specular material map (*_s.qb)').attr('download', "#{filename}_s.qb").attr('href', hrefs)
$('#exportZox').click ->
  return if io.readonly
  filename = $('#exportFilenameZox').val() || 'Model'
  href = 'data:application/octet-binary;base64,' + btoa(new ZoxelIO(io).export())
  $(@).text('Download as Zoxel (.zox)').attr('download', "#{filename}.zox").attr 'href', href unless $(@).attr('href')?
$('#exportVox').click ->
  return if io.readonly
  filename = $('#exportFilenameVox').val() || 'Model'
  href = URL.createObjectURL(new Blob([new MagicaIO(io).export()], {type: 'application/octet-binary'}))
  blobURLs.push(href)
  $(@).text('Download as Magica Voxel (.vox)').attr('download', "#{filename}.vox").attr 'href', href unless $(@).attr('href')?
$('#exportBase64').click ->
  return if io.readonly
  if $('#exportBase64Rbb').prop('checked')
    [x, y, z, ox, oy, oz] = io.computeBoundingBox()
    io.resize x, y, z, ox, oy, oz
  l = window.location.toString().split('#')[0] + '#m=' + new Base64IO(io).export($('#exportBase64Ro').prop('checked'), if $('#exportBase64V2').prop('checked') then 2 else 1)
  $('#exportBase64Ta').val(l).fadeIn()
  if $('#exportBase64Tsl').prop('checked')
    $.post('https://www.trovesaurus.com/shorturl.php', {TroxelData: l}).done (url) -> $('#exportBase64Ta').val(url)
$('#exportJson').click ->
  return if io.readonly
  $('#exportJsonTa').val(new JsonIO(io).export($('#exportJsonPret').prop('checked'))).fadeIn()
$('#btnExportPng').click -> editor.render(true)
$('#ulSavedModels').parent().on 'show.bs.dropdown', (e) ->
  if $(e.relatedTarget).data('tag') == '#ulSavedModels'
    if !io? or io.readonly == 1
      $(@).find('#SavedModelsAdd').prop('disabled', true).parent().addClass('disabled')
    else
      $(@).find('#SavedModelsAdd').prop('disabled', false).parent().removeClass('disabled')
    $('#ulSavedModels li:gt(6)').remove()
    for i in [0...window.localStorage.length] by 1
      key = window.localStorage.key i
      if key.indexOf('saved_models_') == 0
        $('#ulSavedModels').append "<li><a class='openSavedModel' data-model='#{window.localStorage.getItem(key)}'>#{key.substring(13)}</a></li>"
    $('#ulSavedModels').append '<li class="disabled"><a>No saved models</a></li>' if $('.openSavedModel').length == 0
  $('.openSavedModel').click ->
    io = new Base64IO $(@).data 'model'
    $('#btnExport').show() if !io.readonly? or io.readonly == 0
    $('#btnExportPng').show()
    pushStateToHistory({voxels: @voxels, x: @x, y: @y, z: @z}, '#m=' + $(@).data 'model')
    if editor?
      editor.reload io.voxels, io.x, io.y, io.z, true, false
    else
      editor = new Editor io
    $('#ulSavedModels li:eq(1) a').text $(@).text()
$('#saveModelAs').click ->
  return if $('#saveModelName').val().length == 0 or !io? or io.readonly
  window.localStorage.setItem 'saved_models_' + $('#saveModelName').val(), new Base64IO(io).export io.readonly
  $('#saveModal').modal 'hide'
$('#modeView').click ->
  return if !io? or $(@).parent().hasClass('active')
  $(@).parent().addClass('active')
  $('#modeEdit').parent().removeClass('active')
  editor.changeEditMode(false)
  $('#addPanel').fadeOut()
  ga 'send', 'pageview', '/' if ga?
$('#modeEdit').click ->
  return if !io? or io.readonly or $(@).parent().hasClass('active')
  $(@).parent().addClass('active')
  $('#modeView').parent().removeClass('active')
  editor.changeEditMode(true)
  $('#addPanel').fadeIn()
  ga 'send', 'pageview', '/edit' if ga?
$('.rotateBtn').click ->
  return unless io?
  switch $(@).data('rotate')
    when  'x' then io.rotateX(true)
    when '-x' then io.rotateX(false)
    when  'y' then io.rotateY(true)
    when '-y' then io.rotateY(false)
    when  'z' then io.rotateZ(true)
    when '-z' then io.rotateZ(false)
  editor.reload io.voxels, io.x, io.y, io.z, true, false
  ioo = {voxels: io.voxels, x: io.x, y: io.y, z: io.z, readonly: io.readonly}
  base64 = new Base64IO(ioo).export false
  pushStateToHistory(ioo, '#m=' + base64)
$('.moveBtn').click ->
  return unless io?
  switch $(@).data('move')
    when  'x' then io.moveX(true, true)
    when '-x' then io.moveX(false, true)
    when  'y' then io.moveY(true, true)
    when '-y' then io.moveY(false, true)
    when  'z' then io.moveZ(true, true)
    when '-z' then io.moveZ(false, true)
  editor.reload io.voxels, io.x, io.y, io.z, false, false
  ioo = {voxels: io.voxels, x: io.x, y: io.y, z: io.z, readonly: io.readonly}
  base64 = new Base64IO(ioo).export false
  pushStateToHistory(ioo, '#m=' + base64)
$('.mirrorBtn').click ->
  return unless io?
  switch $(@).data('mirror')
    when 'x' then io.mirrorX(true)
    when 'y' then io.mirrorY(true)
    when 'z' then io.mirrorZ(true)
  editor.reload io.voxels, io.x, io.y, io.z, false, false
  ioo = {voxels: io.voxels, x: io.x, y: io.y, z: io.z, readonly: io.readonly}
  base64 = new Base64IO(ioo).export false
  pushStateToHistory(ioo, '#m=' + base64)
$('.panel-heading').click ->
  span = $(@).find('button span')
  if span.hasClass('glyphicon-minus')
    span.removeClass('glyphicon-minus').addClass('glyphicon-plus')
  else
    span.removeClass('glyphicon-plus').addClass('glyphicon-minus')
  $(@).next().toggle()
$('#backgroundColor').val('#888888').change ->
  return unless editor?
  editor.renderer.setClearColor new THREE.Color($(@).val()).getHex()
  editor.controls.needsRender = true
  $('body').css 'background-color', $(@).val()
$('#ambLightColor').val('#606060').change ->
  return unless editor?
  editor.ambientLight.color = new THREE.Color($(@).val())
  editor.controls.needsRender = true
$('#dirLightColor').val('#ffffff').change ->
  return unless editor?
  editor.directionalLight.color = new THREE.Color($(@).val())
  editor.controls.needsRender = true
$('#dirLightIntensity').val(0.3).change ->
  return unless editor?
  editor.directionalLight.intensity = parseFloat $(@).val()
  editor.controls.needsRender = true
$('#pointLightColor').val('#ffffff').change ->
  return unless editor?
  editor.pointLight.color = new THREE.Color($(@).val())
  editor.controls.needsRender = true
$('#pointLightIntensity').val(0.7).change ->
  return unless editor?
  editor.pointLight.intensity = parseFloat $(@).val()
  editor.controls.needsRender = true
$('#dirLightX').val('-0.5')
$('#dirLightY').val('-0.5')
$('#dirLightZ').val('1')
$('#dirLightVector').click ->
  return unless editor?
  editor.directionalLight.position.set(parseFloat($('#dirLightX').val()), parseFloat($('#dirLightY').val()), parseFloat($('#dirLightZ').val())).normalize()
  editor.controls.needsRender = true
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
    when 1, 2, 4
      $('#addVoxAlpha').prop('disabled', false)
      $('#addVoxSpecular').prop('disabled', true)
    when 0, 3
      $('#addVoxAlpha').prop('disabled', true)
      $('#addVoxSpecular').prop('disabled', false)
$('#addVoxAlpha').val(112)
$('#editVoxNoiseBright').val(0)
$('#editVoxNoiseHSL').val(0)
$('#resizeModal').on 'show.bs.modal', (e) ->
  e.relatedTarget.preventDefault() unless editor?
$('#openResizeModal').click ->
  return unless editor?
  $('#resizeX').val(io.x)
  $('#resizeY').val(io.y)
  $('#resizeZ').val(io.z)
  $('#resizeOffX').val(0)
  $('#resizeOffY').val(0)
  $('#resizeOffZ').val(0)
$('#resizeBtn').click ->
  return unless editor?
  $('#resizeModal').modal 'hide'
  io.resize(parseInt($('#resizeX').val()), parseInt($('#resizeY').val()), parseInt($('#resizeZ').val()),
    parseInt($('#resizeOffX').val()), parseInt($('#resizeOffY').val()), parseInt($('#resizeOffZ').val()))
  editor.reload io.voxels, io.x, io.y, io.z, true, false
  ioo = {voxels: io.voxels, x: io.x, y: io.y, z: io.z, readonly: io.readonly}
  base64 = new Base64IO(ioo).export false
  pushStateToHistory(ioo, '#m=' + base64)
$('#resizeCalcBBb').click ->
  return unless editor?
  [x, y, z, ox, oy, oz] = io.computeBoundingBox()
  $('#resizeX').val(x)
  $('#resizeY').val(y)
  $('#resizeZ').val(z)
  $('#resizeOffX').val(ox)
  $('#resizeOffY').val(oy)
  $('#resizeOffZ').val(oz)
$($('.editTool')[0]).parent().button('toggle')
$('#fillSameColor').prop('checked', true)
$('.editTool').change ->
  switch $(@).data('edittool')
    when 1 then $('#fillSameColorDiv').show()
    else $('#fillSameColorDiv').hide()
$('[data-toggle="tooltip"]').tooltip()
$('#rendererPostEffect').val(1).change ->
  editor = new Editor io if editor?
$('#renderMode').change ->
  return unless editor?
  editor.renderMode = parseInt $(@).val()
  editor.reload io.voxels, io.x, io.y, io.z, false, false
$('#renderWireframes').change ->
  return unless editor?
  editor.renderWireframes = parseInt $(@).val()
  editor.reload io.voxels, io.x, io.y, io.z, false, false
$('#renderControls').change ->
  editor.controls.mode = $(@).val() == "0" if editor?
$('#ImportMerge').prop('checked', false).change -> $('.QbMergeOff').prop('disabled', !$(@).prop('checked'))
$('#renderAutoRotateSpeed').val(0).change ->
  return unless editor?
  ars = parseInt $(@).val()
  if ars == 0
    editor.controls.autoRotate = false
  else
    editor.controls.autoRotate = true
    editor.controls.autoRotateSpeed = ars
$('#TroveCreationsLint').click ->
  return unless editor?
  $('#TroveCreationsExportLink').hide()
  if io.readonly
    $('#TroveCreationsExportDiv').hide()
  else
    $('#TroveCreationsExportDiv').show()
  type = $('#TroveCreationsType').val()
  tcl = new TroveCreationsLint io, type
  editor.renderWireframes = 6
  $('#renderWireframes').val('6')
  editor.reload io.voxels, io.x, io.y, io.z, true, false
  ioo = {voxels: io.voxels, x: io.x, y: io.y, z: io.z, readonly: io.readonly}
  base64 = new Base64IO(ioo).export false
  pushStateToHistory(ioo, '#m=' + base64)
  $('#TroveCreationsLintingResults').empty()
  for e in tcl.errors
    footer = if e.footer? then "<hr style=\"margin-top: 5px; margin-bottom: 5px;\"><p><b>Hot to fix it?: </b><i>#{e.footer}</i></p>" else ''
    $('#TroveCreationsLintingResults').append("<div class=\"alert alert-danger\"><h4>#{e.title}</h4>#{e.body}#{footer}</div>")
  if io.warn?.length > 0
    $('#TroveCreationsLintingResults').append("<div class=\"alert alert-warning\"><h4>Troxel had to fix issues in your material maps for you!</h4>
                There were issues in your material maps like invalid color values in the type / alpha / specular map or having a voxel in one map
                but not in another. These were fixed automatically on import by Troxel for you. It\'s recommended that you either fix these isues
                by yourself in your source .qb files or use the .qb files exported by Troxel for creating your .blueprint for submission.
                <textarea class=\"form-control\" style=\"resize: none\">#{io.warn.join('\n')}</textarea></div>")
  for w in tcl.warnings
    footer = if w.footer? then "<hr style=\"margin-top: 5px; margin-bottom: 5px;\"><p><b>Hot to fix it?: </b><i>#{w.footer}</i></p>" else ''
    $('#TroveCreationsLintingResults').append("<div class=\"alert alert-warning\"><h4>#{w.title}</h4>#{w.body}#{footer}</div>")
  for i in tcl.infos
    $('#TroveCreationsLintingResults').append("<div class=\"alert alert-info\"><h4>#{i.title}</h4>#{i.body}</div>")
  if tcl.warnings.length == tcl.errors.length == 0
    $('#TroveCreationsLintingResults').append("<div class=\"alert alert-success\"><h4>All test passed!</h4>There is nothing to complain about your
                                               model. Thats great, go submitting it!</div>")
  else
    warnC = tcl.warnings.length + if io.warn?.length > 0 then 1 else 0
    $('#TroveCreationsLintingCount').text("Warning: You have #{tcl.errors.length} errors and #{warnC} warnings for your voxel model.
                                           Please try to fix them for submitting it to the Trove Creation Reddit!")
  text = switch type
    when 'melee' then 'melee weapon creation check out the
      <a href="http://trove.wikia.com/wiki/Melee_weapon_creation" class="alert-link" target="_blank">melee weapon creation guide</a>'
    when 'gun' then 'gun creation check out the
      <a href="http://trove.wikia.com/wiki/Gun_Weapon_Creation" class="alert-link" target="_blank">gun creation guide</a>'
    when 'staff' then 'staff creation check out the
      <a href="http://trove.wikia.com/wiki/Staff_Creation_Guide" class="alert-link" target="_blank">staff creation guide</a>'
    when 'bow' then 'bow creation check out the
      <a href="http://trove.wikia.com/wiki/Bow_Creation_Guide" class="alert-link" target="_blank">bow creation guide</a>'
    when 'spear' then 'spear creation check out the
      <a href="http://trove.wikia.com/wiki/Spear_Creation_Guide" class="alert-link" target="_blank">spear creation guide</a>'
    when 'mask' then 'mask creation check out the
      <a href="http://trove.wikia.com/wiki/Mask_creation" class="alert-link" target="_blank">mask creation guide</a>'
    when 'hat' then 'hat creation check out the
      <a href="http://trove.wikia.com/wiki/Hat_creation" class="alert-link" target="_blank">hat creation guide</a>'
    when 'hair' then 'hair creation check out the
      <a href="http://trove.wikia.com/wiki/Hair_creation" class="alert-link" target="_blank">hair creation guide</a>'
    when 'deco' then 'decoration creation check out the
      <a href="http://trove.wikia.com/wiki/Cornerstone_decoration_creation" class="alert-link" target="_blank">decoration creation guide</a>'
    when 'lair', 'dungeon' then 'lair and dungeon creation check out the
      <a href="http://trove.wikia.com/wiki/Lair_and_Dungeon_creation" class="alert-link" target="_blank">lair and dungeon creation guide</a>'
    else 'Trove creations check out the <a href="http://trove.wikia.com/wiki/Guides" class="alert-link" target="_blank">trove creations guides</a>'
  $('#TroveCreationsLintingResults').prepend("<div class=\"alert alert-info\">For more information about #{text}. Also check out the
     <a href=\"http://trove.wikia.com/wiki/Material_Map_Guide\" class=\"alert-link\" target=\"_blank\">Material Maps Guide</a>, the
     <a href=\"http://trove.wikia.com/wiki/Style_guidelines\" class=\"alert-link\" target=\"_blank\">offical Style Guidelines</a> and the
     <a href=\"http://trove.wikia.com/wiki/Mods'_Style_Guidelines\" class=\"alert-link\" target=\"_blank\"> Mods' Style Guidelines</a>!
     Note: You will also need some ingame screenshots for your item submission.</div>")
$('#TroveCreationsExport').click ->
  return if io.readonly
  l = window.location.toString().split('#')[0] + '#m=' + new Base64IO(io).export($('#TroveCreationsReadonly').prop('checked'), 2)
  $('#TroveCreationsExportLink').val("[Troxel Link](#{l})").fadeIn()
  if $('#TroveCreationsTsl').prop('checked')
    $.post('https://www.trovesaurus.com/shorturl.php', {TroxelData: l}).done (url) -> $('#TroveCreationsExportLink').val(url)
$('#TroveCreationLinterModal').on 'show.bs.modal', (e) ->
  e.relatedTarget.preventDefault() unless editor?
