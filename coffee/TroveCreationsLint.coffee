'use strict'
class TroveCreationsLint
  constructor: (@io, @type) ->
    @errors = []
    @warnings = []
    @infos = []
    [x, y, z, ox, oy, oz] = @io.computeBoundingBox()
    @io.resize x, y, z, ox, oy, oz
    @hasExactlyOneAttachmentPoint() if @type not in ['deco', 'lair', 'dungeon']
    @hasNoBlackVoxels()
    @hasNoFloatingVoxels() if @type not in ['lair', 'dungeon']
    @usesMaterialMaps() if @type not in ['lair', 'dungeon']
    if @io.warn
      @warnings.push {
        title: 'Troxel had to fix issues in your material maps for you!'
        body: 'There were issues in your material maps like invalid color values in the type / alpha / specualr map or having a voxel in one map
               but not in another. These were fixed automatically on import by Troxel for you (Check the WebConsole for detailed information.).
               It\'s recommended that you either fix these isues by yourself in your source .qb files or use the .qb files
               exported by Troxel for creating your .blueprint for submission.'
      }
    switch @type
      when 'melee' then @validateMelee()
      when 'gun'   then @validateGun()
      when 'staff' then @validateStaff()
      when 'bow'   then @validateBow()
      when 'spear' then @validateSpear()
      when 'mask'  then @validateMask()
      when 'hat'   then @validateHat()
      when 'hair'  then @validateHair()
      when 'deco'  then @validateDeco()
      else @infos.push {
        title: 'Linting lairs and dungeons not yet supported!'
        body: 'Linting lairs and dungeons is not yet supported. Get feedback in the Trove Creations reddit!'
      }

  hasExactlyOneAttachmentPoint: ->
    i = 0
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]?
          vox = @io.voxels[z][y][x]
          if vox.t == 7 or vox.s == 7 or vox.a == 250 or (vox.r == vox.b == 255 and vox.g == 0)
            i++
            t = vox.t == vox.s == 7 and vox.a == 250 and vox.r == vox.b == 255 and vox.g == 0
    if i == 1
      @errors.push {
        title: 'Attachment point not in all material maps found!'
        body: 'Your attachment point is only marked in some but not all material maps as a pink voxel.
               You need to change the voxel to a pink (255, 0, 255) voxel in all material maps!'
      } unless t
      return @correctAttachmentPoint = true
    @correctAttachmentPoint = false
    if i == 0
      return @errors.push {
        title: 'No attachment point found!'
        body: 'You need to specify an attachment point, a (255, 0, 255) = #FF00FF pink voxel, thereby your model will be aligned correctly ingame.
               Check out the guide for your specific creation type linked in the blue infobox below for more informations!'
      }
    @errors.push {
      title: 'Multiple attachment points found!'
      body: "You have more the one attachment point in your model (#{i} found). Avoid the usage of excatly pink (255, 0, 255) voxels in your model
             except for the attachment point in EVERY material map."
    }

  hasNoBlackVoxels: ->
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]?
          vox = @io.voxels[z][y][x]
          if Math.min(vox.r, vox.g, vox.b) + Math.max(vox.r, vox.g, vox.b) < 20
            return @errors.push {
              title: 'Too dark voxel found!'
              body: "There shouldn't be voxels darker than (10, 10, 10) in your voxel model, but we found a voxel with (#{vox.r}, #{vox.g}, #{vox.b}).
                     Try to use a (brighter) dark grey voxel instead. Check out the
                     <a href=\"http://trove.wikia.com/wiki/Style_guidelines#Full_Black\" class=\"alert-link\" target=\"_blank\">style guide</a>
                     for more informations!"
            }

  hasNoFloatingVoxels: ->
    toCheck = @getStartingVoxel()
    return unless toCheck?
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
            t = true unless @io.voxels[z][y][x].t == 7 and @type in ['hair', 'hat', 'mask'] # attachment point have to float
    if t
      @warnings.push { # ToDo: mark them with wireframes?
        title: 'Your model has floating/corner-connected voxels!'
        body: 'There are voxels in your model, which are not directly connected to other voxels (in some cases caused by a unnecessary hole).
               Read more about voxel placements in
               the <a href="http://trove.wikia.com/wiki/Style_guidelines#Voxel_Placement" class="alert-link" target="_blank">sytle guides</a>.
               There will be only a few exceptions where models with floating/corner-connected  voxels will be accepted. Try to avoid them!
               You will get feedback if this is the case for you in the submission process on the Trove Creations subreddit.'
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
    @infos.push {
      title: 'Material maps not used!'
      body: 'It looks like you haven\'t used any material maps in your voxel model. If you arent yet familiar with them, check out the
             <a href="http://trove.wikia.com/wiki/Material_Map_Guide" class="alert-link" target="_blank">Material Map Guide</a> for more informations
             on how you could make voxel look more metallic or like transparent glass for example. You should use them where suitable in your model!'
    }

  validateMelee: ->
    if @io.x > 10 or @io.y > 10 or @io.z > 35 # oriantation and dimension
      if @io.z <= 10 and ((@io.x <= 35 and @io.y <= 10) or (@io.x <= 10 and @io.y <= 35))
        return @errors.push {
          title: 'Incorrect melee weapon model oriantation!'
          body: 'Your melee weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the tip of your weapon is facing the front!
                 Don\'t forget to fix this in your local files too before creating and submitting the .blueprint.'
        }
      else
        @errors.push {
          title: 'Incorrect melee weapon model dimensions!'
          body: "A melee weapon model should not exceed 10x10x35 voxels, but yours is #{@io.x}x#{@io.y}x#{@io.z}. Check out
                 the <a href=\"http://trove.wikia.com/wiki/Melee_weapon_creation#Weapon_dimensions\" class=\"alert-link\" target=\"_blank\">melee
                 weapon creation guide</a> for more informations!"
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    if ay > 4 or @io.y - ay > 6
      @warnings.push {
        title: 'Incorrect attachment point height!'
        body: "There shouldn't be voxels heigher than 5 voxel above or lower than 4 voxels below the attachment point!
               But in your melee weapon model there are up to #{@io.y - ay - 1} voxel above and #{ay} voxels below the attachment point. Check out the
               <a href=\"http://trove.wikia.com/wiki/Melee_weapon_creation#Handle_size_and_attachment\" class=\"alert-link\" target=\"_blank\">melee
               weapon creation guide</a> for more informations!"
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
      @warnings.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel on either side lengthwise
               and nothing else in a 3x3x3 cube around the attachment point. Check out the
               <a href="http://trove.wikia.com/wiki/Melee_weapon_creation#Handle_size_and_attachment" class="alert-link" target="_blank">melee
               weapon creation guide</a> for more informations!'
      }

  validateGun: ->
    if @io.x > 5 or @io.y > 12 or @io.z > 5 # oriantation and dimension
      if @io.y <= 5 and ((@io.x <= 12 and @io.z <= 5) or (@io.x <= 5 and @io.z <= 12))
        return @errors.push {
          title: 'Incorrect gun weapon model oriantation!'
          body: 'Your gun weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the muzzle is facing down! Check out the
                 <a href="http://trove.wikia.com/wiki/Gun_Weapon_Creation#Weapon_orientation" class="alert-link" target="_blank">gun
                 weapon creation guide</a> for more informations!
                 Don\'t forget to fix this in your local files too before creating and submitting the .blueprint.'
        }
      else
        @errors.push {
          title: 'Incorrect gun weapon model dimensions!'
          body: "A gun weapon model should not exceed 5x12x5 voxels, but yours is #{@io.x}x#{@io.y}x#{@io.z}. Check out
                 the <a href=\"http://trove.wikia.com/wiki/Gun_Weapon_Creation#Weapon_dimensions\" class=\"alert-link\" target=\"_blank\">gun
                 weapon creation guide</a> for more informations!"
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    unless az == 0
      @warnings.push {
        title: 'Incorrect attachment point location!'
        body: 'There shouldn\'t be voxels behind the attachment point. Check out the
               <a href="http://trove.wikia.com/wiki/Gun_Weapon_Creation#Handle_size_and_attachment" class="alert-link" target="_blank">gun
               weapon creation guide</a> for more informations! Exceptions may be made for guns which are designed to be worn like a glove.'
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
      @warnings.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel to the front
               and nothing else in a 3x3x3 cube around the attachment point. Check out the
               <a href="http://trove.wikia.com/wiki/Gun_Weapon_Creation#Handle_size_and_attachment" class="alert-link" target="_blank">gun
               weapon creation guide</a> for more informations! Exceptions may be made for guns which are designed to be worn like a glove.'
      }

  validateStaff: ->
    if @io.x > 12 or @io.y > 12 or @io.z > 35 # oriantation and dimension
      if @io.z <= 12 and ((@io.x <= 35 and @io.y <= 12) or (@io.x <= 12 and @io.y <= 35))
        return @errors.push {
          title: 'Incorrect staff weapon model oriantation!'
          body: 'Your staff weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the tip of your weapon is facing the front!
                 Don\'t forget to fix this in your local files too before creating and submitting the .blueprint.'
        }
      else
        @errors.push {
          title: 'Incorrect staff weapon model dimensions!'
          body: "A staff weapon model should not exceed 12x12x35 voxels, but yours is #{@io.x}x#{@io.y}x#{@io.z}. Check out
                 the <a href=\"http://trove.wikia.com/wiki/Staff_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">staff
                 weapon creation guide</a> for more informations!"
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    if az < 8 or az > 14
      @warnings.push {
        title: 'Incorrect attachment point location!'
        body: "The handle of the staff befind the attachment point must have a length between 8 and 14 voxels (your handle length: #{az}). Check out
               the <a href=\"http://trove.wikia.com/wiki/Staff_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">staff
               weapon creation guide</a> for more informations!"
      }
    if @io.z - az < 17
      @warnings.push {
        title: 'Incorrect attachment point location!'
        body: "There must be at least 16 voxels between attachment point and the tip of your staff (your distance: #{@io.z - az - 1}). Check out
               the <a href=\"http://trove.wikia.com/wiki/Staff_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">staff
               weapon creation guide</a> for more informations!"
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
      @warnings.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel on either side lengthwise
               and nothing else in a 3x3x3 cube around the attachment point. Check out the
               <a href="http://trove.wikia.com/wiki/Staff_Creation_Guide#Handle_size_and_attachment" class="alert-link" target="_blank">staff
               weapon creation guide</a> for more informations!'
      }

  validateBow: ->
    if @io.x > 3 or @io.y > 9 or @io.z > 21 # oriantation and dimension
      if @io.z <= 9 and ((@io.x <= 21 and @io.y <= 9) or (@io.x <= 9 and @io.y <= 21))
        return @errors.push {
          title: 'Incorrect bow weapon model oriantation!'
          body: 'You bow weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the bowstring goes from back to front!
                 Don\'t forget to fix this in your local files too before creating and submitting the .blueprint.'
        }
      else if @io.x <= 5 and @io.y <= 9 and @io.z <= 21
        @warnings.push {
          title: 'Bow model dimensions does not follow guidelines!'
          body: "Your bow weapon model is more than the allowed 3 voxel thick. Try to reduce the thickness if you can, but if the 5 voxels tickness
                 is really required for your bow and does make sense, go ahead add submit it to get feedback if it can stay this way. Check out
                 the <a href=\"http://trove.wikia.com/wiki/Bow_Creation_Guide#Basic_Dimensions\" class=\"alert-link\" target=\"_blank\">bow
                 weapon creation guide</a> for more informations!"
        }
      else
        @errors.push {
          title: 'Incorrect bow model dimensions!'
          body: "A bow weapon model should not exceed 3x9x21 voxels, but yours is #{@io.x}x#{@io.y}x#{@io.z}. Check out
                 the <a href=\"http://trove.wikia.com/wiki/Bow_Creation_Guide#Basic_Dimensions\" class=\"alert-link\" target=\"_blank\">bow
                 weapon creation guide</a> for more informations!"
        }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position and surrounding
    if ay > 3 or @io.y - ay > 6
      @warnings.push {
        title: 'Incorrect attachment point height!'
        body: "There shouldn\'t be voxels heigher than 5 voxel above or lower than 3 voxels below the attachment point.
               But in your bow model there are up to #{@io.y - ay - 1} voxel above and #{ay} voxels below the attachment point. Check out
               the <a href=\"http://trove.wikia.com/wiki/Bow_Creation_Guide#Basic_Dimensions\" class=\"alert-link\" target=\"_blank\">bow
               weapon creation guide</a> for more informations!"
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
      @warnings.push {
        title: 'Incorrect attachment point surrounding / handle!'
        body: 'Around the attachment point there should be only one voxel on either side lengthwise
               and nothing else in a 3x3x3 cube around the attachment point. Check out
               the <a href="http://trove.wikia.com/wiki/Bow_Creation_Guide#Other_details" class="alert-link" target="_blank">bow
               weapon creation guide</a> for more informations!'
      }

  validateSpear: ->
    if @io.x > 11 or @io.y > 11 or @io.z > 45 # oriantation and dimension
      if @io.z <= 11 and ((@io.x <= 45 and @io.y <= 11) or (@io.x <= 11 and @io.y <= 45))
        return @errors.push {
          title: 'Incorrect spear weapon model oriantation!'
          body: 'Your spear weapon model is incorrectly oriantated and will be thereby held in a wrong direction ingame.
                 Rotate it so that the tip/head of your weapon is facing the front!
                 Don\'t forget to fix this in your local files too before creating and submitting the .blueprint.'
        }
      else
        @errors.push {
          title: 'Incorrect spear weapon model dimensions!'
          body: "A spear weapon model should not exceed 11x11x45 voxels, but yours is #{@io.x}x#{@io.y}x#{@io.z}. Check out
                 the <a href=\"http://trove.wikia.com/wiki/Spear_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">spear
                 weapon creation guide</a> for more informations!"
        }
    if @io.z < 45
      @errors.push {
        title: 'Incorrect spear weapon model length!'
        body: "A spear weapon model should be exactly 45 voxels long, but yours is only #{@io.z} voxel long. Check out
               the <a href=\"http://trove.wikia.com/wiki/Spear_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">spear
               weapon creation guide</a> for more informations!"
      }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position
    if az < 5 or az > 9
      @errors.push {
        title: 'Incorrect attachment point position!'
        body: "The attachment point in the shaft of the spear should be between 2 and 6 voxel away (not including the attachment point)
               from the base of the spear, but yours is #{az - 3} voxel away. Check out the
               <a href=\"http://trove.wikia.com/wiki/Spear_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">spear
               creation guide</a> for more informations!"
      }
    for z in [0...2] by 1 when @io.voxels[z]? # check base
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and (x > ax + 1 or x < ax - 1 or y > ay + 1 or y < ay - 1)
          return @errors.push {
            title: 'Incorrect spear base!'
            body: "The spear base should fit in a 3x3x3 area with the shaft connected in the center of the base. Check out the
                   <a href=\"http://trove.wikia.com/wiki/Spear_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">spear
                   creation guide</a> for more informations!"
          }
    for z in [3...30] by 1 when @io.voxels[z]? # check shaft
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and (x != ax or y != ay)
          return @errors.push {
            title: 'Incorrect spear shaft or too long spear head/base!'
            body: "The spear shaft should only be 1 voxel thick and 27 voxels long and connect the (3 voxel long) spear base with the 15 voxel long
                   spear head. But your spear head is either #{@io.z - z} voxel long or your spear shaft is too thick. Check out the
                   <a href=\"http://trove.wikia.com/wiki/Spear_Creation_Guide#Weapon_Dimensions\" class=\"alert-link\" target=\"_blank\">spear
                   creation guide</a> for more informations!"
          }

  validateMask: ->
    if @io.x > 10 or @io.y > 10 # dimension
      @errors.push {
        title: 'Incorrect mask model dimensions!'
        body: "A mask model should not exceed 10x10x5 voxels, but yours is #{@io.x}x#{@io.y}x#{@io.z - 6}. Check out
               the <a href=\"http://trove.wikia.com/wiki/Mask_creation#Item_dimensions\" class=\"alert-link\" target=\"_blank\">mask creation guide</a>
               for more informations!"
      }
    if @io.z > 11
      @warnings.push {
        title: 'Very special mask model depth!'
        body: "There will be only a few exceptions where mask with a depth greater than 5 will be accepted (your depth: #{@io.z - 6}).
               You will get feedback if this is the case for you in the submission process and Trove Creations reddit. Check out
               the <a href=\"http://trove.wikia.com/wiki/Mask_creation#Item_dimensions\" class=\"alert-link\" target=\"_blank\">mask creation guide</a>
               for more informations!"
      }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position
    unless az == 0
      return @errors.push {
        title: 'Incorrect mask model oriantation!'
        body: 'You mask model is incorrectly oriantated and will be thereby not weared correctly ingame.
               Rotate it so that it is facing the front!
               Don\'t forget to fix this in your local files too before creating and submitting the .blueprint.'
      }
    if ax > 5 or @io.x - ax > 5 or ay > 4 or @io.y - ay > 6
      @errors.push {
        title: 'Incorrect attachment point position!'
        body: "There shouldn't be more than 5 voxels to the right (#{ax}), 4 to the left (#{@io.x - ax - 1}), 5 above (#{@io.y - ay - 1})
               and 4 below (#{ay}) the attachment point (your models distances are in the brackest). Check out the
               <a href=\"http://trove.wikia.com/wiki/Mask_creation#Head_attachment\" class=\"alert-link\" target=\"_blank\">mask creation guide</a>
               on the wiki for are more in depth attachment point position guide."
      }
    for z in [0..5] by 1 when @io.voxels[z]?
      for y in [0...@io.y] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and @io.voxels[z][y][x].t != 7
          return @errors.push {
            title: 'Incorrect attachment point position!'
            body: "The attachment point should be 6 voxels behind the mask and there shouldn't be any voxels behind this distance. Check out the
                   <a href=\"http://trove.wikia.com/wiki/Mask_creation#Head_attachment\" class=\"alert-link\" target=\"_blank\">mask creation guide</a>
                   for more informations! (minimal distance to the mask was #{z} instead of 6 voxels)"
          }

  validateHat: ->
    if @io.x > 20 or @io.y > 20 or @io.z > 20 # dimension
      @errors.push {
        title: 'Incorrect hat model dimensions!'
        body: "A hat model should not exceed 20x14x20 voxels, but yours is #{@io.x}x#{@io.y - 6}x#{@io.z}. Check out
               the <a href=\"http://trove.wikia.com/wiki/Hat_creation#Item_dimensions\" class=\"alert-link\" target=\"_blank\">hat creation guide</a>
               for more informations!"
      }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position
    unless ay == 0
      return @errors.push {
        title: 'Incorrect hat model oriantation!'
        body: 'You hat model is incorrectly oriantated and will be thereby not weared correctly ingame.
               Rotate it so that top of the hat is facing up!
               Don\'t forget to fix this in your local files too before creating and submitting the .blueprint.'
      }
    if ax > 10 or @io.x - ax > 10 or az > 9 or @io.z - az > 11
      @errors.push {
        title: 'Incorrect attachment point position!'
        body: "There shouldn't be more than 10 voxels to the right (#{ax}), 9 to the left (#{@io.x - ax - 1}), 10 in front of (#{@io.z - az - 1})
               and 9 behind (#{az}) the attachment point (your models distances are in the brackest). Check out the
               <a href=\"http://trove.wikia.com/wiki/Hat_creation#Head_attachment\" class=\"alert-link\" target=\"_blank\">hat creation guide</a>
               on the wiki for are more in depth attachment point position guide."
      }
    for z in [0...@io.z] by 1 when @io.voxels[z]?
      for y in [0..5] by 1 when @io.voxels[z][y]?
        for x in [0...@io.x] by 1 when @io.voxels[z][y][x]? and @io.voxels[z][y][x].t != 7
          return @errors.push {
            title: 'Incorrect attachment point position!'
            body: "The attachment point should be 6 voxels below the hat and there shouldn't be any voxels below this distance. Check out the
                   <a href=\"http://trove.wikia.com/wiki/Hat_creation#Head_attachment\" class=\"alert-link\" target=\"_blank\">hat creation guide</a>
                   for more informations! (minimal distance to the hat was #{y} instead of 6 voxels)"
          }

  validateHair: ->
    if @io.x > 20 or @io.y > 20 or @io.z > 20 # dimension
      @errors.push {
        title: 'Incorrect hat model dimensions!'
        body: "A hair model should not exceed 20x14x20 voxels, but yours is #{@io.x}x#{@io.y - 6}x#{@io.z}. Check out
               the <a href=\"http://trove.wikia.com/wiki/Hair_creation#Item_dimensions\" class=\"alert-link\" target=\"_blank\">hair creation guide</a>
               for more informations!"
      }
    return unless @correctAttachmentPoint
    [ax, ay, az] = @io.getAttachmentPoint() # attachment point position
    if ax > 10 or @io.x - ax > 10 or az > 9 or @io.z - az > 11 or ay > 8 or @io.y - ay > 12
      @errors.push {
        title: 'Incorrect attachment point position!'
        body: 'Check the <a href="http://trove.wikia.com/wiki/Hair_creation#Head_attachment" class="alert-link" target="_blank">hair creation guide</a>
               on the wiki for it\'s correct position.'
      }

  validateDeco: ->
    if @io.x > 12 or @io.y > 12 or @io.z > 12
      @errors.push {
        title: 'Incorrect decoration model dimensions!'
        body: "A decorations model should not exceed 12x12x12 voxels, but yours is #{@io.x}x#{@io.y}x#{@io.z}. Check out
               the <a href=\"http://trove.wikia.com/wiki/Cornerstone_decoration_creation\" class=\"alert-link\" target=\"_blank\">decoration
               creation guide</a> for more informations!"
      }

if typeof module == 'object' then module.exports = TroveCreationsLint else window.TroveCreationsLint = TroveCreationsLint
