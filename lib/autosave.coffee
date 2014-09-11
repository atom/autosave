{$} = require 'atom'

module.exports =
  configDefaults:
    enabled: false

  activate: ->
    $(window).on 'blur', => @autosaveAll()
    $(window).preempt 'beforeunload', => @autosaveAll()

    atom.workspaceView.on 'focusout', ".editor:not(.mini)", (event) =>
      editor = $(event.target).closest('.editor').view()?.getModel()
      @autosave(editor)

    atom.workspaceView.on 'pane:before-item-destroyed', (event, paneItem) =>
      @autosave(paneItem)

  autosave: (paneItem) ->
    return unless atom.config.get('autosave.enabled')
    return unless paneItem?.getUri?()?
    return unless paneItem?.isModified?()

    paneItem?.save?()

  autosaveAll: ->
    for pane in atom.workspace.getPanes()
      @autosave(paneItem) for paneItem in pane.getItems()
