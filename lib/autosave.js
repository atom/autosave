const fs = require('fs-plus')
const {CompositeDisposable, Disposable} = require('atom')
const {dontSaveIf, shouldSave} = require('./controls')

module.exports = {
  subscriptions: null,

  provideService () {
    return {dontSaveIf}
  },

  activate () {
    this.subscriptions = new CompositeDisposable()

    const handleBeforeUnload = this.autosaveAllPaneItems.bind(this)

    window.addEventListener('beforeunload', handleBeforeUnload, true)
    this.subscriptions.add(new Disposable(function () { return window.removeEventListener('beforeunload', handleBeforeUnload, true) }))

    const handleBlur = event => {
      if (event.target === window) {
        this.autosaveAllPaneItems()
      // TODO: We can remove the check for the editor not containing the related target once 1.18 reaches stable
      } else if (event.target.matches('atom-text-editor:not(mini)') && !event.target.contains(event.relatedTarget)) {
        return this.autosavePaneItem(event.target.getModel())
      }
    }

    window.addEventListener('blur', handleBlur, true)
    this.subscriptions.add(new Disposable(() => window.removeEventListener('blur', handleBlur, true)))

    this.subscriptions.add(atom.workspace.onDidAddPaneItem(({item}) => this.autosavePaneItem(item, true)))
    this.subscriptions.add(atom.workspace.onWillDestroyPaneItem(({item}) => this.autosavePaneItem(item)))
  },

  deactivate () {
    this.subscriptions.dispose()
  },

  autosavePaneItem (paneItem, create = false) {
    if (!atom.config.get('autosave.enabled')) return
    if (!paneItem) return
    if (typeof paneItem.getURI !== 'function' || !paneItem.getURI()) return
    if (!create && (typeof paneItem.isModified !== 'function' || !paneItem.isModified())) return
    if (typeof paneItem.getPath !== 'function' || !paneItem.getPath()) return
    if (!shouldSave(paneItem)) return

    try {
      const stats = fs.statSync(paneItem.getPath())
      if (!stats.isFile()) return
    } catch (e) {
      if (e.code !== 'ENOENT') return
      if (!create) return
    }

    const pane = atom.workspace.paneForItem(paneItem)
    if (pane) {
      return pane.saveItem(paneItem)
    } else if (typeof paneItem.save === 'function') {
      return paneItem.save()
    } else {
      return Promise.resolve()
    }
  },

  autosaveAllPaneItems () {
    return atom.workspace.getPaneItems().map((paneItem) => this.autosavePaneItem(paneItem))
  }
}
