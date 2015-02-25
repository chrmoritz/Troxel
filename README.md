Troxel [![Travis Build Status (Linux)](https://img.shields.io/travis/chrmoritz/Troxel/master.svg?label=Travis build)](https://travis-ci.org/chrmoritz/Troxel) [![AppVeyor Build status (Windows)](https://ci.appveyor.com/api/projects/status/glwcnbd0k2qh6f29/branch/master?svg=true)](https://ci.appveyor.com/project/chrmoritz/troxel/branch/master) [![devDependency Status](https://david-dm.org/chrmoritz/Troxel/dev-status.svg)](https://david-dm.org/chrmoritz/Troxel#info=devDependencies)
======

Troxel is a WebGL-based HTML5-WebApp for viewing and editing voxel models with some additional support for [Trove](http://www.trionworlds.com/trove/) specific features.  Visit [chrmoritz.github.io/Troxel/](http://chrmoritz.github.io/Troxel/) to try it out! You can embed Troxel in your own website too with [libTroxel](#libtroxel).

## Features ##
* Supported file formats for both import and export
  * Qubicle (.qb): fully supported (multi matrix, compression ...)
  * Magica Voxel (.vox)
  * Zoxel (.zox)
  * Base64 (links): Troxel's own compressed file format for sharing models via links
  * JSON: raw data output
  * some additions for material maps (multi-layer voxel data) used by Trove
* WebGL-based 3D-Renderer
  * basic support for all material maps
* Editor
  * simple add and remove voxel functionality
  * rotate, mirror, move and resize voxel model
  * filltool with color noise

## How to use
#### Installing
```
git clone git@github.com:chrmoritz/Troxel.git
cd troxel
npm install
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
*The static page will be served by Jekyll (like on GitHub Pages) and grunt will watch for source file changes and automatically recompile these changes and update Jekyll.*

**Note:** *You need the jekyll gem installed (`gem install jekyll`) for this.*

#### Importing Trove's blueprints
```
npm run import -- <UNIX-style path to Trove folder>
```
**Note:** *You have to run this on a Windows machine, because it depends on Trove's devtool for converting `.blueprint` into `.qb`.*

libTroxel
======

LibTroxel is a JavaScript library which allows you to embedd voxel models rendered with Troxel into your own website.

## How to use

LibTroxel is licensed under the same license as Troxel, the [GNU LGPL v3.0](LICENSE.txt) . You can find an [example usage of libTroxel here](test/libTroxelTest.html).

#### Dependencies

In addition to libTroxel, you will need to include JQuery into your site. If you want to use our github pages site as a CDN just add these lines to your html:

```html
<script src="https://chrmoritz.github.io/Troxel/static/js/jquery.min.js" type="text/javascript"></script>
<script src="https://chrmoritz.github.io/Troxel/static/libTroxel.min.js" type="text/javascript"></script>
```

### API

Create somewhere in your layout a `<div>` element and set it's size to the size the rendered model should have. You can add a fallback content inside it, which will be shown if the model is  not available or your users browser doesn't support WebGL.

#### Troxel.renderBlueprint(blueprintId, domElement, [options], [callback])

Renders any Trove blueprint into the given DOM element. It has these parameters:
* `blueprintId` is the id of the blueprint (the filename without the `.blueprint` file extension)
* `domElement` is either a DOM element or a JQuery Object representing this DOM element
* `options` is an optional Object of [render options](#options)
* `callback(error, options)` is an optional callback function which the `error` argument set to `null` if the blueprint is successfully loaded or with `error` set to an Error object if an error has occurred (WebGl not support or blueprint not found ). `options` is an Object with setters and getters containing nearly all [render options](#options)

```JavaScript
Troxel.renderBlueprint('deco_candy_torch_mallow[Laoge]', $('#container'), {
    autoRotate: true,
    autoRotateSpeed: 4.0,
    rendererClearColor: 0x9c9c9c,
    ambientLightColor: 0x707070,
    directionalLightColor: 0xeeeeee,
    directionalLightIntensity: 0.9,
    directionalLightVector: {x: 0.58, y: 0.58, z: 0.58}
}, function(error, resultOptions){
  if (error === null){
    resultOptions.noZoom = true;
  }
});
```

#### Troxel.renderBase64(base64, domElement, [options])

Renders any voxel model represented in Troxel's Base64 format into the given DOM element. It has these parameters:
* `base64` is a Base64 formated String containing the voxel data of your model (check out Troxels `Link (share)` export options and use the base64 string starting after `#m=`)
* `domElement` is either a DOM element or a JQuery Object representing this DOM element
* `options` is an optional Object of [render options](#options)
Returns an Object with the `error` property set to `null` if it was able to successfully load the model or set to a Error object if WebGl isn't supported or the base64 string was invalid. In the first case a options property is defined containing a Object with nearly all [render options](#options) as setters and getters.

#### Troxel.webgl()

Returns `true` if the current browser supports WebGL and `false` otherwise.

#### Markup API (data attributes)

If you can't use Java Script to call the Java Script API (for example in wiki templates or forums bb-tags) you can also embedd voxel models with libTroxel using html markup only. Just create a div with the desired size and these data attributes:
* `data-troxel-blueprint`: set it to the id of the blueprint (the filename without the `.blueprint` file extension)
* or `data-troxel-base64`: set it to a Base64 formated String containing the voxel data of your model (check out Troxels `Link (share)` export options and use the base64 string starting after `#m=`)
* and optionally `data-troxel-options`: set it to a JSON containing a Object of [render options](#options)

```html
<div data-troxel-blueprint="item_tf_candy" data-troxel-options='{"autoRotate": false}' style="width: 300px; height: 300px;">
    <!-- insert fallback content (like a static image of the rendered model) here -->
</div>
```

### Options

`options` is a JavaScript Object with these optional keys:

Options                    | Description                                                                           | Default
---------------------------|---------------------------------------------------------------------------------------|-----------
`autoRotate`               | set it to `true` to automatically rotate around the voxel model                       | `true`
`autoRotateSpeed`          | the rotation speed in full rotation per minute at 60 fps (set to negative values to change the auto rotate direction)                                                                                               | `-4.0` (15 sec / rotation @60fps)
`rendererAntialias`        | disables the antialiasing of the renderer if set to (only available at initialisation)| `true`
`rendererClearColor`       | the color of the background behind the voxel model                                    | `0x888888`
`ambientLightColor`        | the color of the ambient light                                                        | `0x606060`
`directionalLightColor`    | the color of the directional light                                                    | `0xffffff`
`directionalLightIntensity`| the intensity of the direction light as a Float                                       | `0.3`
`directionalLightVector`   | the vector direction of the directional light as an Object (don't need to be a normal vector)                                                                                                        | `{x: -0.5, y: -0.5, z: 1}`
`spotLightColor`           | the color of the spot light                                                           | `0xffffff`
`spotLightIntensity`       | the intensity of the spot light as a Float                                            | `0.7`
`noRotate`                 | disables the rotate controls if set to `true`                                         | `false`
`noPan`                    | disables the pan controls if set to `true`                                            | `false`
`noZoom`                   | disables the zoom controls if set to `true`                                           | `false`
`showInfoLabel`            | set to `false`, if you want to hide the 'Open this model in Troxel' link (I would appreciate it if you would link somewhere else to Troxel in this case, this option is only available at initialisation)                                                             | `true`

*Note: for performance reasons you should prefere passing colors as a Javascript hexadecimal Numbers instead of hex strings like in css*
