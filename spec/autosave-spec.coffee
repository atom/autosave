Autosave = require '../lib/autosave'
{$, WorkspaceView} = require 'atom'

describe "Autosave", ->
  [initialActiveItem, otherItem1, otherItem2] = []

  beforeEach ->
    atom.workspaceView = new WorkspaceView()

    waitsForPromise ->
      atom.packages.activatePackage("autosave")

    runs ->
      atom.workspaceView.attachToDom()

    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      initialActiveItem = atom.workspace.getActiveEditor()

    waitsForPromise ->
      atom.project.open('sample.coffee').then (o) ->
        otherItem1 = o
        otherItem2 = otherItem1.copy()

    runs ->
      spyOn(initialActiveItem, 'save')
      spyOn(otherItem1, 'save')
      spyOn(otherItem2, 'save')

  describe "when the item is not modified", ->
    it "does not autosave the item", ->
      atom.config.set('autosave.enabled', true)
      leftPane = atom.workspaceView.getActivePaneView()
      rightPane = leftPane.splitRight(otherItem1)
      expect(initialActiveItem.save).not.toHaveBeenCalled()

  describe "when the buffer is modified", ->
    beforeEach ->
      initialActiveItem.setText("i am modified")

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
        leftPane = atom.workspaceView.getActivePaneView()
        rightPane = leftPane.splitRight(otherItem1)
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        rightPane.remove()
        atom.config.set('autosave.enabled', true)
        leftPane.splitRight(otherItem2)
        expect(initialActiveItem.save).toHaveBeenCalled()

    describe "when an item is destroyed", ->
      describe "when the item is the active item", ->
        it "does not save the item if autosave is enabled and the item has a uri", ->
          leftPane = atom.workspaceView.getActivePaneView()
          rightPane = leftPane.splitRight(otherItem1)
          leftPane.focus()
          expect(initialActiveItem).toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(initialActiveItem)
          expect(initialActiveItem.save).not.toHaveBeenCalled()

          otherItem2.setText("I am also modified")
          atom.config.set("autosave.enabled", true)
          leftPane = rightPane.splitLeft(otherItem2)
          expect(otherItem2).toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(otherItem2)
          expect(otherItem2.save).toHaveBeenCalled()

      describe "when the item is NOT the active item", ->
        it "does not save the item if autosave is enabled and the item has a uri", ->
          leftPane = atom.workspaceView.getActivePaneView()
          rightPane = leftPane.splitRight(otherItem1)
          expect(initialActiveItem).not.toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(initialActiveItem)
          expect(initialActiveItem.save).not.toHaveBeenCalled()

          otherItem2.setText("I am also modified")
          atom.config.set("autosave.enabled", true)
          leftPane = rightPane.splitLeft(otherItem2)
          rightPane.focus()
          expect(otherItem2).not.toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(otherItem2)
          expect(otherItem2.save).toHaveBeenCalled()

    describe "when the item does not have a URI", ->
      it "does not save the item", ->
        waitsForPromise ->
          atom.workspace.open()

        runs ->
          pathLessItem = atom.workspace.getActiveEditor()
          spyOn(pathLessItem, 'save').andCallThrough()
          pathLessItem.setText('text!')
          expect(pathLessItem.getUri()).toBeFalsy()

          atom.config.set('autosave.enabled', true)
          atom.workspaceView.getActivePaneView().destroyItem(pathLessItem)
          expect(pathLessItem.save).not.toHaveBeenCalled()

  describe "when the window is blurred", ->
    it "saves all items", ->
      atom.config.set('autosave.enabled', true)

      leftPane = atom.workspaceView.getActivePaneView()
      rightPane = leftPane.splitRight(otherItem1)

      initialActiveItem.insertText('a')
      otherItem1.insertText('b')

      $(window).trigger('blur')

      expect(initialActiveItem.save).toHaveBeenCalled()
      expect(otherItem1.save).toHaveBeenCalled()
