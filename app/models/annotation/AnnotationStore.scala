package models.annotation

import com.scalableminds.util.accesscontext.DBAccessContext
import com.scalableminds.util.tools.Fox
import com.typesafe.scalalogging.LazyLogging
import javax.inject.Inject
import models.annotation.handler.AnnotationInformationHandlerSelector
import models.user.User
import net.liftweb.common.{Box, Empty, Failure, Full}
import play.api.libs.concurrent.Execution.Implicits._

import scala.concurrent.duration._

class AnnotationStore @Inject()(annotationInformationHandlerSelector: AnnotationInformationHandlerSelector) extends LazyLogging {

  private val cacheTimeout = 5 minutes

  case class StoredResult(result: Fox[Annotation], timestamp: Long = System.currentTimeMillis)

  def requestAnnotation(id: AnnotationIdentifier, user: Option[User])(implicit ctx: DBAccessContext) = {
    requestFromCache(id)
    .getOrElse(requestFromHandler(id, user))
    .futureBox
    .recover {
      case e =>
        logger.error("AnnotationStore ERROR: " + e)
        e.printStackTrace()
        Failure("AnnotationStore ERROR: " + e)
    }
  }

  private def requestFromCache(id: AnnotationIdentifier): Option[Fox[Annotation]] = {
    val handler = annotationInformationHandlerSelector.informationHandlers(id.annotationType)
    if (handler.cache) {
      val cached = getFromCache(id)
      cached
    } else
      None
  }

  private def requestFromHandler(id: AnnotationIdentifier, user: Option[User])(implicit ctx: DBAccessContext) = {
    val handler = annotationInformationHandlerSelector.informationHandlers(id.annotationType)
    for {
      annotation <- handler.provideAnnotation(id.identifier, user)
    } yield {
      if (handler.cache) {
        storeInCache(id, annotation)
      }
      annotation
    }
  }

  private def storeInCache(id: AnnotationIdentifier, annotation: Annotation) = {
    TemporaryAnnotationStore.insert(id.toUniqueString, annotation, Some(cacheTimeout))
  }

  private def getFromCache(annotationId: AnnotationIdentifier): Option[Fox[Annotation]] = {
    TemporaryAnnotationStore.find(annotationId.toUniqueString).map(Fox.successful(_))
  }

  def findCachedByTracingId(tracingId: String): Box[Annotation] = {
    val annotationOpt = TemporaryAnnotationStore.findAll.find(a => a.skeletonTracingId == Some(tracingId) || a.volumeTracingId == Some(tracingId))
    annotationOpt match {
      case Some(annotation) => Full(annotation)
      case None => Empty
    }
  }
}
