/*
 * Copyright (C) 2011-2017 scalable minds UG (haftungsbeschränkt) & Co. KG. <http://scm.io>
 */
package com.scalableminds.braingames.datastore.tracings

import java.util.UUID

import com.scalableminds.braingames.binary.storage.kvstore.{KeyValueStoreImplicits, VersionedKeyValueStore}
import com.scalableminds.braingames.datastore.tracings.skeleton.TracingSelector
import com.scalableminds.util.tools.{Fox, FoxImplicits}
import com.trueaccord.scalapb.{GeneratedMessage, GeneratedMessageCompanion, Message}
import com.typesafe.scalalogging.LazyLogging
import net.liftweb.common.{Empty, Failure, Full}

import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.Future
import scala.concurrent.duration._

trait TracingService[T <: GeneratedMessage with Message[T]] extends KeyValueStoreImplicits with FoxImplicits with LazyLogging {

  def tracingType: TracingType.Value

  def tracingStore: VersionedKeyValueStore

  def temporaryTracingStore: TemporaryTracingStore[T]

  implicit def tracingProtoCompanion: GeneratedMessageCompanion[T]

  // this should be longer than maxCacheTime in webknossos/AnnotationStore
  // so that the references saved there remain valid throughout their life
  private val temporaryStoreTimeout = 10 minutes

  def createNewId: String =
    UUID.randomUUID.toString

  def currentVersion(tracingId: String): Fox[Long] = Fox.successful(1)

  def applyPendingUpdates(tracing: T, tracingId: String, targetVersion: Option[Long]): Fox[T] =
    Fox.successful(tracing)

  def find(tracingId: String, version: Option[Long] = None, useCache: Boolean = true, applyUpdates: Boolean = false): Fox[T] = {
    tracingStore.get(tracingId, version)(fromProto[T]).map(_.value).flatMap { tracing =>
      if (applyUpdates)
        applyPendingUpdates(tracing, tracingId, version)
      else
        Fox.successful(tracing)
    }.orElse {
      if (useCache)
        temporaryTracingStore.find(tracingId)
      else
        Fox.empty
    }
  }

  def findMultiple(selectors: List[TracingSelector], useCache: Boolean = true, applyUpdates: Boolean = false): Fox[List[T]] = {
    Fox.combined {
      selectors.map(selector => find(selector.tracingId, selector.version, useCache, applyUpdates))
    }
  }

  def save(tracing: T, tracingId: String, version: Long, toCache: Boolean = false): Fox[_] = {
    logger.debug("####### saving tracing at id " + tracingId)
    find(tracingId).futureBox.flatMap {
      case Full(_) =>
        Fox.failure("tracing ID is already in use.")
      case Empty =>
        if (toCache) {
          Fox.successful(temporaryTracingStore.insert(tracingId, tracing, Some(temporaryStoreTimeout)))
        } else {
          tracingStore.put(tracingId, version, tracing)
        }
      case f: Failure =>
        Future.successful(f)
    }
  }
}
