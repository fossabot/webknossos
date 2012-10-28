### define
libs/request : Request
###

# This takes care of the userdate. 
User = {}

# Debounce for POST User.Configuration
DEBOUNCE_TIME = 3000

User.Configuration = 

  # userdata
  # default values are defined in server
  moveValue : null
  rotateValue : null
  scaleValue : null
  mouseRotateValue : null
  routeClippingDistance : null
  lockZoom : null
  displayCrosshair : null
  interpolation : null
  minZoomStep : null
  zoomXY : null
  zoomYZ : null
  zoomXZ : null
  displayPreviewXY : null
  displayPreviewYZ : null
  displayPreviewXZ : null
  newNodeNewTree : null
  nodesAsSpheres : null
  mouseInversionX : null
  mouseInversionY : null
  mouseActive : null
  keyboardActive : null
  gamepadActive : null
  motionsensorActive : null


  initialize : ->
    unless @configDeferred
      @push =  _.debounce @pushImpl, DEBOUNCE_TIME      
      @configDeferred = $.Deferred()

      @configDeferred.fail =>
        @configDeferred = null

      Request.send(url : '/user/configuration').then( 
        
        (data) =>
          try
            data = JSON.parse data
            { @moveValue, 
              @rotateValue, 
              @scaleValue, 
              @mouseRotateValue, 
              @routeClippingDistance, 
              @lockZoom,
              @displayCrosshair,
              @interpolation,
              @minZoomStep,
              @zoomXY,
              @zoomYZ,
              @zoomXZ,
              @displayPreviewXY,
              @displayPreviewYZ,
              @displayPreviewXZ,
              @newNodeNewTree,
              @nodesAsSpheres,
              @mouseInversionX,
              @mouseInversionY,
              @mouseActive, 
              @keyboardActive,
              @gamepadActive,
              @motionsensorActive } = data

          catch ex
            @configDeferred.reject(ex)
          
          @configDeferred.resolve(data)

        (err) =>
          @configDeferred.reject(err)
      )
    
      @configDeferred.promise()

  push : null

  pushImpl : ->
    deferred = $.Deferred()
      
    request(
      url    : "/user/configuration"
      method : 'POST'
      contentType : "application/json"
      data   : { 
        moveValue : @moveValue,
        rotateValue : @rotateValue,
        scaleValue : @scaleValue,
        mouseRotateValue : @mouseRotateValue,
        routeClippingDistance : @routeClippingDistance,
        lockZoom : @lockZoom,
        displayCrosshair : @displayCrosshair,
        interpolation : @interpolation,
        minZoomStep : @minZoomStep,
        zoomXY : @zoomXY,
        zoomYZ : @zoomYZ,
        zoomXZ : @zoomXZ,
        displayPreviewXY : @displayPreviewXY,
        displayPreviewYZ : @displayPreviewYZ,
        displayPreviewXZ : @displayPreviewXZ,
        newNodeNewTree : @newNodeNewTree,
        nodesAsSpheres : @nodesAsSpheres,
        mouseInversionX : @mouseInversionX,
        mouseInversionY : @mouseInversionY,
        mouseActive : @mouseActive,
        keyboardActive : @keyboardActive,
        gamepadActive : @gamepadActive,
        motionsensorActive : @motionsensorActive }
    ).fail( =>
      
      console.log "could'nt save userdata"

    ).always(-> deferred.resolve())
    
    deferred.promise()    

User
