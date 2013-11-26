{$} = require 'atom'

module.exports =
  configDefaults:
    enabled: false

  activate: (state) ->
    @migrateOldAutosaveConfig()

    atom.workspaceView.on 'focusout', ".editor:not(.mini)", (event) =>
      editSession = event.targetView()?.getModel()
      @autosave(editSession)

    atom.workspaceView.on 'pane:before-item-destroyed', (event, paneItem) =>
      @autosave(paneItem)

    $(window).preempt 'beforeunload', =>
      for pane in atom.workspaceView.getPanes()
        @autosave(paneItem) for paneItem in pane.getItems()

  autosave: (paneItem) ->
    paneItem?.save?() if atom.config.get('autosave.enabled')

  migrateOldAutosaveConfig: ->
    enabled = atom.config.get('core.autosave')
    return unless enabled?

    atom.config.set('autosave.enabled', enabled)
    atom.config.set('core.autosave', null)
