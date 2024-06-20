# HyloDoc - Automatic Documentation Generation Tool

## Getting Started
To use HyloDoc for generating websites, you can use its command line interface or use it as a library in your project
to gain more control and customization.

After setting up the development environment, you can run the HyloDoc CLI the following command:
```shell
swift run -c release hdc
```

The CLI can extract documentation from one or more folders and generate a website into the output directory, which by default is `./dist`. An http server can be started after generation by the `--preview` flag.

```shell
hdc --help

# Outputs documentation of one module to ./dist
hdc PATH_TO_MODULE

# Process multiple modules
hdc PATH_TO_MODULE_1 PATH_TO_MODULE_2 ...

# Specify output directory
hdc PATH_TO_MODULE --output OUTPUT_DIRECTORY

# Preview the generated website by starting a web server
hdc PATH_TO_MODULE && python3 -m http.server 8080 -d dist

# Generate documentation for the Standard Library
hdc ./Sources/StandardLibrary/Sources -s

# Preview the website after generating
hdc ./Sources/StandardLibrary/Sources -s --preview
```

## Documentation Syntax Reference
You can read our syntax specification in the [Syntax Reference](./SyntaxReference.md)
## Development Environment Setup
### Windows
- Install docker and WSL2
- Clone the repo into a WSL folder
- Open the repo in Windows VSCode, reopen it in devcontainer

#### Debugging and Running Tests
- Once you open up a devcontainer, there should be a run configuration called "Debug Tests" in the run and debug tab.
- Additionally, you should be able to debug individual tests cases and test methods by clicking on the green arrow next 
  to them. If you right-click the arrow, you will have the option to debug the particular test.

### Mac
- Set up Swift 5.10 and LLVM, according to the [Hylo compiler's repository](https://github.com/hylo-lang/hylo)
- CLone the repository

## Running the Tests
To run all tests, you can use the following command:
```shell
swift test
```
Alternatively, in VSCode after the first full build of the project, you should be able to see green arrows next to the 
test cases, which you can click to run them individually, and to debug them.

### Formatting

This project uses the `swift-format` library to enforce good formatting of all `.swift` files. There is a job in the 
pipeline that will fail if the library finds any lines of code that do not conform to the ruleset `.swift-format.json`.
To check if your staged files adhere to this standard you can run the following command in the devcontainer terminal:

```
swift-format lint -r --configuration .swift-format.json -p Sources Tests Package.swift
```

If there are any problems, you one can run this command to fix *most* errors in all files.
```
./format-all.sh
```
You can alternatively use the VSCode extension `vknabel.vscode-apple-swift-format` and the `Shift + Alt + F` shortcut for formatting the current file. Note that it takes some time until the library initializes itself in a devcontainer.

However, there are some limitations to these formatting tools that will still fail the pipeline, which will require manual modifications.

#### Pre-commit git hook

There is a pre-commit git hook that will run the format command on any staged `.swift` files. It is provided as `pre-commit` in the project root.

To use it, you need to have Swift 5.10 installed and available in the PATH environment variable. Next, install the `swift-format` library locally and add it to `$PATH`. Navigate to a suitable location and run the following command:

```
git clone -b release/5.10 https://github.com/apple/swift-format.git && cd swift-format && swift build -c release && export PATH="$(pwd)/.build/release:$PATH" && swift-format --version
```

This will clone and build the required `swift-format` version and add it to your PATH. If the installation has been successful, the terminal output should read `508.0.0`.

Finally, add the pre-commit script to your `.git` folder. Copy `pre-commit` from the project root and paste it in `.git/hooks`. 
