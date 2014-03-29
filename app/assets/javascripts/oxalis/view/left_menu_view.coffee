### define
underscore : _
backbone.marionette : marionette
./settings/user_settings_view : UserSettingsView
./settings/dataset_settings_view : DatasetSettingsView
###

class LeftMenuView extends Backbone.Marionette.Layout

  template : _.template("""
    @if(annotation.restrictions.allowUpdate(session.user)){
      <a href="#" class="btn btn-primary" id="trace-save-button">Save</a>
    } else {
      <button class="btn btn-primary disabled">Read only</button>
    }
    <div id="buttonbar" class="btn-group inline-block">
      @if(annotation.restrictions.allowFinish(session.user)){
        <a href="@controllers.routes.AnnotationController.finishWithRedirect(annotation.typ, annotation.id)" class="btn btn-default btn-small" id="trace-finish-button"><i class="fa fa-check-circle-o"></i>Finish</a>
      }
      <a href="@controllers.routes.AnnotationController.download(annotation.typ, annotation.id)" class="btn btn-default btn-small" id="trace-download-button"><i class="fa fa-download"></i>NML</a>
      <a href="#help-modal" class="btn btn-default btn-small" data-toggle="modal"><i class="fa fa-question-circle"></i>Help</a>
    </div>
    <div id="dataset" class="well well-sm">
        @annotation._name.getOrElse(annotation.typ)<br />
        DataSet: <span id="dataset-name"></span><br />
        <span id="zoomFactor"></span>
    </div>
    <div class="input-group">
      <span class="input-group-addon">Position</span>
      <input id="trace-position-input" class="form-control" type="text">
    </div>
    <div class="input-group" id="trace-rotation">
      <span class="input-group-addon">Rotation</span>
      <input id="trace-rotation-input" class="form-control" type="text">
    </div>


    <div id="volume-actions" class="volume-controls">
      <button class="btn btn-default" id="btn-merge">Merge cells</button>
    </div>

    <div id="view-mode" class="skeleton-controls">
      <p>View mode:</p>
      <div class="btn-group">
        <button type="button" class="btn btn-default btn-primary" id="view-mode-3planes">3 Planes</button>
        <button type="button" class="btn btn-default" id="view-mode-sphere">Sphere</button>
        <button type="button" class="btn btn-default" id="view-mode-arbitraryplane">Arbitrary Plane</button>
      </div>
    </div>

    <div id="lefttabbar">
        <ul class="nav nav-tabs">
          <li class="active">
          <a href="#dataset-settings-tab" data-toggle="tab"><i class="fa fa-cogs"></i> Dataset</a></li>
          <li>
          <a href="#user-settings-tab" data-toggle="tab"><i class="fa fa-cogs"></i> User</a></li>
        </ul>

        <div class="tab-content">
          <div class="tab-pane active" id="dataset-settings-tab"></div>
          <div class="tab-pane" id="user-settings-tab"></div>
        </div>

    </div>
  """)


  regions :
    "userSettings" : "#user-settings-tab"
    "datasetSettings" : "#dataset-settings-tab"


  initialize : (options) ->


  #   <% if(task) { %>
  #     <li><a href="#tab0" data-toggle="tab">Task</a></li>
  #   <% } %>
  #   @if(additionalHtml.body != ""){
  #     <li class="active"><a href="#tab1" data-toggle="tab">Review</a></li>
  #     <li>
  #   } else {
  #     <li class="active">
  #   }
  #   <a href="#tab2" data-toggle="tab">Options</a></li>
  # </ul>
  #
  # <div class="tab-content">
  #   <% if(task) { %>
  #     <div class="tab-pane" id="tab0">
  #       <h5><%=task.type.summary%></h5>
  #       <%=task.type.description%>
  #     </div>
  #   <% } %>

    @userSettingsView = new UserSettingsView( _model : options._model )

    @datasetSettingsView = new DatasetSettingsView( _model : options._model )

    @listenTo(this, "render", @afterRender)


  afterRender : ->

    @userSettings.show(@userSettingsView)
    @datasetSettings.show(@datasetSettingsView)
