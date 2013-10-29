module.exports =
  configDefaults:
    enabled: false

  activate: (state) ->
    @migrateOldAutosaveConfig()

    rootView.on 'focusout', ".editor:not(.mini)", (event) =>
      @autosave(event.targetView()?.getModel())

    rootView.on 'pane:before-item-destroyed', (event, item) =>
      @autosave(item)

  autosave: (editSession) ->
    editSession?.save() if config.get('autosave.enabled')

  migrateOldAutosaveConfig: ->
    enabled = config.get('core.autosave')
    return unless enabled?

    config.set('autosave.enabled', enabled)
    config.set('core.autosave', null)
