package controllers

import play.api.libs.json.Json._
import play.api.libs.json._
import oxalis.security.Secured
import models.security.{RoleDAO, Role}
import play.api.Logger
import models.user._
import models.task._
import views._
import play.api.libs.concurrent._
import play.api.libs.concurrent.Execution.Implicits._
import play.api.i18n.Messages
import models.annotation.{AnnotationService, AnnotationDAO, AnnotationType}
import play.api.Play.current
import models.tracing.skeleton.SkeletonTracing
import scala.concurrent.Future

object TaskController extends Controller with Secured {
  override val DefaultAccessRole = RoleDAO.User
  
  val MAX_OPEN_TASKS = current.configuration.getInt("oxalis.tasks.maxOpenPerUser") getOrElse 5

  def request = Authenticated().async{ implicit request =>
    val user = request.user
    if (AnnotationService.countOpenTasks(request.user) < MAX_OPEN_TASKS) {
      TaskService.nextTaskForUser(request.user).flatMap {
        case Some(task) =>
          for {
            annotation <- AnnotationService.createAnnotationFor(user, task) ?~> Messages("annotation.creationFailed")
          } yield {
            JsonOk(html.user.dashboard.taskAnnotationTableItem(task, annotation), Messages("task.assigned"))
          }
        case _ =>
          for {
            task <- Training.findAssignableFor(user).map(_.headOption) ?~> Messages("task.unavailable")
            annotation <- AnnotationService.createAnnotationFor(user, task) ?~> Messages("annotation.creationFailed")
          } yield {
            JsonOk(html.user.dashboard.taskAnnotationTableItem(task, annotation), Messages("task.training.assigned"))
          }
      }
    } else{
      Future.successful(JsonBadRequest(Messages("task.tooManyOpenOnes")))
    }
  }
}