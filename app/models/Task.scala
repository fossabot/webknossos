package models

import com.mongodb.casbah.Imports._
import models.context._
import com.novus.salat.annotations._
import com.novus.salat.dao.SalatDAO
import models.basics.BasicDAO
import java.util.Date
import brainflight.tools.geometry.Point3D
import models.graph.Experiment
import play.api.libs.concurrent.Akka
import play.api.Play.current
import akka.actor.Props
import akka.pattern.ask
import brainflight.js.JsExecutionActor
import brainflight.js.JS
import akka.util.Timeout
import akka.util.duration._
import akka.pattern.AskTimeoutException
import org.bson.types.ObjectId
import akka.dispatch.Future
import play.api.libs.concurrent.execution.defaultContext
import akka.dispatch.Promise
import play.api.libs.json.Format
import play.api.libs.json.Json
import play.api.libs.json.Writes

case class Task(
    dataSetName: String,
    cellId: Int,
    seedIdHeidelberg: Int,
    taskType: ObjectId,
    //requiredPermission: Int,
    start: Point3D,
    priority: Int = 100,
    instances: Int = 1,
    created: Date = new Date,
    experiments: List[Experiment] = Nil,
    _id: ObjectId = new ObjectId) {
  def id = _id.toString
}

object Task extends BasicDAO[Task]("tasks") {
  val jsExecutionActor = Akka.system.actorOf(Props[JsExecutionActor])
  val conf = current.configuration
  implicit val timeout = Timeout((conf.getInt("js.defaultTimeout") getOrElse 5) seconds) // needed for `?` below

  def fromForm(experiment: String, priority: Int, instances: Int, taskTypeId: String) = 
    Experiment.findOneById(experiment).flatMap(e => TaskType.findOneById(taskTypeId).map( taskType =>
    Task(e.dataSetName,
        0,
        0,
        taskType._id,
        e.editPosition,
        priority,
        instances)))
  
  def toForm(t: Option[Task]): Option[(String, Int, Int, String)] = 
    None
  
  def nextTaskIdForUser(user: User): Future[Option[Int]] = {
    val tasks = Task.findAll.toArray
    if (tasks.isEmpty) {
      Promise.successful(None)(Akka.system.dispatcher)
    } else {
      val params = Map("user" -> user, "tasks" -> tasks)

      val future = (jsExecutionActor ? JS(TaskSelectionAlgorithm.current.js, params)) recover {
        case e: AskTimeoutException =>
          ""
      }
      future.mapTo[Int].map(x => Some(x))
    }
  }

  implicit object TaskFormat extends Writes[Task] {
    val TASK_ID = "taskId"
    val CELL_ID = "cellId"
    val START = "start"
    val PRIORITY = "priority"
    val CREATED = "created"

    def writes(e: Task) = Json.obj(
      TASK_ID -> e.id,
      CELL_ID -> e.cellId,
      START -> e.start,
      PRIORITY -> e.priority)
  }
}