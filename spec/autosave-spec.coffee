Autosave = require '../lib/autosave'
{$, RootView, Editor} = require 'atom'

describe "Autosave", ->
  [initialActiveItem, anotherItem] = []

  beforeEach ->
    window.rootView = new RootView()
    pack = atom.activatePackage("autosave", immediate: true)

    rootView.attachToDom()
    initialActiveItem = rootView.openSync('sample.js')
    anotherItem = project.openSync('sample.coffee')

    spyOn(initialActiveItem, 'save').andCallThrough()

  describe "when a pane loses focus", ->
    it "saves the item if autosave is enabled and the item has a uri", ->
      $('body').focus()
      expect(initialActiveItem.save).not.toHaveBeenCalled()

      rootView.focus()
      config.set('autosave.enabled', true)
      $('body').focus()
      expect(initialActiveItem.save).toHaveBeenCalled()

  describe "when a new pane is created", ->
    it "saves the item if autosave is enabled and the item has a uri", ->
      leftPane = rootView.getActivePane()
      rightPane = leftPane.splitRight(anotherItem)
      expect(initialActiveItem.save).not.toHaveBeenCalled()

      rightPane.remove()
      config.set('autosave.enabled', true)
      leftPane.splitRight(anotherItem)
      expect(initialActiveItem.save).toHaveBeenCalled()

  describe "when an item is destroyed", ->
    describe "when the item is the active item", ->
      it "does not save the item if autosave is enabled and the item has a uri", ->
        leftPane = rootView.getActivePane()
        rightPane = leftPane.splitRight(anotherItem)
        leftPane.focus()
        expect(initialActiveItem).toBe rootView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        config.set("autosave.enabled", true)
        leftPane = rightPane.splitLeft(initialActiveItem)
        expect(initialActiveItem).toBe rootView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).toHaveBeenCalled()

    describe "when the item is NOT the active item", ->
      it "does not save the item if autosave is enabled and the item has a uri", ->
        leftPane = rootView.getActivePane()
        rightPane = leftPane.splitRight(anotherItem)
        expect(initialActiveItem).not.toBe rootView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        config.set("autosave.enabled", true)
        leftPane = rightPane.splitLeft(initialActiveItem)
        rightPane.focus()
        expect(initialActiveItem).not.toBe rootView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).toHaveBeenCalled()
