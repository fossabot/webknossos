package brainflight.binary

import brainflight.tools.geometry.Point3D
import models.binary.DataSet
import brainflight.tools.geometry.Cuboid
import play.api.libs.concurrent.Promise
import play.api.libs.concurrent.execution.defaultContext
import brainflight.tools.geometry.Vector3D

/**
 * Abstract Datastore defines all method a binary data source (e.q. normal file
 * system or db implementation) must implement to be used
 */
abstract class DataStore {
  /**
   * Loads the data of a given point from the data source
   */
  def load( dataSet: DataSet, resolution: Int, point: Point3D ): Promise[Byte]

  def load( dataSet: DataSet, resolution: Int, cube: Cuboid, halfByte: Boolean = false): Promise[Array[Byte]]

  def loadInterpolated( dataSet: DataSet, resolution: Int, points: Array[Vector3D] ): Promise[Array[Byte]]
  
  /**
   * Gives the data store the possibility to clean up its mess on shutdown/clean
   */
  def cleanUp()
  
  /**
   * Creates the file-name of the cube based on the data set id, resolution
   * and coordinates.
   * 
   * Example:
   *  "binaryData/100527_k0563/1/x0001/y0002/z0004/100527_k0563_mag1_x0001_y0002_z0004.raw"
   *  
   * The path structure is:
   *  "DATAPATH/DATASETID/RESOLUTION/.../DATASETID_magRESOLUTION_xX_yY_zZ.raw"
   *  
   *  where DATAPATH, DATASETID, RESOLUTION, X, Y and Z are parameters.
   */
  def createFilename( dataSet: DataSet, resolution: Int, point: Point3D ) =
    "%s/%d/x%04d/y%04d/z%04d/%s_mag%d_x%04d_y%04d_z%04d.raw".format( 
        dataSet.baseDir,
        resolution, 
        point.x, point.y, point.z, 
        dataSet.name, 
        resolution, 
        point.x, point.y, point.z )
}