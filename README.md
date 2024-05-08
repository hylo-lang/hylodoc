# HyloDoc - Automatic Documentation Generation Tool

## Getting Started
### Windows
- Install docker and WSL2
- Clone the repo into a WSL folder
- Open the repo in Windows VSCode, reopen it in devcontainer

#### Debugging and Running Tests
- Once you open up a devcontainer, there should be a run configuration called "Debug Tests" in the run and debug tab.
- Additionally, you should be able to debug individual tests cases and test methods by clicking on the green arrow next 
  to them. If you right-click the arrow, you will have the option to debug the particular test.
 

### Mac
- Set up Swift
- CLone the repository

### Formatting

This project uses the `swift-format` library to enforce good formatting of all `.swift` files. There is a job in the 
pipeline that will fail if the library finds any lines of code that do not conform to the ruleset `.swift-format.json`.
To check if your staged files adhere to this standard you can run the following command in the devcontainer terminal:

```
swift-format lint -r --configuration .swift-format.json -p Sources Tests Package.swift
```

If there are any problems, one can run this command to fix *most* errors:
```
swift-format --in-place -r --configuration .swift-format.json -p Sources Tests Package.swift
```

However, there are some limitations to this command that will still fail the pipeline, which will require manual 
modifications.

#### Pre-commit git hook

There's a pre-commit git hook that will run the format command on any staged `.swift` files. It is provided as 
`pre-commit` in the project root.

To use it you have to have Swift 5.9 installed and available in the PATH environment variable. Next, you will have to 
install the `swift-format` library locally and add it to `$PATH`. Navigate to a suitable location and run the following
command:

```
git clone -b release/5.9 https://github.com/apple/swift-format.git && cd swift-format && swift build -c release && export PATH="$(pwd)/.build/release:$PATH" && swift-format --version
```

This will clone and build the required `swift-format` version and add it to your PATH. If the installation has been 
successful, the terminal output should read `509.0.0`.

Finally, the pre-commit script should be added to your `.git` folder. Copy `pre-commit` from the project root and paste 
it in `.git/hooks`. 
