Troxel [![Build Status](https://travis-ci.org/chrmoritz/Troxel.svg?branch=master)](https://travis-ci.org/chrmoritz/Troxel)
======

Troxel is a WebGL-based HTML5-WebApp for viewing and editing voxel models with some additional support for [Trove](http://www.trionworlds.com/trove/) specific features.  Visit [chrmoritz.github.io/Troxel/](http://chrmoritz.github.io/Troxel/) to try it out!

## Features ##
* Supported file formats for both import and export
  * Qubicle (.qb): fully supported (multi matrix, compression ...)
  * Magica Voxel (.vox)
  * Zoxel (.zox)
  * Base64 (links): Troxel's own compressed file format for sharing models via links
  * JSON: raw data output
  * some additions for material maps (multi-layer voxel data) used by Trove
* WebGL-based 3D-Renderer
  * basic support for alpha layer
  * (type and specular are not yet supported)
* Editor
  * simple add and remove voxel functionality
  * rotate and mirror model

## How to use
#### Installing
```
git clone git@github.com:chrmoritz/Troxel.git
cd Troxel
npm update
```
##### Dependencies:
* [Node.js](http://nodejs.org/) 0.10
* for hosting static page locally (optionally): [ruby](https://www.ruby-lang.org/) with jekyll gem (`gem install jekyll`)

#### Running dev server
```
npm start
```
*This server will automatically recompile resources after editing them. You only need to reload you page to see your edits live.*

#### Running tests
```
npm test
```
*Please run this test suite before opening a pull request.*

#### Building a static page
```
npm run build
```
*The static page will be generated into the `dist` folder.*

#### Serving the static page via jekyll
```
npm run serve
```
*Note: You need the jekyll gem installed (`gem install jekyll`) for this.*

#### Importing Trove's blueprints
```
npm run import -- <UNIX-style path to Trove folder>
```
*Note: You have to run this on a Windows machine, because it depends on Trove's devtool for converting `.blueprint` into `.qb`.*
