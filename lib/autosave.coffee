{$} = require 'atom'

module.exports =
  configDefaults:
    enabled: true

  activate: ->
    $(window).on 'blur', => @autosaveAll()
    $(window).preempt 'beforeunload', => @autosaveAll()

    atom.workspaceView.on 'focusout', ".editor:not(.mini)", (event) =>
      if editorView = $(event.target).closest('.editor').view()
        # If focusing an element *contained* by the editor, don't autosave
        return if editorView.element.contains(event.relatedTarget)
        editor = editorView.getModel()
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
