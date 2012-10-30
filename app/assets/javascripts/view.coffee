### define
libs/flycam : Flycam
libs/flycam2 : Flycam2d
libs/Tween : TWEEN_LIB
model/game : Game
libs/event_mixin : EventMixin
model/route : Route
###

#model : Model
    
# global View variables
# flycam = null

# constants
# display 512px out of 512px total width and height
#CAM_DISTANCE = 384/2 # alt: 384/2  #alt: 96
VIEWPORT_WIDTH = 380
PLANE_XY = 0
PLANE_YZ = 1
PLANE_XZ = 2
VIEW_3D  = 3

class View

  constructor : (model, flycam) ->

    _.extend(this, new EventMixin())

    @model  = model
    @flycam = flycam

    # The "render" div serves as a container for the canvas, that is 
    # attached to it once a renderer has been initalized.
    container = $("#render")
    # Create a 4x4 grid
    @curWidth = WIDTH = (container.width()-20)/2
    HEIGHT = (container.height()-20)/2
    @scaleFactor = 1

    # Initialize main THREE.js components
    colors    = [0xff0000, 0x0000ff, 0x00ff00, 0xffffff]
    @renderer = new THREE.WebGLRenderer({clearColor: colors[i], clearAlpha: 1, antialias: false})
    @camera   = new Array(4)
    @lights   = new Array(3)
    @scene    = new THREE.Scene()
    for i in [PLANE_XY, PLANE_YZ, PLANE_XZ, VIEW_3D]
      # Let's set up cameras
      # No need to set any properties, because the camera controller will deal with that
      @camera[i]   = new THREE.OrthographicCamera(0, 0, 0, 0)
      @scene.add @camera[i]

      # There is one light for each plane
      if i != VIEW_3D
        @lights[i]   = new THREE.PointLight( 0xffffff, 0.8 )
        @scene.add @lights[i]

    @camera[PLANE_XY].position.z = -1
    @camera[PLANE_YZ].position.x =  1
    @camera[PLANE_XZ].position.y =  1
    @camera[VIEW_3D].position    = new THREE.Vector3(10, 10, -10)
    @camera[PLANE_XY].up         = new THREE.Vector3( 0, -1,  0)
    @camera[PLANE_YZ].up         = new THREE.Vector3( 0, -1,  0)
    @camera[PLANE_XZ].up         = new THREE.Vector3( 0,  0, -1)
    @camera[VIEW_3D].up          = new THREE.Vector3( 0,  0, -1)
    for cam in @camera
      cam.lookAt(new THREE.Vector3( 0, 0, 0))

    # Because the voxel coordinates do not have a cube shape but are distorted,
    # we need to distort the entire scene to provide an illustration that is
    # proportional to the actual size in nm.
    # For some reason, all objects have to be put into a group object. Changing
    # scene.scale does not have an effect.
    @group = new THREE.Object3D
    rScale = @model.Route.data.experiment.scale
    rMin   = Math.min.apply(null, rScale)
    # The dimension(s) with the highest resolution will not be distorted
    @group.scale = new THREE.Vector3(rScale[0] / rMin, rScale[1] / rMin, rScale[2] / rMin)
    # Add scene to the group, all Geometries are than added to group
    @scene.add(@group)

    # Attach the canvas to the container
    @renderer.setSize 2*WIDTH+20, 2*HEIGHT+20
    container.append @renderer.domElement

    @setActivePlaneXY()
    
    # FPS stats
    stats = new Stats()
    stats.getDomElement().id = "stats"
    $("body").append stats.getDomElement() 
    @stats = stats
    @positionStats = $("#status")

    @first = true
    @newTextures = [true, true, true, true]
    # start the rendering loop
    @animate()

    # Dont forget to handle window resizing!
    $(window).resize( => @.resize() )
    
    # refresh the scene once a bucket is loaded
    # FIXME: probably not the most elgant thing to do
    # FIXME: notifies all planes when any bucket is loaded
    # $(window).on("bucketloaded", => @flycam.hasChanged = true; @flycam.newBuckets = [true, true, true]) 

  animate : ->

    @renderFunction()

    window.requestAnimationFrame => @animate()

  # This is the main render function.
  # All 3D meshes and the trianglesplane are rendered here.
  renderFunction : ->

    TWEEN.update()

    @trigger "render"

    # skip rendering if nothing has changed
    # This prevents you the GPU/CPU from constantly
    # working and keeps your lap cool
    # ATTENTION: this limits the FPS to 30 FPS (depending on the keypress update frequence)
    
    # update postion and FPS displays
    position2d = @flycam.getGlobalPos()
    texturePositionXY = @flycam.texturePosition[0]
    # without rounding the position becomes really long and blocks the canvas mouse input
    position2d = [Math.round(position2d[0]),Math.round(position2d[1]),Math.round(position2d[2])]
    texturePositionXY = [Math.round(texturePositionXY[0]),Math.round(texturePositionXY[1]),Math.round(texturePositionXY[2])]
    #@positionStats.html "Flyflycam: #{position2d}<br />texturePositionXY: #{texturePositionXY}<br />ZoomStep #{@flycam.getIntegerZoomStep(@flycam.getActivePlane())}<br />activePlane: #{@flycam.getActivePlane()}" 
    @stats.update()

    @newTextures[VIEW_3D] = @newTextures[0] or @newTextures[1] or @newTextures[2]
    viewport = [[0, @curWidth+20], [@curWidth+20, @curWidth+20], [0, 0], [@curWidth+20, 0]]
    @renderer.autoClear = true
    colors   = [ 0xff0000, 0x0000ff, 0x00ff00, 0xffffff]
    if @flycam.hasChanged or @flycam.hasNewTextures()
      for i in [PLANE_XY, PLANE_YZ, PLANE_XZ, VIEW_3D]
        @trigger "renderCam", i
        @renderer.setViewport(viewport[i][0], viewport[i][1], @curWidth, @curWidth)
        @renderer.setScissor(viewport[i][0], viewport[i][1], @curWidth, @curWidth)
        @renderer.enableScissorTest(true)
        @renderer.setClearColorHex(colors[i], 1);
        @renderer.render @scene, @camera[i]
    @flycam.hasChanged = false
    @flycam.hasNewTexture = [false, false, false]
  
  # Adds a new Three.js geometry to the scene.
  # This provides the public interface to the GeometryFactory.
  addGeometry : (geometry) ->
    @group.add geometry

  removeGeometry : (geometry) ->
    @group.remove geometry

  #Apply a single draw (not used right now)
  draw : ->
    #FIXME: this is dirty
    @flycam.hasChanged = true

  #Call this after the canvas was resized to fix the viewport
  resize : ->
    #FIXME: Is really the window's width or rather the DIV's?
    container = $("#render")
    WIDTH = (container.width()-20)/2
    HEIGHT = (container.height()-20)/2

    @renderer.setSize( 2*WIDTH+20, 2*HEIGHT+20)
    for i in [PLANE_XY, PLANE_YZ, PLANE_XZ, VIEW_3D]
      @camera[i].aspect = WIDTH / HEIGHT
      @camera[i].updateProjectionMatrix()
    @draw()
  
  scaleTrianglesPlane : (delta) =>
    @scaleFactor = 1 unless @scaleFactor
    if (@scaleFactor+delta > 0.75) and (@scaleFactor+delta < 1.5)
      @scaleFactor += Number(delta)
      @curWidth = WIDTH = HEIGHT = @scaleFactor * 384
      container = $("#render")
      container.width(2 * WIDTH + 20)
      container.height(2 * HEIGHT + 20)

      divs = $(".inputcatcher")
      for div in divs
        $(div).width(WIDTH)
        $(div).height(HEIGHT)

      divYZ = $("#planeyz")
      divYZ.css({left: @scaleFactor * 384 + 20 + "px"})
      divXZ = $("#planexz")
      divXZ.css({top: @scaleFactor * 384 + 20 + "px"})
      divSkeleton = $("#skeletonview")
      divSkeleton.css({left: @scaleFactor * 384 + 20 + "px", top: @scaleFactor * 384 + 20 + "px"})

      # scales the 3D-view controls
      prevControl = $("#prevControls")
      prevControl.css({top: @scaleFactor * 440 + "px", left: @scaleFactor * 420 + "px"})

      @resize()

  setActivePlaneXY : =>
    @setActivePlane PLANE_XY

  setActivePlaneYZ : =>
    @setActivePlane PLANE_YZ

  setActivePlaneXZ : =>
    @setActivePlane PLANE_XZ

  setActivePlane : (planeID) =>
    @flycam.setActivePlane planeID
    for i in [0..2]
      catcherStyle = $(".inputcatcher")[i].style
      #catcherStyle.borderColor  = "#f8f800"   #  else "#C7D1D8"
      $(".inputcatcher")[i].style.borderWidth = if i==planeID then "2px" else "0px"

  getCameras : =>
    @camera

  getLights  : =>
    @lights
