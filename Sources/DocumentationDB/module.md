# Documentation Database
This module contains the common data structures that are shared between the frontend and the backend. This is what is referred to in the solution outline as final Documentation Database. It supports efficient queries of entities based on their id.

It is produced by the frontend, and consumed by the backend, so the CLI can do something like this in the end:

```swift
backend(frontend(projectPath:"./myHyloProject"), exportPath: "./build")
```