Autosave = require '../lib/autosave'
{$, WorkspaceView, Editor} = require 'atom'

describe "Autosave", ->
  [initialActiveItem, otherItem1, otherItem2] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView()
    pack = atom.packages.activatePackage("autosave", immediate: true)

    atom.workspaceView.attachToDom()
    initialActiveItem = atom.workspaceView.openSync('sample.js')
    otherItem1 = atom.project.openSync('sample.coffee')
    otherItem2 = otherItem1.copy()

    spyOn(initialActiveItem, 'save').andCallThrough()
    spyOn(otherItem1, 'save').andCallThrough()
    spyOn(otherItem2, 'save').andCallThrough()

  describe "when a pane loses focus", ->
    it "saves the item if autosave is enabled and the item has a uri", ->
      $('body').focus()
      expect(initialActiveItem.save).not.toHaveBeenCalled()

      atom.workspaceView.focus()
      atom.config.set('autosave.enabled', true)
      $('body').focus()
      expect(initialActiveItem.save).toHaveBeenCalled()

  describe "when a new pane is created", ->
    it "saves the item if autosave is enabled and the item has a uri", ->
      leftPane = atom.workspaceView.getActivePane()
      rightPane = leftPane.splitRight(otherItem1)
      expect(initialActiveItem.save).not.toHaveBeenCalled()

      rightPane.remove()
      atom.config.set('autosave.enabled', true)
      leftPane.splitRight(otherItem2)
      expect(initialActiveItem.save).toHaveBeenCalled()

  describe "when an item is destroyed", ->
    describe "when the item is the active item", ->
      it "does not save the item if autosave is enabled and the item has a uri", ->
        leftPane = atom.workspaceView.getActivePane()
        rightPane = leftPane.splitRight(otherItem1)
        leftPane.focus()
        expect(initialActiveItem).toBe atom.workspaceView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        atom.config.set("autosave.enabled", true)
        leftPane = rightPane.splitLeft(otherItem2)
        expect(otherItem2).toBe atom.workspaceView.getActivePaneItem()
        leftPane.removeItem(otherItem2)
        expect(otherItem2.save).toHaveBeenCalled()

    describe "when the item is NOT the active item", ->
      it "does not save the item if autosave is enabled and the item has a uri", ->
        leftPane = atom.workspaceView.getActivePane()
        rightPane = leftPane.splitRight(otherItem1)
        expect(initialActiveItem).not.toBe atom.workspaceView.getActivePaneItem()
        leftPane.removeItem(initialActiveItem)
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        atom.config.set("autosave.enabled", true)
        leftPane = rightPane.splitLeft(otherItem2)
        rightPane.focus()
        expect(otherItem2).not.toBe atom.workspaceView.getActivePaneItem()
        leftPane.removeItem(otherItem2)
        expect(otherItem2.save).toHaveBeenCalled()
