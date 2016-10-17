{CompositeDisposable, Disposable} = require 'atom'
fs = require 'fs-plus'
{dontSaveIf, shouldSave} = require './controls'

module.exports =
  subscriptions: null

  provideControls: -> dontSaveIf

  activate: ->
    @subscriptions = new CompositeDisposable

    handleBeforeUnload = @autosaveAllPaneItems.bind(this)

    window.addEventListener('beforeunload', handleBeforeUnload, true)
    @subscriptions.add new Disposable -> window.removeEventListener('beforeunload', handleBeforeUnload, true)

    handleBlur = (event) =>
      if event.target is window
        @autosaveAllPaneItems()
      else if editorElement = event.target.closest('atom-text-editor:not(mini)')
        unless event.target.matches('atom-text-editor:not(mini)') or editorElement.contains(event.relatedTarget)
          @autosavePaneItem(editorElement.getModel())

    window.addEventListener('blur', handleBlur, true)
    @subscriptions.add new Disposable -> window.removeEventListener('blur', handleBlur, true)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem ({item}) => @autosavePaneItem(item)

  deactivate: ->
    @subscriptions.dispose()

  autosavePaneItem: (paneItem) ->
    return unless atom.config.get('autosave.enabled')
    return unless shouldSave(paneItem)
    return unless paneItem?.getURI?()?
    return unless paneItem?.isModified?()
    return unless paneItem?.getPath?()? and fs.isFileSync(paneItem.getPath())

    pane = atom.workspace.paneForItem(paneItem)
    if pane?
      pane.saveItem(paneItem)
    else
      paneItem.save?()

  autosaveAllPaneItems: ->
    @autosavePaneItem(paneItem) for paneItem in atom.workspace.getPaneItems()
