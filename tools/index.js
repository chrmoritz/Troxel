'use strict';
global.module = require('module');
let res = global.module._resolveFilename;
global.module._resolveFilename = function(r, p){
  return res(r.split('!')[0], p);
};

require('coffee-script/register');
module.exports = {
  IO: require('../coffee/IO'),
  MagicaIO: require('../coffee/Magica.io'),
  QubicleIO: require('../coffee/Qubicle.io'),
  Base64IO: require('../coffee/Troxel.io').Base64IO,
  JsonIO: require('../coffee/Troxel.io').JsonIO,
  ZoxelIO: require('../coffee/Zoxel.io'),
  TestUtils: function(){return require('../test/TestUtils');}
};
