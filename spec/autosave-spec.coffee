Autosave = require '../lib/autosave'
{$, RootView, Editor} = require 'atom'

describe "Autosave", ->
  [initialActiveItem, otherItem1, otherItem2] = []

  beforeEach ->
    window.rootView = new RootView()
    pack = atom.activatePackage("autosave", immediate: true)

    rootView.attachToDom()
    initialActiveItem = rootView.openSync('sample.js')
    otherItem1 = project.openSync('sample.coffee')
    otherItem2 = otherItem1.copy()

    spyOn(initialActiveItem, 'save').andCallThrough()
    spyOn(otherItem1, 'save').andCallThrough()
    spyOn(otherItem2, 'save').andCallThrough()

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
      rightPane = leftPane.splitRight(otherItem1)
      expect(initialActiveItem.save).not.toHaveBeenCalled()

      rightPane.remove()
      config.set('autosave.enabled', true)
      leftPane.splitRight(otherItem2)
      expect(initialActiveItem.save).toHaveBeenCalled()

  describe "when an item is destroyed", ->
    describe "when the item is the active item", ->
      it "does not save the item if autosave is enabled and the item has a uri", ->
        leftPane = rootView.getActivePane()
        rightPane = leftPane.splitRight(otherItem1)
        leftPane.focus()
        expect(initialActiveItem).toBe rootView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        config.set("autosave.enabled", true)
        leftPane = rightPane.splitLeft(otherItem2)
        expect(otherItem2).toBe rootView.getActivePaneItem()
        leftPane.removeItem(otherItem2)
        expect(otherItem2.save).toHaveBeenCalled()

    describe "when the item is NOT the active item", ->
      it "does not save the item if autosave is enabled and the item has a uri", ->
        leftPane = rootView.getActivePane()
        rightPane = leftPane.splitRight(otherItem1)
        expect(initialActiveItem).not.toBe rootView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        config.set("autosave.enabled", true)
        leftPane = rightPane.splitLeft(otherItem2)
        rightPane.focus()
        expect(otherItem2).not.toBe rootView.getActivePaneItem()
        leftPane.removeItem(otherItem2)
        expect(otherItem2.save).toHaveBeenCalled()
