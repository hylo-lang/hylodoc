# Documentation Syntax Reference

## Overview

The Hylo Documentation Compiler converts Markdown-based text into rich documentation for Hylo modules. The tool extracts documentation comments from two places: standalone Markdown articles and comment blocks embedded inside `.hylo` source files.

## Embedded documentation

### The documentation comment block

Consecutive lines starting with 3 slashes (`///`) constitute a comment block:
```
/// This is a valid comment line.
/// This is also valid and it's part of the same block.

/// This line is part of another comment block.
```
It is required to place a space after the 3 slashes unless it is an empty line. This space will be stripped away from the actual content.

### The supported Markdown syntax
Markdown syntax is supported in documentation comments according to the CommonMark specification with some differences:
 - Level 1 headings are reserved for declaring special sections (`# Parameters:`) and the file-level modifier (`# File-level`).
 - Inline code snippets surrounded by double backticks are reserved for Hylo code references (` ``MyType.myFunction(x:,y:)`` `) that are resolved and checked in the scope of the symbol they appear in.


Example: 
```markdown
/// I *like* **markdown** _a lot_
///  - It is very readable
///  - It is `easy to write`
///
///     This becomes a code block because of the 4 leading spaces.
```

The first paragraph of the block will always be parsed as that block's Summary. All other Markdown that follows until the next level one heading (in the case that special sections are present) or the end of the block is considered as that block's Description.

```
/// This is the summary
/// 
/// This is the description
///   - This is also part of the description
/// ## So is this
```
### Special Sections

Special sections are signaled by level one headings and document a specific part of a symbol. They make use of predefined styles and layouts in the website generation. A special section will always start with a level one heading with the first word being that section's title. Depending on what the block is associated with only some special sections are available. A special section's content can either be

- a list
  ```
  /// # Preconditons:
  ///  - width //< height – the rectangle should be 
  ///    longer vertically than horizontally
  ///  - width and height must be positive
  ```

- or a one-line paragraph
  ```
  /// # Preconditon: width //< height – the rectangle should be longer vertically than horizontally
  /// # Precondition: width and height must be positive
  ```

Note that the less than (`<`) character has been escaped.

#### Parameter/Generic sections

All special sections titles are followed by a colon `:`, except Parameter and Generic Parameter sections in their inline(singular) form. In their list/plural form, i.e. `# Parameters:` and `# Generics:` they still have the colon, but in their inline forms they do not: `# Parameter` and `# Generic`. This is because these inline sections have a special syntax where the title is followed by a space, then the name of the parameter, then a colon `:`, and then the parameter description:

```
/// # Parameter myParameter1: Example parameter description
/// # Parameter myParameter2: Example parameter description
```

And the list form:
```
/// # Parameters: 
///   - myParameter1: Example parameter description
///   - myParameter2: Example parameter description
```
The parameters are validated. A parameter or generic parameter can only be documented if is present in that symbol's declaration.

### Scope of Embedded Documentation
Documentation comment blocks can have two different scopes:
- A **symbol-level** documentation comment annotates the symbol declaration it preceeds, and it needs to be placed before a symbol declaration, possibly separated by spaces.<br>
  Example:
  ```swift
  /// Checks a necessary condition for making forward progress.
  ///
  /// # Parameters:
  ///   - condition: The condition to test.
  ///   - message: A description of the error
  public fun precondition(_ condition: Bool, _ message: String) {
    ...
  }
  ```
- A **file-level** documentation comment describes the source file as a whole, and they are identified by starting with a `# File-Level` heading.<br>
  Example:
  ```
  /// # File-level:
  ///
  /// The first paragraph is the summary
  ///
  /// This is the description
  ///
  /// # See also:
  ///   - [this other file](MyModule/article.hylodoc)
  ///   - ``MyModule.myFunction(x:y:_:)``
  ```

### Symbol Documentation
A documentation comment block preceding a symbol declaration is a symbol-level documentation, unless marked file-Level by a heading.

The first paragraph is the summary, then the rest of the content until the first section is the description. Example:

```swift
/// This is the summary
/// 
/// This is the description.
///
/// This is still the description.
/// # See Also:
///  - This is part of the first section.
trait A { ... }
```

#### Section Types:
1. `# See Also:` - inline, list<br>
   The See Also section is used to provide references to related symbols, articles, or external resources.<br>
   **Available for:** all declarations. <br>
   Example:
   ```markdown
   /// # See Also:
   ///   - ``MyModule.relatedFunction(_:)``
   ///   - [External Resource](https://example.com/related-topic)
   ```
2. `# Invariant:` - inline, `# Invariants:` - list<br>
   The Invariant section is used to document invariants or conditions that must hold true for the associated type or binding.
   Available for: **Product Types, Traits, Binding**.<br>
   ```markdown
   /// # Invariant: `startIndex < endIndex`.
   /// # Invariant:
   ///   - The `capacity` must be greater than `count`.
   ///   - The earth must be kept spinning
   ```

3. `# Parameter ` - inline, `# Parameters:` - list<br>
   The Parameter section is used to document the parameters of a function, method, subscript, or initializer.<br>
   **Available for:** Function, Method declaration, Method Bundle implementation, Subscript declaration.<br>
   Example:
   ```markdown
   /// # Parameter label: A brief description of the `label` parameter.
   /// # Parameters:
   ///   - label: A brief description of the `label` parameter.
   ///   - value: A description of the `value` parameter.
   ```

4. `# Generic ` - inline, `# Generics:` - list<br>
   The Generic(s) section is used to document the generic parameters of a declaration.<br>
   **Available for:** function, method declaration, initializer and product type.<br>
   Example:
   ```markdown
   /// # Generic T: The type of elements in the array.
   /// # Generics:
   ///   - T: The type of elements in the array.
   ///   - U: The type of the transform function's argument.
   ```

