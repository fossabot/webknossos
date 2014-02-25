package controllers

import oxalis.security.Secured
import models.team.{TeamService, Team, TeamDAO}
import play.api.libs.json.{JsError, JsSuccess, Writes, Json}
import play.api.libs.concurrent.Execution.Implicits._
import models.user.User
import braingames.util.ExtendedTypes.ExtendedString
import scala.concurrent.Future
import play.api.i18n.Messages
import models.binary.DataSet
import net.liftweb.common.{Failure, Full}
import play.api.templates.Html

object TeamController extends Controller with Secured {

  def empty = Authenticated{ implicit request =>
    Ok(views.html.main()(Html.empty))
  }

  def isTeamOwner(team: Team, user: User) =
    team.owner.map(_ == user._id).getOrElse(false) match {
      case true  => Full(true)
      case false => Failure(Messages("notAllowed"))
    }

  def list = Authenticated.async{ implicit request =>
    for{
      teams <- TeamDAO.findAll
    } yield{
      val filtered = request.getQueryString("isEditable").flatMap(_.toBooleanOpt) match{
        case Some(isEditable) =>
          teams.filter(_.isEditableBy(request.user) == isEditable)
        case None =>
          teams
      }
      Ok(Writes.list(Team.teamPublicWrites(request.user)).writes(filtered))
    }
  }

  def delete(teamName: String) = Authenticated.async{ implicit request =>
    for{
      team <- TeamDAO.findOneByName(teamName)
      _ <- isTeamOwner(team, request.user).toFox
      _ <- TeamService.remove(team)
    } yield {
      JsonOk(Messages("team.deleted"))
    }
  }

  def create = Authenticated.async(parse.json){ implicit request =>
    request.body.validate(Team.teamPublicReads(request.user)) match {
      case JsSuccess(team, _) =>
        TeamService.create(team, request.user).map{ _ =>
          JsonOk(Messages("team.created"))
        }
      case e: JsError =>
        Future.successful(BadRequest(JsError.toFlatJson(e)))
    }
  }

  def delete(teamId: String) = Authenticated.async { implicit request =>
    for {
      team <- UserDAO.findOneById(teamId) ?~> Messages("user.notFound")
      _ <- allowedToAdministrate(request.user, user).toFox
      _ <- UserService.removeFromAllPossibleTeams(user, request.user)
    } yield {
      JsonOk(Messages("user.deleted", user.name))
    }
  }
}
