require('coffee-script/register');
global.IO = require('../coffee/IO');
module.exports = {
  IO: global.IO,
  MagicaIO: require('../coffee/Magica.io'),
  QubicleIO: require('../coffee/Qubicle.io'),
  Base64IO: require('../coffee/Troxel.io').Base64IO,
  JsonIO: require('../coffee/Troxel.io').JsonIO,
  ZoxelIO: require('../coffee/Zoxel.io'),
  TestUtils: function(){require('../test/TestUtils');}
};
