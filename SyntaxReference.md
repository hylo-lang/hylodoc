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
- A **symbol-level** documentation comment annotates the symbol declaration it preceeds, and it needs to be placed before a symbol declaration, possibly separated by spaces.
- A **file-level** documentation comment describes the source file as a whole, and they are identified by starting with a `# File-Level` heading.
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

A symbol documentation block must precede a symbol in the source file. The first paragraph after the heading is the file's summary and what follows until the first special section or the end of the file is the description. The allowed special sections vary based on the type of the symbol. Here are the types currently supported:

<!-- 
TODO: flip the association
Introduce the different special sections, and list which types of declarations (or the File-level comment block) they can belong to.
-->
#### Types of symbols supported and their special sections

  1. Product Types
      - `# See Also:` (inline, list)
      - `# Invariant:` (inline), `# Invariants:` (list)

  2. Traits
      - `# See Also:` (inline, list)
      - `# Invariant:` (inline), `# Invariants:` (list)

  3. Type Alias
      - `# See Also:` (inline, list)

  4. Associated Type
      - `# See Also:` (inline, list)

  5. Associated Value
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

  10. Method Bundle implementation
      - `# See Also:` (inline, list)
      - `# Parameter ` (inline), `# Parameters:` (list)
      - `# Generic ` (inline), `# Generics:` (list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)
      - `# Returns:` (inline, list)

  11. Subscript declaration
      - `# See Also:` (inline, list)
      - `# Parameter ` (inline), `# Parameters:` (list)
      - `# Generic ` (inline), `# Generics:` (list)
      - `# Throws:` (inline, list)
      - `# Precondition:` (inline), `# Preconditions:` (list)
      - `# Postcondition:` (inline), `# Postconditions:` (list)
      - `# Yields:` (inline, list)
  12. Subscript bundle implementation
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

## Reference Syntax
### URLs
There are two form of links in the MarkDown syntax:
- autolinks (`<https://example.com>`)
- full Markdown links (`[title](url)`) for arbitrary URLs except ones with the `file://` protocol.

Implicit links are not supported.

### Local File References
> Note: this feature has not been implemented yet. The syntax is also work in progress.

We only support the full link syntax for local file references. The user is required to start the reference with
either `../`, `./`, or `/`. This is the most unambiguous syntax, and it is also the most common one, supported by all
editors. The `/` prefix will serve as a pointer to the root of the entire repository which might be different than the
module that is currently being documented. This is so that absolute links can be resolved properly in a repository by
GitHub, which takes the root of the repository as the base for resolving absolute links.

### Symbol References
We can use double backticks for code entity references, just like Swift. You can write any name that can be resolved
from the scope of the documented entity.

```markdown
``MyModule.myFunction(x:y:_:)``
```

If there is no ambiguity, parameter labels can be ignored from function references:
```markdown
``MyModule.myFunction``
```
> Note: currently, only the latter syntax is implemented