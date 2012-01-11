# This provides interpolation mechanics. It's a lot of code. But it
# should run fast.
Interpolation =
  BLACK : 1
  linear : (p0, p1, d) ->
    if p0 == 0 or p1 == 0
      @BLACK
    else
      p0 * (1 - d) + p1 * d
  
  bilinear : (p00, p10, p01, p11, d0, d1) ->
    if p00 == 0 or p10 == 0 or p01 == 0 or p11 == 0
      @BLACK
    else
      p00 * (1 - d0) * (1 - d1) + 
      p10 * d0 * (1 - d1) + 
      p01 * (1 - d0) * d1 + 
      p11 * d0 * d1
    
  trilinear : (p000, p100, p010, p110, p001, p101, p011, p111, d0, d1, d2) ->
    if p000 == 0 or p100 == 0 or p010 == 0 or p110 == 0 or p001 == 0 or p101 == 0 or p011 == 0 or p111 == 0
      @BLACK
    else
      p000 * (1 - d0) * (1 - d1) * (1 - d2) +
      p100 * d0 * (1 - d1) * (1 - d2) + 
      p010 * (1 - d0) * d1 * (1 - d2) + 
      p110 * d0 * d1 * (1 - d2) +
      p001 * (1 - d0) * (1 - d1) * d2 + 
      p101 * d0 * (1 - d1) * d2 + 
      p011 * (1 - d0) * d1 * d2 + 
      p111 * d0 * d1 * d2

# Use this function to have your point interpolated. We'll figure
# out whether linear, bilinear or trilinear interpolation is best.
# But, you need to give us the `get` callback so we can find points
# in your data structure. Keep in mind that the `get` function
# probably loses its scope (hint: use `_.bind`)
interpolate = (x, y, z, get)->
  
  # Bitwise operations are faster than javascript's native rounding functions.
  x0 = x >> 0; x1 = x0 + 1; xd = x - x0     
  y0 = y >> 0; y1 = y0 + 1; yd = y - y0
  z0 = z >> 0; z1 = z0 + 1; zd = z - z0

  # return get(x0, y0, z0)

  if xd == 0
    if yd == 0
      if zd == 0
        get(x, y, z)
      else
        #linear z
        Interpolation.linear(get(x, y, z0), get(x, y, z1), zd)
    else
      if zd == 0
        #linear y
        Interpolation.linear(get(x, y0, z), get(x, y1, z), yd)
      else
        #bilinear y,z
        Interpolation.bilinear(
          get(x, y0, z0), 
          get(x, y1, z0), 
          get(x, y0, z1), 
          get(x, y1, z1), 
          yd, zd)
  else
    if yd == 0
      if zd == 0
        #linear x
        Interpolation.linear(get(x0, y, z), get(x1, y, z), xd)
      else
        #bilinear x,z
        Interpolation.bilinear(
          get(x0, y, z0), 
          get(x1, y, z0), 
          get(x0, y, z1), 
          get(x1, y, z1), 
          xd, zd)
    else
      if zd == 0
        #bilinear x,y
        Interpolation.bilinear(
          get(x0, y0, z), 
          get(x1, y0, z), 
          get(x0, y1, z), 
          get(x1, y1, z), 
          xd, yd)
      else
        #trilinear x,y,z
        Interpolation.trilinear(
          get(x0, y0, z0),
          get(x1, y0, z0),
          get(x0, y1, z0),
          get(x1, y1, z0),
          get(x0, y0, z1),
          get(x1, y0, z1),
          get(x0, y1, z1),
          get(x1, y1, z1),
          xd, yd, zd
        )

nextPoint = (x0, y0, z0, xd, yd, zd, _cube, bucketIndex000, pointIndex000, _size0, _size01) ->

  bucketIndex = bucketIndex000
  pointIndex  = pointIndex000
  
  if xd
    if x0 & 63 == 63
      bucketIndex++
      pointIndex &= -64
    else
      pointIndex++
  
  if yd
    if y0 & 4032 == 4032
      bucketIndex += _size0
      pointIndex &= -4033
    else
      pointIndex += 64

  if zd
    if zd & 258048 == 258048
      bucketIndex += _size01
      pointIndex &= -258049
    else
      pointIndex += 4096
  
  if (bucket = _cube[bucketIndex])?
    bucket[pointIndex]
  else
    -1

