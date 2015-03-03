/**
 * @author qiao / https://github.com/qiao
 * @author mrdoob / http://mrdoob.com
 * @author alteredq / http://alteredqualia.com/
 * @author WestLangley / http://github.com/WestLangley
 * @author erich666 / http://erichaines.com
 */
// threejs.org/license

THREE.MixedControls = function ( object, domElement ) {
	this.object = object;
	this.domElement = ( domElement !== undefined ) ? domElement : document;
	// API
	this.enabled = true; // Set to false to disable this control
	this.mode = true; // true for Orbital and false for Fly controls
	this.target = new THREE.Vector3(); // "target" sets the location of focus, where the control orbits around and where it pans with respect to.
	this.center = this.target; // center is old, deprecated; use "target" instead
	this.noZoom = false; // This option actually enables dollying in and out
	this.zoomSpeed = 1.0;
	this.minDistance = 0; // Limits to how far you can dolly in and out
	this.maxDistance = Infinity;
	this.noRotate = false;
	this.rotateSpeed = 1.0;
	this.noPan = false;
	this.autoRotate = false; // Set to true to automatically rotate around the target
	this.autoRotateSpeed = -4.0; // 15 seconds per round when fps is 60
	this.noKeys = false; // Set to true to disable use of the keys
	// internals
	var scope = this;
	var EPS = 0.000001;
	var rotateStart = new THREE.Vector2();
	var rotateEnd = new THREE.Vector2();
	var rotateDelta = new THREE.Vector2();
	var panStart = new THREE.Vector2();
	var panEnd = new THREE.Vector2();
	var panDelta = new THREE.Vector2();
	var panOffset = new THREE.Vector3();
	var offset = new THREE.Vector3();
	var dollyStart = new THREE.Vector2();
	var dollyEnd = new THREE.Vector2();
	var dollyDelta = new THREE.Vector2();
	var theta;
	var phi;
	var phiDelta = 0;
	var thetaDelta = 0;
	var scale = 1;
	var pan = new THREE.Vector3();
	var lastPosition = new THREE.Vector3();
	var lastQuaternion = new THREE.Quaternion();
	var STATE = { NONE : -1, ROTATE : 0, DOLLY : 1, PAN : 2, TOUCH_ROTATE : 3, TOUCH_DOLLY : 4, TOUCH_PAN : 5, FLY: 6 };
	var state = STATE.NONE;
	this.target0 = this.target.clone(); // for reset
	this.position0 = this.object.position.clone();
	var quat = new THREE.Quaternion().setFromUnitVectors( object.up, new THREE.Vector3( 0, 1, 0 ) ); // so camera.up is the orbit axis
	var quatInverse = quat.clone().inverse();
	// Fly Controls internals
	var moveVector = new THREE.Vector3();
	var rotationVector = new THREE.Vector3();
	var tmpQuaternion = new THREE.Quaternion();
	var mousefly = false;
	// events
	var changeEvent = { type: 'change' };
	var startEvent = { type: 'start'};
	var endEvent = { type: 'end'};

	this.rotateLeft = function ( angle ) {
		if ( angle === undefined ) {
			angle = getAutoRotationAngle();
		}
		thetaDelta -= angle;
	};

	this.rotateUp = function ( angle ) {
		if ( angle === undefined ) {
			angle = getAutoRotationAngle();
		}
		phiDelta -= angle;
	};

	this.panLeft = function ( distance ) { // pass in distance in world space to move left
		var te = this.object.matrix.elements;
		panOffset.set( te[ 0 ], te[ 1 ], te[ 2 ] ); // get X column of matrix
		panOffset.multiplyScalar( - distance );
		pan.add( panOffset );
	};

	this.panUp = function ( distance ) { // pass in distance in world space to move up
		var te = this.object.matrix.elements;
		panOffset.set( te[ 4 ], te[ 5 ], te[ 6 ] ); // get Y column of matrix
		panOffset.multiplyScalar( distance );
		pan.add( panOffset );
	};

	this.pan = function ( deltaX, deltaY ) { // pass in x,y of change desired in pixel space, right and down are positive
		var element = scope.domElement === document ? scope.domElement.body : scope.domElement;
		if ( scope.object.fov !== undefined ) {
			var position = scope.object.position; // perspective
			var offset = position.clone().sub( scope.target );
			var targetDistance = offset.length();
			targetDistance *= Math.tan( ( scope.object.fov / 2 ) * Math.PI / 180.0 ); // half of the fov is center to top of screen
			scope.panLeft( 2 * deltaX * targetDistance / element.clientHeight ); // we actually don't use screenWidth, since perspective camera is fixed to screen height
			scope.panUp( 2 * deltaY * targetDistance / element.clientHeight );
		} else if ( scope.object.top !== undefined ) {
			scope.panLeft( deltaX * (scope.object.right - scope.object.left) / element.clientWidth ); // orthographic
			scope.panUp( deltaY * (scope.object.top - scope.object.bottom) / element.clientHeight );
		} else {
			console.warn( 'WARNING: Controls.js encountered an unknown camera type - pan disabled.' ); // camera neither orthographic or perspective
		}
	};

	this.dollyIn = function ( dollyScale ) {
		if ( dollyScale === undefined ) {
			dollyScale = getZoomScale();
		}
		scale /= dollyScale;
	};

	this.dollyOut = function ( dollyScale ) {
		if ( dollyScale === undefined ) {
			dollyScale = getZoomScale();
		}
		scale *= dollyScale;
	};

	this.update = function () {
		if ( scope.mode ) {
			var position = this.object.position;
			offset.copy( position ).sub( this.target );
			offset.applyQuaternion( quat ); // rotate offset to "y-axis-is-up" space
			theta = Math.atan2( offset.x, offset.z ); // angle from z-axis around y-axis
			phi = Math.atan2( Math.sqrt( offset.x * offset.x + offset.z * offset.z ), offset.y ); // angle from y-axis
			if ( this.autoRotate && state === STATE.NONE ) {
				this.rotateLeft( getAutoRotationAngle() );
			}
			theta += thetaDelta;
			phi += phiDelta;
			phi = Math.max( EPS, Math.min( Math.PI - EPS, phi ) ); // restrict phi to be betwee EPS and PI-EPS
			var radius = offset.length() * scale;
			radius = Math.max( this.minDistance, Math.min( this.maxDistance, radius ) ); // restrict radius to be between desired limits
			this.target.add( pan ); // move target to panned location
			offset.x = radius * Math.sin( phi ) * Math.sin( theta );
			offset.y = radius * Math.cos( phi );
			offset.z = radius * Math.sin( phi ) * Math.cos( theta );
			offset.applyQuaternion( quatInverse ); // rotate offset back to "camera-up-vector-is-up" space
			position.copy( this.target ).add( offset );
			this.object.lookAt( this.target );
			thetaDelta = 0;
			phiDelta = 0;
			scale = 1;
			pan.set( 0, 0, 0 );
		} else {
			this.object.translateX( moveVector.x * 20 );
			this.object.translateY( moveVector.y * 20 );
			this.object.translateZ( moveVector.z * 20 );
			tmpQuaternion.set( rotationVector.x * 0.003, rotationVector.y * 0.003, rotationVector.z * 0.003, 1 ).normalize();
			this.object.quaternion.multiply( tmpQuaternion );
			this.object.rotation.setFromQuaternion( this.object.quaternion, this.object.rotation.order ); // expose the rotation vector for convenience
		}
		// update condition is: min(camera displacement, camera rotation in radians)^2 > EPS using small-angle approximation cos(x/2) = 1 - x^2 / 8
		if ( lastPosition.distanceToSquared( this.object.position ) > EPS || 8 * (1 - lastQuaternion.dot(this.object.quaternion)) > EPS ) {
			this.dispatchEvent( changeEvent );
			lastPosition.copy( this.object.position );
			lastQuaternion.copy (this.object.quaternion );
		}
	};

	this.reset = function () {
		state = STATE.NONE;
		this.target.copy( this.target0 );
		this.object.position.copy( this.position0 );
		this.update();
	};

	function getAutoRotationAngle() {
		return 2 * Math.PI / 60 / 60 * scope.autoRotateSpeed;
	}

	function getZoomScale() {
		return Math.pow( 0.95, scope.zoomSpeed );
	}

	function onMouseDown( event ) {
		if ( scope.enabled === false ) return;
		event.preventDefault();
		if (scope.mode) { // Orbital Controls
			if ( event.button === 0 ) { // left mouse button
				if ( scope.noRotate === true ) return;
				state = STATE.ROTATE;
				rotateStart.set( event.clientX, event.clientY );
			} else if ( event.button === 1 ) { // middle mouse button
				if ( scope.noZoom === true ) return;
				state = STATE.DOLLY;
				dollyStart.set( event.clientX, event.clientY );
			} else if ( event.button === 2 ) { // right mouse button
				if ( scope.noPan === true ) return;
				state = STATE.PAN;
				panStart.set( event.clientX, event.clientY );
			}
		} else { // Fly Controls
			mousefly = true;
			state = STATE.FLY
			if ( event.button === 0 ) { // left mouse button
				moveVector.z = -1;
			} else if ( event.button === 2 ) { // right mouse button
				moveVector.z = 1;
			}
		}
		if ( state !== STATE.NONE ) {
			document.addEventListener( 'mouseup', onMouseUp, false );
			scope.dispatchEvent( startEvent );
		}
	}

	function onMouseMove( event ) {
		if ( scope.enabled === false ) return;
		event.preventDefault();
		var element = scope.domElement === document ? scope.domElement.body : scope.domElement;
		if ( state === STATE.ROTATE ) {
			if ( scope.noRotate === true ) return;
			rotateEnd.set( event.clientX, event.clientY );
			rotateDelta.subVectors( rotateEnd, rotateStart );
			scope.rotateLeft( 2 * Math.PI * rotateDelta.x / element.clientWidth * scope.rotateSpeed ); // rotating across whole screen goes 360 degrees around
			// rotating up and down along whole screen attempts to go 360, but limited to 180
			scope.rotateUp( 2 * Math.PI * rotateDelta.y / element.clientHeight * scope.rotateSpeed );
			rotateStart.copy( rotateEnd );
		} else if ( state === STATE.DOLLY ) {
			if ( scope.noZoom === true ) return;
			dollyEnd.set( event.clientX, event.clientY );
			dollyDelta.subVectors( dollyEnd, dollyStart );
			if ( dollyDelta.y > 0 ) {
				scope.dollyIn();
			} else {
				scope.dollyOut();
			}
			dollyStart.copy( dollyEnd );
		} else if ( state === STATE.PAN ) {
			if ( scope.noPan === true ) return;
			panEnd.set( event.clientX, event.clientY );
			panDelta.subVectors( panEnd, panStart );
			scope.pan( panDelta.x, panDelta.y );
			panStart.copy( panEnd );
		} else if ( mousefly ) {
			var w = scope.domElement.clientWidth / 2;
			var h = scope.domElement.clientHeight / 2;
			rotationVector.y = - ( event.clientX - w  ) / w
			rotationVector.x = - ( event.clientY - h  ) / h
		}
		if ( state !== STATE.NONE && scope.mode ) {
			scope.update();
		}
	}

	function onMouseUp( /* event */ ) {
		if ( scope.enabled === false ) return;
		moveVector.z = 0;
		document.removeEventListener( 'mouseup', onMouseUp, false );
		scope.dispatchEvent( endEvent );
		state = STATE.NONE;
	}

	function onMouseWheel( event ) {
		if ( scope.enabled === false || scope.noZoom === true || state !== STATE.NONE || scope.mode == false ) return;
		event.preventDefault();
		event.stopPropagation();
		var delta = 0;
		if ( event.wheelDelta !== undefined ) { // WebKit / Opera / Explorer 9
			delta = event.wheelDelta;
		} else if ( event.detail !== undefined ) { // Firefox
			delta = - event.detail;
		}
		if ( delta > 0 ) {
			scope.dollyOut();
		} else {
			scope.dollyIn();
		}
		scope.update();
		scope.dispatchEvent( startEvent );
		scope.dispatchEvent( endEvent );
	}

	function onKeyDown( event ) {
		if ( scope.enabled === false || scope.noKeys === true) return;
		if ( scope.mode ) { // Orbital Controls
			if (scope.noRotate == false) {
				switch ( event.keyCode ) {
					case 87: // W
						scope.rotateUp( -0.05 ); scope.update(); break;
					case 65: // A
						scope.rotateLeft( -0.05 ); scope.update(); break;
					case 83: // S
						scope.rotateUp( 0.05 ); scope.update(); break;
					case 68: // D
						scope.rotateLeft( 0.05 ); scope.update(); break;
				}
			}
			if (scope.noZoom == false) {
				switch ( event.keyCode ) {
					case 81: // Q
						scope.dollyIn(); scope.update(); break;
					case 69: // E
						scope.dollyOut(); scope.update(); break;
				}
			}
			if (scope.noPan == false) {
				switch ( event.keyCode ) {
					case 38: // up arrow key
						scope.pan( 0, 7.0 ); scope.update(); break;
					case 40: // down arrow key
						scope.pan( 0, -7.0 ); scope.update(); break;
					case 37: // left arrow key
						scope.pan( 7.0, 0 ); scope.update(); break;
					case 39: // right arrow key
						scope.pan( -7.0, 0 ); scope.update(); break;
				}
			}
		} else { // Fly Controls
			switch ( event.keyCode ) {
				case 87: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} moveVector.z = -1; break; // W
				case 83: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} moveVector.z = 1; break; // S
				case 65: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} moveVector.x = -1; break; // A
				case 68: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} moveVector.x = 1; break; // D
				case 82: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} moveVector.y = 1; break; // R
				case 70: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} moveVector.y = -1; break; // F
				case 38: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} rotationVector.x = -1; break; // up arrow key
				case 40: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} rotationVector.x = 1; break; // down arrow key
				case 37: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} rotationVector.y = 1; break; // left arrow key
				case 39: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} rotationVector.y = -1; break; // right arrow key
				case 81: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} rotationVector.z = 1; break; // Q
				case 69: if (mousefly){rotationVector.set(0,0,0); mousefly = false;} rotationVector.z = -1; break; // E
			}
		}
	}

	function onKeyUp( event ) {
		if ( scope.enabled === false || scope.noKeys === true) return;
		if ( !scope.mode ) { // Fly Controls
			switch ( event.keyCode ) {
				case 87: moveVector.z = 0; break; // W
				case 83: moveVector.z = 0; break; // S
				case 65: moveVector.x = 0; break; // A
				case 68: moveVector.x = 0; break; // D
				case 82: moveVector.y = 0; break; // R
				case 70: moveVector.y = 0; break; // F
				case 38: rotationVector.x = 0; break; // up arrow key
				case 40: rotationVector.x = 0; break; // down arrow key
				case 37: rotationVector.y = 0; break; // left arrow key
				case 39: rotationVector.y = 0; break; // right arrow key
				case 81: rotationVector.z = 0; break; // Q
				case 69: rotationVector.z = 0; break; // E
			}
		}
	}

	function touchstart( event ) {
		if ( scope.enabled === false || scope.mode == false ) return;
		switch ( event.touches.length ) {
			case 1:	// one-fingered touch: rotate
				if ( scope.noRotate === true ) return;
				state = STATE.TOUCH_ROTATE;
				rotateStart.set( event.touches[ 0 ].pageX, event.touches[ 0 ].pageY );
				break;
			case 2:	// two-fingered touch: dolly
				if ( scope.noZoom === true ) return;
				state = STATE.TOUCH_DOLLY;
				var dx = event.touches[ 0 ].pageX - event.touches[ 1 ].pageX;
				var dy = event.touches[ 0 ].pageY - event.touches[ 1 ].pageY;
				var distance = Math.sqrt( dx * dx + dy * dy );
				dollyStart.set( 0, distance );
				break;
			case 3: // three-fingered touch: pan
				if ( scope.noPan === true ) return;
				state = STATE.TOUCH_PAN;
				panStart.set( event.touches[ 0 ].pageX, event.touches[ 0 ].pageY );
				break;
			default:
				state = STATE.NONE;
		}
		if ( state !== STATE.NONE ) scope.dispatchEvent( startEvent );
	}

	function touchmove( event ) {
		if ( scope.enabled === false || scope.mode == false ) return;
		event.preventDefault();
		event.stopPropagation();
		var element = scope.domElement === document ? scope.domElement.body : scope.domElement;
		switch ( event.touches.length ) {
			case 1: // one-fingered touch: rotate
				if ( scope.noRotate === true ) return;
				if ( state !== STATE.TOUCH_ROTATE ) return;
				rotateEnd.set( event.touches[ 0 ].pageX, event.touches[ 0 ].pageY );
				rotateDelta.subVectors( rotateEnd, rotateStart );
				scope.rotateLeft( 2 * Math.PI * rotateDelta.x / element.clientWidth * scope.rotateSpeed ); // rotating across whole screen goes 360 degrees around
				// rotating up and down along whole screen attempts to go 360, but limited to 180
				scope.rotateUp( 2 * Math.PI * rotateDelta.y / element.clientHeight * scope.rotateSpeed );
				rotateStart.copy( rotateEnd );
				scope.update();
				break;
			case 2: // two-fingered touch: dolly
				if ( scope.noZoom === true ) return;
				if ( state !== STATE.TOUCH_DOLLY ) return;
				var dx = event.touches[ 0 ].pageX - event.touches[ 1 ].pageX;
				var dy = event.touches[ 0 ].pageY - event.touches[ 1 ].pageY;
				var distance = Math.sqrt( dx * dx + dy * dy );
				dollyEnd.set( 0, distance );
				dollyDelta.subVectors( dollyEnd, dollyStart );
				if ( dollyDelta.y > 0 ) {
					scope.dollyOut();
				} else {
					scope.dollyIn();
				}
				dollyStart.copy( dollyEnd );
				scope.update();
				break;
			case 3: // three-fingered touch: pan
				if ( scope.noPan === true ) return;
				if ( state !== STATE.TOUCH_PAN ) return;
				panEnd.set( event.touches[ 0 ].pageX, event.touches[ 0 ].pageY );
				panDelta.subVectors( panEnd, panStart );
				scope.pan( panDelta.x, panDelta.y );
				panStart.copy( panEnd );
				scope.update();
				break;
			default:
				state = STATE.NONE;
		}
	}

	function touchend( ) {
		if ( scope.enabled === false || scope.mode == false ) return;
		scope.dispatchEvent( endEvent );
		state = STATE.NONE;
	}

	this.domElement.addEventListener( 'contextmenu', function ( event ) { event.preventDefault(); }, false );
	this.domElement.addEventListener( 'mousedown', onMouseDown, false );
	document.addEventListener( 'mousemove', onMouseMove, false );
	this.domElement.addEventListener( 'mousewheel', onMouseWheel, false );
	this.domElement.addEventListener( 'DOMMouseScroll', onMouseWheel, false ); // firefox
	this.domElement.addEventListener( 'touchstart', touchstart, false );
	this.domElement.addEventListener( 'touchend', touchend, false );
	this.domElement.addEventListener( 'touchmove', touchmove, false );
	window.addEventListener( 'keydown', onKeyDown, false );
	window.addEventListener( 'keyup', onKeyUp, false );
	this.object.lookAt(this.target);
	this.update(); // force an update at start
};

THREE.MixedControls.prototype = Object.create( THREE.EventDispatcher.prototype );
THREE.MixedControls.prototype.constructor = THREE.MixedControls;
