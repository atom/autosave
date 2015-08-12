Controls = require '../lib/controls'

describe 'Controls', ->
  describe "::shouldSave", ->
    paneItem = null

    beforeEach ->
      waitsForPromise ->
        atom.project.open('sample.coffee').then (o) ->
          paneItem = o

    it "returns true when there are no controls", ->
      expect(Controls.shouldSave(paneItem)).toBe true

    it "returns true when all controls are false", ->
      Controls.dontSaveIf (paneItem) -> not paneItem.getURI?()?
      expect(Controls.shouldSave(paneItem)).toBe true

    it "returns false when a control is true", ->
      Controls.dontSaveIf (paneItem) -> paneItem.getURI?()?
      expect(Controls.shouldSave(paneItem)).toBe false
