{CompositeDisposable, Disposable} = require 'atom'
fs = require 'fs-plus'

module.exports =
  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable

    handleBeforeUnload = @autosaveAllPaneItems.bind(this)

    window.addEventListener('beforeunload', handleBeforeUnload, true)
    @subscriptions.add new Disposable -> window.removeEventListener('beforeunload', handleBeforeUnload, true)

    handleBlur = (event) =>
      if event.target is window
        @autosaveAllPaneItems()
      else if editorElement = event.target.closest('atom-text-editor:not(mini)')
        unless editorElement.contains(event.relatedTarget) or (editorElement.lightDOM and editorElement is event.target)
          @autosavePaneItem(editorElement.getModel())

    window.addEventListener('blur', handleBlur, true)
    @subscriptions.add new Disposable -> window.removeEventListener('blur', handleBlur, true)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem ({item}) => @autosavePaneItem(item)

  deactivate: ->
    @subscriptions.dispose()

  autosavePaneItem: (paneItem) ->
    ignorable = (file) -> new RegExp(file).test(paneItem.getPath())
    filesToIgnore = atom.config.get('autosave.ignoreFiles')?.split(',') || []
    return unless atom.config.get('autosave.enabled')
    return unless paneItem?.getURI?()?
    return unless paneItem?.isModified?()
    return unless paneItem?.getPath?()? and fs.isFileSync(paneItem.getPath())
    return if filesToIgnore.some(ignorable)

    pane = atom.workspace.paneForItem(paneItem)
    if pane?
      pane.saveItem(paneItem)
    else
      paneItem.save?()

  autosaveAllPaneItems: ->
    @autosavePaneItem(paneItem) for paneItem in atom.workspace.getPaneItems()
