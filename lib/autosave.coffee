{$} = require 'atom'

module.exports =
  configDefaults:
    enabled: false

  activate: (state) ->
    @migrateOldAutosaveConfig()

    atom.rootView.on 'focusout', ".editor:not(.mini)", (event) =>
      editSession = event.targetView()?.getModel()
      @autosave(editSession)

    atom.rootView.on 'pane:before-item-destroyed', (event, paneItem) =>
      @autosave(paneItem)

    $(window).preempt 'beforeunload', =>
      for pane in atom.rootView.getPanes()
        @autosave(paneItem) for paneItem in pane.getItems()

  autosave: (paneItem) ->
    paneItem?.save?() if atom.config.get('autosave.enabled')

  migrateOldAutosaveConfig: ->
    enabled = atom.config.get('core.autosave')
    return unless enabled?

    atom.config.set('autosave.enabled', enabled)
    atom.config.set('core.autosave', null)
