Autosave = require '../lib/autosave'
fs = require 'fs-plus'

describe "Autosave", ->
  [workspaceElement, initialActiveItem, otherItem1, otherItem2] = []

  beforeEach ->
    workspaceElement = atom.views.getView(atom.workspace)
    jasmine.attachToDOM(workspaceElement)

    waitsForPromise ->
      atom.packages.activatePackage("autosave")

    waitsForPromise ->
      atom.workspace.open('sample.js')

    runs ->
      initialActiveItem = atom.workspace.getActiveTextEditor()

    waitsForPromise ->
      atom.workspace.open('sample.coffee', activateItem: false).then (o) ->
        otherItem1 = o
        otherItem2 = otherItem1.copy()

    runs ->
      spyOn(initialActiveItem, 'save')
      spyOn(otherItem1, 'save')
      spyOn(otherItem2, 'save')

  describe "when the item is not modified", ->
    it "does not autosave the item", ->
      atom.config.set('autosave.enabled', true)
      atom.workspace.getActivePane().splitRight(items: [otherItem1])
      expect(initialActiveItem.save).not.toHaveBeenCalled()

  describe "when the buffer is modified", ->
    beforeEach ->
      initialActiveItem.setText("i am modified")

    describe "when a pane loses focus", ->
      it "saves the item if autosave is enabled and the item has a uri", ->
        document.body.focus()
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        workspaceElement.focus()
        atom.config.set('autosave.enabled', true)
        document.body.focus()
        expect(initialActiveItem.save).toHaveBeenCalled()

      it "suppresses autosave if the file does not exist", ->
        document.body.focus()
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        workspaceElement.focus()
        atom.config.set('autosave.enabled', true)

        originalPath = atom.workspace.getActiveTextEditor().getPath()
        tmpPath = "#{originalPath}~"
        fs.renameSync(originalPath, tmpPath)

        document.body.focus()
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        fs.renameSync(tmpPath, originalPath)

      it "suppresses autosave if the focused element is contained by the editor, such as occurs when opening the autocomplete menu", ->
        atom.config.set('autosave.enabled', true)
        focusStealer = document.createElement('div')
        focusStealer.setAttribute('tabindex', -1)

        textEditorElement = atom.views.getView(atom.workspace.getActiveTextEditor())
        textEditorElement.appendChild(focusStealer)
        focusStealer.focus()
        expect(initialActiveItem.save).not.toHaveBeenCalled()

    describe "when a new pane is created", ->
      it "saves the item if autosave is enabled and the item has a uri", ->
        leftPane = atom.workspace.getActivePane()
        rightPane = leftPane.splitRight()
        expect(initialActiveItem.save).not.toHaveBeenCalled()

        rightPane.destroy()
        leftPane.activate()

        atom.config.set('autosave.enabled', true)
        leftPane.splitRight()
        expect(initialActiveItem.save).toHaveBeenCalled()

    describe "when an item is destroyed", ->
      describe "when the item is the active item", ->
        it "does not save the item if autosave is enabled and the item has a uri", ->
          leftPane = atom.workspace.getActivePane()
          rightPane = leftPane.splitRight(items: [otherItem1])
          leftPane.activate()
          expect(initialActiveItem).toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(initialActiveItem)
          expect(initialActiveItem.save).not.toHaveBeenCalled()

          otherItem2.setText("I am also modified")
          atom.config.set("autosave.enabled", true)
          leftPane = rightPane.splitLeft(items: [otherItem2])
          expect(otherItem2).toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(otherItem2)
          expect(otherItem2.save).toHaveBeenCalled()

      describe "when the item is NOT the active item", ->
        it "does not save the item if autosave is enabled and the item has a uri", ->
          leftPane = atom.workspace.getActivePane()
          rightPane = leftPane.splitRight(items: [otherItem1])
          expect(initialActiveItem).not.toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(initialActiveItem)
          expect(initialActiveItem.save).not.toHaveBeenCalled()

          otherItem2.setText("I am also modified")
          atom.config.set("autosave.enabled", true)
          leftPane = rightPane.splitLeft(items: [otherItem2])
          rightPane.focus()
          expect(otherItem2).not.toBe atom.workspace.getActivePaneItem()
          leftPane.destroyItem(otherItem2)
          expect(otherItem2.save).toHaveBeenCalled()

    describe "when the item does not have a URI", ->
      it "does not save the item", ->
        waitsForPromise ->
          atom.workspace.open()

        runs ->
          pathLessItem = atom.workspace.getActiveTextEditor()
          spyOn(pathLessItem, 'save').andCallThrough()
          pathLessItem.setText('text!')
          expect(pathLessItem.getURI()).toBeFalsy()

          atom.config.set('autosave.enabled', true)
          atom.workspace.getActivePane().destroyItem(pathLessItem)
          expect(pathLessItem.save).not.toHaveBeenCalled()

  describe "when the window is blurred", ->
    it "saves all items", ->
      atom.config.set('autosave.enabled', true)

      leftPane = atom.workspace.getActivePane()
      rightPane = leftPane.splitRight(items: [otherItem1])

      initialActiveItem.insertText('a')
      otherItem1.insertText('b')

      window.dispatchEvent(new FocusEvent('blur'))

      expect(initialActiveItem.save).toHaveBeenCalled()
      expect(otherItem1.save).toHaveBeenCalled()

  it "saves via the item's Pane so that write errors are handled via notifications", ->
    saveError = new Error('Save failed')
    saveError.code = 'EACCES'
    saveError.path = initialActiveItem.getPath()
    initialActiveItem.save.andThrow(saveError)

    errorCallback = jasmine.createSpy('errorCallback').andCallFake ({preventDefault}) -> preventDefault()
    atom.onWillThrowError(errorCallback)

    initialActiveItem.insertText('a')
    atom.config.set('autosave.enabled', true)

    expect(-> atom.workspace.destroyActivePaneItem()).not.toThrow()
    expect(initialActiveItem.save).toHaveBeenCalled()
    expect(errorCallback.callCount).toBe 1
