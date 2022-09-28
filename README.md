##### Atom and all repositories under Atom will be archived on December 15, 2022. Learn more in our [official announcement](https://github.blog/2022-06-08-sunsetting-atom/)
 # Autosave package
[![OS X Build Status](https://travis-ci.org/atom/autosave.svg?branch=master)](https://travis-ci.org/atom/autosave) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/3aktr9updp722fqx/branch/master?svg=true)](https://ci.appveyor.com/project/Atom/autosave/branch/master) [![Dependency Status](https://david-dm.org/atom/autosave.svg)](https://david-dm.org/atom/autosave)

Autosaves editor when they lose focus, are destroyed, or when the window is closed.

This package is disabled by default and can be enabled via the `autosave.enabled` config
setting or by checking *Enabled* in the settings for the *autosave* package in the
Settings view.

## Service API
The service exposes an object with a function `dontSaveIf`, which accepts a callback.
Callbacks will be invoked with each pane item eligible for an autosave and if the callback
returns true, the item will be skipped.

### Usage

#### package.json
``` json
"consumedServices": {
  "autosave": {
    "versions": {
      "1.0.0": "consumeAutosave"
    }
  }
}
```

#### package initialize
``` javascript
consumeAutosave({dontSaveIf}) {
  dontSaveIf(paneItem -> paneItem.getPath() === '/dont/autosave/me.coffee')
}
```