5. `# Throws:` - inline, list<br>
   The Throws section is used to document the errors that a function, method, subscript, or initializer can throw.<br>
   **Available for:** function, method declaration, method Bundle implementation, subscript declaration, subscript bundle implementation.<br>
   Example:
   ```markdown
   /// # Throws: An `InvalidArgumentError` if the provided argument is invalid.
   ```

6. `# Precondition:` - inline, `# Preconditions:` - list<br>
   The Precondition section is used to document the preconditions that must be met before a function, method, subscript, or initializer is called.<br>
   **Available for:** function, method declaration, method bundle implementation, subscript declaration, subscript bundle implementation, initializer.<br>
   Example:
   ```markdown
   /// # Precondition: The `index` must be within the bounds of the array.
   /// # Preconditions:
   ///   - The `start` index must be less than or equal to the `end` index.
   ///   - The `capacity` must be greater than or equal to the requested `newCapacity`.
   ```

7. `# Postcondition:` - inline, `# Postconditions:` - list<br>
   The Postcondition section is used to document the conditions that must hold true after a function, method, subscript, or initializer has executed.<br>
   **Available for:** Function, Method declaration, Method Bundle implementation, Subscript declaration, Subscript bundle implementation, Initializer.<br>
   Example:
   ```markdown
   /// # Postcondition: `array.count == 0`
   /// # Postconditions:
   ///   - The `capacity` is greater than or equal to the `count`.
   ///   - The `isEmpty` property returns `true` if the `count` is zero.
   ```

8. `# Returns:` - inline, list<br>
   The Returns section is used to document the return value of a function or method.<br>
   **Available for:** Function, Method declaration, Method Bundle implementation.<br>
   Example:
   ```markdown
   /// # Returns: The sum of all elements in the array.

   /// # Returns:
   ///  - true on success
   ///  - false on failure
   ```

9. `# Yields:` - inline, list<br>
   The Yields section is used to document the values yielded by a subscript or computed property.<br>
   **Available for:** subscript/property declaration, subscript/property bundle implementation.<br>
   Example:
   ```markdown
   /// # Yields: The element at the specified `index`.
   ```


#### Supported Symbol Types and Their Available Sections
Different special sections are available for different declaration types.

  1. Product type
      - `# See Also:` (inline, list)
      - `# Invariant:` (inline), `# Invariants:` (list)
      - `# Generic:` (inline), `# Generics:` (list)

  2. Trait
      - `# See Also:` (inline, list)
      - `# Invariant:` (inline), `# Invariants:` (list)

  3. Type alias
      - `# See Also:` (inline, list)

  4. Associated type
      - `# See Also:` (inline, list)

  5. Associated value
      - `# See Also:` (inline, list)

  6. Binding
      - `# See Also:` (inline, list)
      - `# Invariant:` (inline), `# Invariants:` (list)

  7. Operator
      - `# See Also:` (inline, list)

  8. Function
      - `# See Also:` (inline, list)
      - `# Parameter ` (inline), `# Parameters:` (list)
      - `# Generic ` (inline), `# Generics:` (list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)
      - `# Returns:` (inline, list)

  9. Method declaration
      - `# See Also:` (inline, list)
      - `# Parameter ` (inline), `# Parameters:` (list)
      - `# Generic ` (inline), `# Generics:` (list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)
      - `# Returns:` (inline, list)

  10. Method bundle implementation
      - `# See Also:` (inline, list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)
      - `# Returns:` (inline, list)

  11. Subscript/property declaration
      - `# See Also:` (inline, list)
      - `# Parameter ` (inline), `# Parameters:` (list)
      - `# Generic ` (inline), `# Generics:` (list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)
      - `# Yields:` (inline, list)
  12. Subscript/property bundle implementation
      - `# See Also:` (inline, list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)
      - `# Yields:` (inline, list)

  13. Initializer
      - `# See Also:` (inline, list)
      - `# Parameter ` (inline), `# Parameters:` (list)
      - `# Generic ` (inline), `# Generics:` (list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)



## Articles

Markdown articles can be written in `.hylodoc` files. 

A **level 1 heading** may only appear at the beginning of the article, and, if present, is interpreted as the main title of the article, and removed from the content.

**Hylodoc references** are supported in articles, and they are resolved in the scope of the module in which they appear in.

Here's the section restructured in a more reference manual style:

## Syntax of Links

### URLs

The following Markdown syntax for URLs is supported:

- Autolinks: `<https://example.com>`
- Full Markdown links: `[title](url)` 
- Images: `![title](https://example.com/logo.png)`

Implicit links are not supported.

### Local File References

Usage: 
- Full Markdown links: `[title](relative/path/to/file.ext)`
- Images: `![alt text](path/to/image.png "title")`

Only relative paths are supported. These can refer to the following:
- Articles (`.hylodoc` files)
- Folders
- Source code (`.hylo` files)
- Other assets (PDF, images, etc.)

`.hylodoc` files, folders, and source files are resolved to their corresponding documentation pages. Other assets are copied to the output directory for download, preserving their relative tree structure.

Examples:

```markdown
[Article](./article.hylodoc)
[Article](../src/article.hylodoc)
![Image](../public/logo.png "Logo")
[Whitepaper](../public/MVS.pdf)
[Source File](main.hylo)
[Folder](../)
[Folder](./)
```

### Symbol References

Usage:
``` ``MyModule.myFunction(x:y:_:)`` ```

Parameter labels can be omitted if the reference is unambiguous: ``` ``markdown``MyModule.myFunction`` ```

> Note: Currently, only the latter syntax is implemented, and it is a fatal failure if the overload set contains more than 1 declaration.