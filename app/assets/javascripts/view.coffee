### define
libs/gl_engine/flycam : Flycam
model : Model
###
    

cam = null

lastMatrix = null

standardModelViewMatrix = null      

#constants
CLIPPING_DISTANCE = 140
CAM_DISTANCE = 140
BACKGROUND_COLOR = [0.9, 0.9 ,0.9 ,1]

camHasChanged = ->
    return true if lastMatrix is null           
    currentMatrix = cam.getMatrix()
    for i in [0..15]
        return true if lastMatrix[i] isnt currentMatrix[i]
    return false
    

View =
    initialize : (canvas) ->

        helperMatrix = [ 
            1, 0, 0, 0, 
            0, 1, 0, 0, 
            0, 0, 1, 0, 
            0, 0, 0, 1 
        ]

        standardModelViewMatrix = M4x4.makeLookAt [ 
            helperMatrix[12], helperMatrix[13], helperMatrix[14]],
            V3.add([ 
                helperMatrix[8], helperMatrix[9], helperMatrix[10] ], 
                [helperMatrix[12], helperMatrix[13], helperMatrix[14]]),
            [helperMatrix[4], helperMatrix[5], helperMatrix[6]]

        container = $("#render")
        WIDTH = container.width()
        HEIGHT = container.height()


        @renderer = new THREE.WebGLRenderer({ clearColor: 0xffffff, antialias: true })
        @camera = new THREE.PerspectiveCamera(90, WIDTH / HEIGHT, 0.1, 10000)
        @scene = new THREE.Scene()
        
        @scene.add(@camera)

        @camera.position.z = CAM_DISTANCE
        @camera.lookAt(new THREE.Vector3( 0, 0, 0 ))
        @cameraControll = new THREE.TrackballControls(@camera)

        @renderer.setSize(WIDTH, HEIGHT)
        container.append(@renderer.domElement)

        cam = new Flycam CAM_DISTANCE

        #FPS stats
        stats = new Stats()
        stats.getDomElement().style.position = 'absolute'
        stats.getDomElement().style.left = '0px'
        stats.getDomElement().style.top = '0px'
        $("body").append stats.getDomElement() 
        @stats = stats

        # unless @trianglesplane
        #   @trianglesplane = GeometryFactory.createTrianglesplane(128, 0)
        #   @addGeometry @trianglesplane

        @animate()

        # #resizes canvas correctly
        # _canvas = $("#render")

        # cvs.resize = =>
        #   cvs.height = _canvas.height()
        #   cvs.width = _canvas.width()
        #   View.resize()
        #   View.draw()
        #   return

        # $(window).resize( =>
        #   cvs.resize()
        #   return
        # )

        # $(window).resize()
        # $(window).on("bucketloaded", View.draw) 

    animate : ->
        @renderFunction()

        window.requestAnimationFrame => @animate()

    renderFunction : (forced) ->

        @cameraControll.update()

        #skipping rendering if nothing has changed
        currentMatrix = cam.getMatrix()
        if forced is false
                if camHasChanged() is false
                    return

        @updateTrianglesplane()

        # MAth.floor WAT?
        # DOM element selection WAT?
        #performance WAT?
        position = cam.getGlobalPos()
        p = [Math.floor(position[0]), Math.floor(position[1]), Math.floor(position[2])]
        $("#status").html "#{p}<br />ZoomStep #{cam.getZoomStep()}<br />" 

        lastMatrix = currentMatrix
        @renderer.render @scene, @camera
        @stats.update()

    updateTrianglesplane : ->
        return unless @trianglesplane
        g = @trianglesplane

        transMatrix = cam.getMatrix()
        newVertices = M4x4.transformPointsAffine transMatrix, @trianglesplane.queryVertices
        
        #sets the original vertices to trianglesplane
        # unless g.vertices.VBO?
        #   g.setVertices (View.createArrayBufferObject g.normalVertices), g.normalVertices.length

        globalMatrix = cam.getGlobalMatrix()
        #sends current position to Model for preloading data
        Model.Binary.ping transMatrix, cam.getZoomStep() #.done(View.draw).progress(View.draw)

        #sends current position to Model for caching route
        Model.Route.put globalMatrix

        Model.Binary.get(newVertices, cam.getZoomStep()).done ({ buffer0, buffer1, bufferDelta }) ->
            # ATTENTION 
            # when playing around with texture please look at setTexture() (line 5752 in WebGLRenderer)
            # the data attribute is only available for DataTexture (in other cases it is only texture.image)
            textureData = g.texture.image.data

            i = j = 0
            k = 1 << 14 # 128 * 128
            while --k

                index0 = j++
                index1 = j++
                index2 = j++
                index3 = j++

                bufferDelta0 = bufferDelta[i++]
                bufferDelta1 = bufferDelta[i++]
                bufferDelta2 = bufferDelta[i++]

                diff0 = 1.0 - bufferDelta0
                diff1 = 1.0 - bufferDelta1
                diff2 = 1.0 - bufferDelta2

                colorScalar =      
                buffer0[index0] * diff0         * diff1         * diff2 +
                buffer0[index1] * bufferDelta0  * diff1         * diff2 + 
                buffer0[index2] * diff0         * bufferDelta1  * diff2 + 
                buffer0[index3] * bufferDelta0  * bufferDelta1  * diff2 +
                buffer1[index0] * diff0         * diff1         * bufferDelta2 + 
                buffer1[index1] * bufferDelta0  * diff1         * bufferDelta2 + 
                buffer1[index2] * diff0         * bufferDelta1  * bufferDelta2 + 
                buffer1[index3] * bufferDelta0  * bufferDelta1  * bufferDelta2

                textureData[k] = colorScalar

            g.texture.needsUpdate = true
            g.material.map = g.texture


    addGeometry : (geometry) ->
        @scene.add geometry

    
    #Apply a single draw (not used right now)
    draw : ->
        @renderer.render @scene, @camera

    setMatrix : (matrix) ->
        cam.setMatrix(matrix)

    getMatrix : ->
        cam.getMatrix()

    #Call this after the canvas was resized to fix the viewport
    resize : ->
        #FIXME
        @renderer.setSize( window.innerWidth, window.innerHeight )
        @camera.aspect  = window.innerWidth / window.innerHeight
        @camera.updateProjectionMatrix()


############################################################################
#Interface for Controller
    yaw : (angle) ->
        cam.yaw angle

    yawDistance : (angle) ->
        cam.yawDistance angle

    roll : (angle) ->
        cam.roll angle

    rollDistance : (angle) ->
        cam.rollDistance angle

    pitch : (angle) ->
        cam.pitch angle

    pitchDistance : (angle) ->
        cam.pitchDistance angle

    move : (p) ->
        cam.move p

    scaleTrianglesPlane : (delta) ->
        if trianglesplane 
            x = Number(trianglesplane.scaleFactor.x) + Number(delta)
            if x > 0 and x < 2
                trianglesplane.scaleFactor.x = x
                @draw()

    zoomIn : ->
        if cam.getZoomStep() > 0
            cam.zoomIn()

    zoomOut : ->
        if cam.getZoomStep() < 3
            #todo: validation in Model
            cam.zoomOut()
