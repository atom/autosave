{$} = require 'atom'

module.exports =
  configDefaults:
    enabled: true

  activate: ->
    atom.workspaceView.on 'focusout', ".editor:not(.mini)", (event) =>
      editor = $(event.target).closest('.editor').view()?.getModel()
      @autosave(editor)

    atom.workspaceView.on 'pane:before-item-destroyed', (event, paneItem) =>
      @autosave(paneItem)

    $(window).preempt 'beforeunload', =>
      for pane in atom.workspace.getPanes()
        @autosave(paneItem) for paneItem in pane.getItems()

  autosave: (paneItem) ->
    return unless atom.config.get('autosave.enabled')
    return unless paneItem?.getUri?()?
    return unless paneItem?.isModified?()

    paneItem?.save?()
