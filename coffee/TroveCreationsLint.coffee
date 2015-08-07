'use strict'
class TroveCreationsLint
  constructor: (@io, @type) ->
    @errors = []
    @warnings = []
    [x, y, z, ox, oy, oz] = @io.computeBoundingBox()
    @io.resize x, y, z, ox, oy, oz
    @hasExactlyOneAttachmentPoint() if @type not in ['deco', 'lair', 'dungeon']
    @hasNoFloatingVoxels() if @type not in ['lair', 'dungeon']
    @usesMaterialMaps() if @type not in ['lair', 'dungeon']
    @checkForAlphaWithoutGlass() if @type not in ['lair', 'dungeon']
    switch @type
      when 'meele' then @validateMeele()
      when 'gun' then @validateGun()
      when 'staff' then @validateStaff()
      when 'bow' then @validateBow()
      when 'spear' then @validateSpear()
      when 'mask' then @validateMask()
      when 'hat' then @validateHat()
      when 'hair' then @validateHair()
      when 'deco' then @validateDeco()
      else @warnings.push {
        title: 'Linting lairs and dungeons not yet supported!'
        body: 'Linting lairs and dungeons is not yet supported. Get feedback in the Trove Creations reddit!'
      }

  hasExactlyOneAttachmentPoint: ->
    i = 0
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and @io.voxels[z][y][x].t == 7
          i++
    return @correctAttachmentPoint = true if i == 1
    @correctAttachmentPoint = false
    if i == 0
      return @errors.push {
        title: 'No attachment point found!'
        body: 'You need to specify an attachment point whereby your model will be aligned correctly ingame.'
      }
    @errors.push {
      title: 'Multiple attachment points found!'
      body: 'You have more the one attachment point in your model. Avoid the usage of excatly pink (255,0,255) voxels in your model
             except for the attachment point.'
    }

  hasNoFloatingVoxels: ->
    toCheck = @getStartingVoxel()
    @io.voxels[toCheck[0][0]][toCheck[0][1]][toCheck[0][2]].checked = true
    while toCheck.length > 0
      [z, y, x] = toCheck.pop()
      (@io.voxels[z][y][x + 1].checked = true; toCheck.push [z, y, x + 1]) if @io.voxels[z]?[y]?[x + 1]? and !@io.voxels[z][y][x + 1].checked
      (@io.voxels[z][y][x - 1].checked = true; toCheck.push [z, y, x - 1]) if @io.voxels[z]?[y]?[x - 1]? and !@io.voxels[z][y][x - 1].checked
      (@io.voxels[z][y + 1][x].checked = true; toCheck.push [z, y + 1, x]) if @io.voxels[z]?[y + 1]?[x]? and !@io.voxels[z][y + 1][x].checked
      (@io.voxels[z][y - 1][x].checked = true; toCheck.push [z, y - 1, x]) if @io.voxels[z]?[y - 1]?[x]? and !@io.voxels[z][y - 1][x].checked
      (@io.voxels[z + 1][y][x].checked = true; toCheck.push [z + 1, y, x]) if @io.voxels[z + 1]?[y]?[x]? and !@io.voxels[z + 1][y][x].checked
      (@io.voxels[z - 1][y][x].checked = true; toCheck.push [z - 1, y, x]) if @io.voxels[z - 1]?[y]?[x]? and !@io.voxels[z - 1][y][x].checked
    t = false
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]?
          if @io.voxels[z][y][x].checked
            delete @io.voxels[z][y][x].checked
          else
            t = true unless @io.voxels[z][y][x].t == 7 and @type in ['hair', 'hat', 'mask']
    if t
      @warnings.push {
        title: 'Your model has floating voxels!'
        body: 'There will be only a few exceptions where models with floating voxels will be accepted. Try to avoid them!
               You will get feedback if this is the case for you in the submission process and Trove Creations reddit.'
      }

  getStartingVoxel: ->
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]?
          return [[z, y, x]] unless @io.voxels[z][y][x].t == 7 and @type in ['hair', 'hat', 'mask']

  usesMaterialMaps: ->
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and (@io.voxels[z][y][x].t > 0 or @io.voxels[z][y][x].s > 0) and @io.voxels[z][y][x].t != 7
          return
    @warnings.push {
      title: 'Material maps not used!'
      body: 'It looks like you haven\'t used any material maps in your voxel model. Check out the
             <a href="http://trove.wikia.com/wiki/Material_Map_Guide" class="alert-link" target="_blank">Material Map Guide</a> and see what
             awesome stuff you can do using material maps. The usage of material maps will increase the chance, that your model gets accepted too.'
    }

  checkForAlphaWithoutGlass: ->
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and @io.voxels[z][y][x].a < 250 and @io.voxels[z][y][x].t not in [1, 2, 4]
          return @warnings.push {
            title: 'Usage of transparency on a solid block!'
            body: 'It looks like you tried to make voxels transparent but left their type to a solid type.
                   For transparency you have to create a type map too and set the type of the transparent voxels to a glass type. Check out the
                  <a href="http://trove.wikia.com/wiki/Material_Map_Guide" class="alert-link" target="_blank">Material Map Guide</a> for
                  more informations.'
          }

  validateMeele: ->
    if @io.x > 10 or @io.y > 10 or @io.z > 35 # oriantation and dimension
      if @io.z <= 10 and ((@io.x <= 35 and @io.y <= 10) or (@io.x <= 10 and @io.y <= 35))
        @errors.push {
          title: 'Incorrect meele weapon model oriantation!'
          body: 'You meele weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the tip of your weapon is facing the front!
                 Don\'t forget to fix this in your local files too before creating and submitting the blueprint to the devs.'
        }
      else
        @errors.push {
          title: 'Incorrect meele weapon model dimensions!'
          body: 'A meele weapon model should not exceed 10x10x35 voxels.'
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    if ay > 4 or @io.y - ay > 6
      @errors.push {
        title: 'Incorrect attachment point height!'
        body: 'There shouldn\'t be voxels heigher than 5 voxel above or lower than 4 voxels below the attachment point.'
      }
    t = false
    for z in [az-1..az+1] by 1
      for y in [ay-1..ay+1] by 1
        for x in [ax-1..ax+1] by 1
          if x == ax and y == ay
            t = true unless @io.voxels[z]?[y]?[x]?
          else
            t = true if @io.voxels[z]?[y]?[x]?
    if t
      @errors.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel on either side lengthwise
               and nothing else in a 3x3x3 cube around the attachment point.'
      }

  validateGun: ->
    if @io.x > 5 or @io.y > 12 or @io.z > 5 # oriantation and dimension
      if @io.y <= 5 and ((@io.x <= 12 and @io.z <= 5) or (@io.x <= 5 and @io.z <= 12))
        @errors.push {
          title: 'Incorrect gun weapon model oriantation!'
          body: 'You gun weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the muzzle is facing down!
                 Don\'t forget to fix this in your local files too before creating and submitting the blueprint to the devs.'
        }
      else
        @errors.push {
          title: 'Incorrect gun weapon model dimensions!'
          body: 'A gun weapon model should not exceed 5x12x5 voxels.'
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    unless az == 0
      @warnings.push {
        title: 'Incorrect attachment point location!'
        body: 'There shouldn\'t be voxels behind the attachment point.'
      }
    t = false
    for z in [az-1..az+1] by 1
      for y in [ay-1..ay+1] by 1
        for x in [ax-1..ax+1] by 1
          if x == ax and y == ay and z >= az
            t = true unless @io.voxels[z]?[y]?[x]?
          else
            t = true if @io.voxels[z]?[y]?[x]?
    if t
      @errors.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel to the front
               and nothing else in a 3x3x3 cube around the attachment point.'
      }

  validateStaff: ->
    if @io.x > 10 or @io.y > 10 or @io.z > 35 # oriantation and dimension
      if @io.z <= 10 and ((@io.x <= 35 and @io.y <= 10) or (@io.x <= 10 and @io.y <= 35))
        @errors.push {
          title: 'Incorrect staff weapon model oriantation!'
          body: 'You meele weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the tip of your weapon is facing the front!
                 Don\'t forget to fix this in your local files too before creating and submitting the blueprint to the devs.'
        }
      else
        @errors.push {
          title: 'Incorrect staff weapon model dimensions!'
          body: 'A meele weapon model should not exceed 10x10x35 voxels.'
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    if az < 8 or az > 14
      @errors.push {
        title: 'Incorrect attachment point location!'
        body: 'The handle of the staff befind the attachment point must have a length between 8 and 14 voxels.'
      }
    if @io.z - az < 17
      @errors.push {
        title: 'Incorrect attachment point location!'
        body: 'There must be at least 16 voxels between attachment point and the tip of your staff.'
      }
    t = false
    for z in [az-1..az+1] by 1
      for y in [ay-1..ay+1] by 1
        for x in [ax-1..ax+1] by 1
          if x == ax and y == ay
            t = true unless @io.voxels[z]?[y]?[x]?
          else
            t = true if @io.voxels[z]?[y]?[x]?
    if t
      @errors.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel on either side lengthwise
               and nothing else in a 3x3x3 cube around the attachment point.'
      }

  validateBow: ->
    if @io.x > 3 or @io.y > 9 or @io.z > 21 # oriantation and dimension
      if @io.z <= 9 and ((@io.x <= 21 and @io.y <= 9) or (@io.x <= 9 and @io.y <= 21))
        @errors.push {
          title: 'Incorrect bow weapon model oriantation!'
          body: 'You bow weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the bowstring goes from back to front!
                 Don\'t forget to fix this in your local files too before creating and submitting the blueprint to the devs.'
        }
      else
        @errors.push {
          title: 'Incorrect bow weapon model dimensions!'
          body: 'A meele weapon model should not exceed 3x9x21 voxels.'
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    if ay > 3 or @io.y - ay > 6
      @errors.push {
        title: 'Incorrect attachment point height!'
        body: 'There shouldn\'t be voxels heigher than 5 voxel above or lower than 3 voxels below the attachment point.'
      }
    t = false
    for z in [az-1..az+1] by 1
      for y in [ay-1..ay+1] by 1
        for x in [ax-1..ax+1] by 1
          if x == ax and y == ay
            t = true unless @io.voxels[z]?[y]?[x]?
          else
            t = true if @io.voxels[z]?[y]?[x]?
    if t
      @errors.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel on either side lengthwise
               and nothing else in a 3x3x3 cube around the attachment point.'
      }

  validateSpear: ->
    @warnings.push {
      title: 'Linting spears weapon models not yet supported!'
      body: 'Linting spears weapon models is not yet supported. Get feedback in the Trove Creations reddit!'
    }

  validateMask: ->
    if @io.x > 10 or @io.y > 10 # dimension
      @errors.push {
        title: 'Incorrect mask model dimensions!'
        body: 'A mask model should not exceed 10x10x5 voxels.'
      }
    if @io.z > 11
      @warnings.push {
        title: 'Very special mask model depth!'
        body: 'There will be only a few exceptions where mask with a depth greater thab 5 will be accepted.
               You will get feedback if this is the case for you in the submission process and Trove Creations reddit.'
      }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position
    unless az == 0
      @errors.push {
        title: 'Incorrect mask model oriantation!'
        body: 'You mask model is incorrectly oriantated and will be thereby not weared correctly ingame.
               Rotate it so that it is facing the front!
               Don\'t forget to fix this in your local files too before creating and submitting the blueprint to the devs.'
      }
    if ax > 5 or @io.x - ax > 5 or ay > 4 or @io.y - ay > 6
      @errors.push {
        title: 'Incorrect attachment point position!'
        body: 'Check the mask creation guide on the wiki for it\'s correct position..'
      }
    for z in [0...5] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and @io.voxels[z][y][x].t != 7
          return @errors.push {
            title: 'Incorrect attachment point position!'
            body: 'The attachment point should be 6 voxels behind the mask and there shouldn\'t be any voxels behind this distance.'
          }

  validateHat: ->
    if @io.x > 20 or @io.y > 20 or @io.z > 20# dimension
      @errors.push {
        title: 'Incorrect hat model dimensions!'
        body: 'A hat model should not exceed 20x14x20 voxels.'
      }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position
    unless ay == 0
      @errors.push {
        title: 'Incorrect hat model oriantation!'
        body: 'You hat model is incorrectly oriantated and will be thereby not weared correctly ingame.
               Rotate it so that top of the hat is facing up!
               Don\'t forget to fix this in your local files too before creating and submitting the blueprint to the devs.'
      }
    if ax > 10 or @io.x - ax > 10 or az > 9 or @io.z - az > 11
      @errors.push {
        title: 'Incorrect attachment point position!'
        body: 'Check the hat creation guide on the wiki for it\'s correct position.'
      }
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...5] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and @io.voxels[z][y][x].t != 7
          return @errors.push {
            title: 'Incorrect attachment point position!'
            body: 'The attachment point should be 6 voxels below the hat and there shouldn\'t be any voxels below this distance.'
          }

  validateHair: ->
    if @io.x > 20 or @io.y > 20 or @io.z > 20 # dimension
      @errors.push {
        title: 'Incorrect hat model dimensions!'
        body: 'A hat model should not exceed 20x14x20 voxels.'
      }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position
    if ax > 10 or @io.x - ax > 10 or az > 9 or @io.z - az > 11 or ay > 8 or @io.y - ay > 12
      @errors.push {
        title: 'Incorrect attachment point position!'
        body: 'Check the hair creation guide on the wiki for it\'s correct position.'
      }

  validateDeco: ->
    if @io.x > 12 or @io.y > 12 or @io.z > 12
      @errors.push {
        title: 'Incorrect decoration model dimensions!'
        body: 'A decorations model should not exceed 12x12x12 voxels.'
      }

if typeof module == 'object' then module.exports = TroveCreationsLint else window.TroveCreationsLint = TroveCreationsLint
