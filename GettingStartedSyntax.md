# Documentation Syntax Guide

## Overview

This documentation compiler tool converts Markdown-based text into rich documentation for Hylo modules. Here's a type with an example method documented:

```
type Vector2 {
  public var x: Float64
  public var y: Float64
  public memberwise init

  /// This method offsets a vector's coordinates by the given parameter.
  ///
  /// # Parameters:
  ///   - delta: Vector2 containing the x and y values to offset by
  /// # Returns: A new Vector2 with the modified coordinates
  /// # Precondition: initial vector and parameter must not be nil
  public fun offset_let(by delta: Vector2) -> Vector2 {
    Vector2(x: self.x + delta.x, y: self.y + delta.y)
  }
}
```

## Basic symbol description

This tool only aggregates documentation lines that are prepended by three forward slashes and a space (`/// `) into a documentation comment. If this block is directly above a symbol, then it becomes associated with it and an entry in the generated website will be created for it. 

The first step toward writing great documentation is to add single-sentence abstracts or summaries. This tool takes the first paragraph of a documentation content as the summary:

```
/// Let binding for the gravitational constant.
let gravity = 9.81
```

Sometimes, just a summary is not enough and you would like to provide additional content or details.

```
/// Let binding for the gravitational constant.
///
/// Declared here to be used in further calculations.
/// **Warning**: It is a constant, so it cannot be changed!
let gravity = 9.81
```

Any other content you will add after the summary is considered as the Description of this symbol. The Description section can contain one or more paragraphs, lists and all other Markdown features, except for level one headers. That is because level one headers are used to delineate a special section.

## Special sections

For methods that take parameters, you can document those parameters in their own section. Rather than just writing everything as part of the Description, you should write their documentation as part of the special Parameters section as this will enable the website generation to use the special layout created for parameters. A special section can be created directly below the summary, or the Discussion section, if you include one. The documentation compiler supports two approaches for creating a special section: either as a list with a level one heading title, or one or more inline sections that each have the section title and the content afterwards.

Consider this method:

```
/// This method offsets a vector's coordinates by the given parameters.
public fun offset_let(_ x: Float64, _ y: Float64) -> Vector2 {
    Vector2(x: self.x + x, y: self.y + y)
  }
```


The two parameters can be documented one of two ways (**not** both!):

```
/// This method offsets a vector's coordinates by the given parameters.
///
/// # Parameters:
///   - x: Float64 containing the x value to offset by
///   - y: Float64 containing the y value to offset by
public fun offset_let(_ x: Float64, _ y: Float64) -> Vector2 {
    Vector2(x: self.x + x, y: self.y + y)
  }
```

OR

```
/// This method offsets a vector's coordinates by the given parameters.
///
/// # Parameter x: Float64 containing the x value to offset by
/// # Parameter y: Float64 containing the y value to offset by
public fun offset_let(_ x: Float64, _ y: Float64) -> Vector2 {
    Vector2(x: self.x + x, y: self.y + y)
  }
```

Now, a method's documentation can only include documentation for parameters that are actually declared for that specific method. For example, trying to write documentation for a `z` parameter will result in an exception. Similar can be said about the special sections themselves. A method cannot `yield` anything, therefore trying to create a `# Yields: ` section for a method will also result in an exception. The full list of allowed special section titles and other requirements for every type of symbol can be seen in the [Syntax Reference](./SyntaxReference.md).

## File-level documentation

Another option that is supported is to write a documentation comment describing this file or some characteristics about its contents. Just like symbol comments, the first paragraph is the summary and the rest are the description. However, this whole comment block must begin with the ``# File-level:`` level one heading and can only contain a `# See also: ` special section that may link to other pieces of documentation. For example, this is a valid file level comment:

```
/// # File-level:
/// This file contains the implementations of all of the Vector types.
///
/// All Vector2, Vector3 and Vector4 inherit from the same Vector type.
/// # See also:
///   - link to something
```

## Articles

You can document a module (a directory of files) by creating a `module.hylodoc` file. You can use this as a landing page: provide a brief introduction for the module, and add links to other articles, such as getting started guides and tutorials. All related symbols and files will be linked and properly presented on the generated website, so you can concentrate on the content.