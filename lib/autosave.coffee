{CompositeDisposable, Disposable} = require 'atom'

module.exports =
  config:
    enabled:
      type: 'boolean'
      default: false

  subscriptions: null

  activate: ->
    @subscriptions = new CompositeDisposable

    handleBeforeUnload = @autosaveAllPaneItems.bind(this)

    window.addEventListener('beforeunload', handleBeforeUnload, true)
    @subscriptions.add new Disposable -> window.removeEventListener('beforeunload', handleBeforeUnload, true)

    handleBlur = (event) =>
      if event.target is window
        @autosaveAllPaneItems()
      else if event.target.matches('atom-text-editor:not([mini])') and not event.target.contains(event.relatedTarget)
        @autosavePaneItem(event.target.getModel())

    window.addEventListener('blur', handleBlur, true)
    @subscriptions.add new Disposable -> window.removeEventListener('blur', handleBlur, true)

    @subscriptions.add atom.workspace.onWillDestroyPaneItem ({item}) => @autosavePaneItem(item)

  deactivate: ->
    @subscriptions.dispose()

  autosavePaneItem: (paneItem) ->
    return unless atom.config.get('autosave.enabled')
    return unless paneItem?.getUri?()?
    return unless paneItem?.isModified?()

    paneItem?.save?()

  autosaveAllPaneItems: ->
    @autosavePaneItem(paneItem) for paneItem in atom.workspace.getPaneItems()
