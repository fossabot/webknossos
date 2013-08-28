package braingames.geometry

case class TransformationMatrix(value: Array[Float]) {
  val width = math.sqrt(TransformationMatrix.defaultSize).toInt
  val height = width

  /**
   * Extract the translation from the transformation matrix
   */
  def extractTranslation: Option[Vector3D] =
    value match {
      case matrix if matrix.size >= TransformationMatrix.defaultSize =>
        Some(new Vector3D(matrix(12), matrix(13), matrix(14)))
      case _ =>
        None
    }
}

object TransformationMatrix {
  val defaultSize = 16

  def identity =
    TransformationMatrix(Array[Float](
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1))
  
  def apply(pos: Vector3D, direction: Vector3D): TransformationMatrix = {

    val nz = direction.normalize
    val x = Vector3D(1, 0, 0)
    val nx = (x - nz * (nz ° x)).normalize
    val y = Vector3D(0, 1, 0)
    val ny = (y - nz * (nz ° y) - nx * (nx ° y)).normalize

    TransformationMatrix(Array(nx.x, nx.y, nx.z, 0, ny.x, ny.y, ny.z, 0, nz.x, nz.y, nz.z, 0, pos.x, pos.y, pos.z, 1).map(_.toFloat))
  }
}