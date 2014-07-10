{$} = require 'atom'

module.exports =
  configDefaults:
    enabled: false

  activate: ->
    atom.workspaceView.on 'focusout', ".editor:not(.mini)", (event) =>
      # Don't autosave if the focus change was towards a select list.
      # Select lists will be opened by packages like autosuggest.
      if $(event.relatedTarget).closest(".select-list").length
        return
      editor = $(event.target).closest('.editor').view()?.getModel()
      @autosave(editor)

    atom.workspaceView.on 'pane:before-item-destroyed', (event, paneItem) =>
      @autosave(paneItem)

    $(window).preempt 'beforeunload', =>
      for pane in atom.workspaceView.getPanes()
        @autosave(paneItem) for paneItem in pane.getItems()

  autosave: (paneItem) ->
    return unless atom.config.get('autosave.enabled')
    return unless paneItem?.getUri?()?
    return unless paneItem?.isModified?()

    paneItem?.save?()