# pointIndex = 111111 111111 111111
#                 z      y      x
# return codes:
# -2 : negative coordinates
# -1 : bucket fault
# 0  : point fault
find2 = (x, y, z, interpolationFront, interpolationBack, interpolationOffset, j4, j3, _cube, _offset0, _offset1, _offset2, _size0, _size01) ->

  return interpolationFront[j4] = -2 if x < 0 or y < 0 or z < 0

  # Bitwise operations are faster than javascript's native rounding functions.
  x0 = x >> 0; xd = x - x0     
  y0 = y >> 0; yd = y - y0
  z0 = z >> 0; zd = z - z0

  bucketIndex000 = 
    ((x0 >> 6) - _offset0) + 
    ((y0 >> 6) - _offset1) * _size0 + 
    ((z0 >> 6) - _offset2) * _size01
  
  pointIndex000 = 
    ((x0 & 63)) +
    ((y0 & 63) << 6) +
    ((z0 & 63) << 12)
  
  output0 = nextPoint(x0, y0, z0, false, false, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
  return interpolationFront[j4] = output0 if output0 <= 0

  if xd == 0
    if yd == 0
      unless zd == 0
        #linear z
        output1 = nextPoint(x0, y0, z0, false, false, true, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output1 if output1 <= 0
    else
      if zd == 0
        #linear y
        output1 = nextPoint(x0, y0, z0, false, true, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output1 if output1 <= 0
      else
        #bilinear y,z
        output1 = nextPoint(x0, y0, z0, false, true, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output1 if output1 <= 0

        output2 = nextPoint(x0, y0, z0, false, false, true, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output2 if output2 <= 0

        output3 = nextPoint(x0, y0, z0, false, true, true,  _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output3 if output3 <= 0
  else
    if yd == 0
      if zd == 0
        #linear x
        output1 = nextPoint(x0, y0, z0, true, false, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output1 if output1 <= 0
      else
        #bilinear x,z
        output1 = nextPoint(x0, y0, z0, true, false, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output1 if output1 <= 0

        output2 = nextPoint(x0, y0, z0, false, false, true, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output2 if output2 <= 0

        output3 = nextPoint(x0, y0, z0, true, false, true,  _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output3 if output3 <= 0
    else
      if zd == 0
        #bilinear x,y
        output1 = nextPoint(x0, y0, z0, true, false, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output1 if output1 <= 0

        output2 = nextPoint(x0, y0, z0, false, true, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output2 if output2 <= 0

        output3 = nextPoint(x0, y0, z0, true, true, false,  _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output3 if output3 <= 0
      else
        #trilinear x,y,z
        output1 = nextPoint(x0, y0, z0, true, false, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output1 if output1 <= 0

        output2 = nextPoint(x0, y0, z0, false, true, false, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output2 if output2 <= 0

        output3 = nextPoint(x0, y0, z0, true, true, false,  _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output3 if output3 <= 0

        output4 = nextPoint(x0, y0, z0, false, false, true, _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output4 if output4 <= 0

        output5 = nextPoint(x0, y0, z0, true, false, true,  _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output5 if output5 <= 0

        output6 = nextPoint(x0, y0, z0, false, true, true,  _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output6 if output6 <= 0

        output7 = nextPoint(x0, y0, z0, true, true, true,   _cube, bucketIndex000, pointIndex000, _size0, _size01)
        return interpolationFront[j4] = output7 if output7 <= 0

  interpolationFront[j4]      = output0
  interpolationFront[j4 + 1]  = output1
  interpolationFront[j4 + 2]  = output2
  interpolationFront[j4 + 3]  = output3
  interpolationBack[j4]       = output4
  interpolationBack[j4 + 1]   = output5
  interpolationBack[j4 + 2]   = output6
  interpolationBack[j4 + 3]   = output7
  interpolationOffset[j3 + 0] = xd
  interpolationOffset[j3 + 1] = yd
  interpolationOffset[j3 + 2] = zd
