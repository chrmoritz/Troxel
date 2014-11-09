fs = require 'fs'
exec = require('child_process').exec
global.IO = require '../coffee/IO.coffee'
QubicleIO = require '../coffee/Qubicle.io.coffee'
{Base64IO} = require '../coffee/Troxel.io.coffee'
require '../test/TestUtils.coffee'

BROKEN_MODELS = [ # devtool does not finish after over 1 minute for these blueprints
  'C_P_knight_lvl2_L_thigh.blueprint', 'C_P_knight_lvl2_R_thigh.blueprint', 'C_P_knight_lvl3_L_thigh.blueprint', 'C_P_knight_lvl3_R_thigh.blueprint',
  'C_P_knight_L_thigh.blueprint', 'C_P_knight_R_thigh.blueprint', 'C_P_knight_store_dragon_L_thigh.blueprint', 'C_P_knight_store_dragon_R_thigh.blueprint',
  'C_P_knight_store_trovianguard_L_thigh.blueprint','C_P_knight_store_trovianguard_R_thigh.blueprint', 'deco_highlands_grail_gold.blueprint',
  'C_M_saloonbot_master.blueprint', 'E_F_treestump_01.blueprint', 'E_F_cave_mushroom_01.blueprint', 'E_F_bush_01.blueprint',
  # in these blueprints the heigth (y) of the model is incorrectly set to 4294967295
  'equipment_face_mask_wisebeard[MugensBlade].blueprint', 'equipment_face_mask_soulpatch[Cretoriani].blueprint', 'equipment_face_collar_001.blueprint',
  'char_hair_face_mustache_003.blueprint', 'char_hair_face_mustache_002.blueprint', 'char_hair_face_mustache_001.blueprint'
]

models = {}
jsonPath = process.cwd() + '/static/Trove.json'
process.chdir(process.argv[2] || 'C:/Program Files/Trove/')
fs.readdir 'blueprints', (err, files) ->
  throw err if err?
  toProcess = files.length
  processSny = -> # Trove doesn't like spawning 1k+ instances at the same time ;-)
    f = files.pop()
    return unless f? # all files processed
    if f.length > 10 and f.indexOf('.blueprint') == f.length - 10 and not (f in BROKEN_MODELS)
      exec 'devtool_dungeon_blueprint_to_QB.bat blueprints/' + f, (err, stdout, stderr) ->
        throw err if err?
        qbf = 'qbexport/' + f.substring 0, f.length - 10
        io = new QubicleIO m: qbf + '.qb', a: qbf + '_a.qb', t: qbf + '_t.qb', s: qbf + '_s.qb', ->
          models[f] = new Base64IO(io).export(true)
          if --toProcess == 0
            fs.writeFile jsonPath, JSON.stringify(models), -> thow err if err?
            process.stdout.write 'base64 data successfully written to static/Trove.json\n'
          process.stdout.write "#{toProcess} blueprints remaining: #{f}\n"
        process.nextTick processSny
    else
      if --toProcess == 0
        fs.writeFile jsonPath, JSON.stringify(models), -> thow err if err?
        process.stdout.write 'base64 data successfully written to static/Trove.json\n'
      process.nextTick processSny
  processSny() for i in [0...4] # 4 parallel jobs
