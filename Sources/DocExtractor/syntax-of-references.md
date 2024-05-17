# Syntax of References

## Introduction

Documentation in Hylo code, and in .hylodoc files is written in markdown. We allow referring to code entities in the
markdown comment similar to as if they were in code. This document describes the syntax of different types of
references.

[](/README.md)
[](../../README.md)
[](module.md)

We need to account for the following use cases in links:

- Reference a local file within the project by relative path
- Reference a local file within the project by an absolute project path
- A web link (http://, https://, ftp://, mailto: etc.)
- Reference to an arbitrary named Hylo code entity

## General Link Syntax in Markdown

There are 3 types of links in markdown:

- Implicit links:      `https://something.com`
- [Autolinks](https://spec.commonmark.org/0.31.2/#autolinks): `<https://something.com>`
- [Full links](https://spec.commonmark.org/0.31.2/#links "title"):      `[Link Text](https://something.com "title")`

The first option (implicit links) is not in the CommonMark standard but many tools support it (Github, IntelliJ,
VSCode).
Often, it only works for links starting with a common protocol like `http://`, `https://`, `ftp://` but not
for `mailto:` or
`tel:`.

The second option is included in the standard and also works for other protocols. `https://`, `tel:`, `mailto:`, etc.)
It is required to include the protocol in the link (except for email addresses) because otherwise it might be
interpreted as an html tag: `<localhost>`.

The third option is the most common and most versatile. It allows for custom link text and title, and is not limited to
requiring the protocol.

## Syntax Design for the Special Cases

Local file references and code symbol references need special care when incorporating them into the existing MarkDown 
syntax. We need to make them expressible easily and unambiguously.

### Local File References

#### Full markdown links:

- `[Link Text](./module.md)` - file in the current directory
- `[Link Text](../module.md)` - file in the parent directory
- `[Link Text](/module.md)` - path starting from the root module
- `[Link Text](~/module.md)` - path starting from the root directory (alternative syntax, not common)
- `[Link Text](module.md)` - file in the current directory (without the `./` prefix)
    - There is possibility of ambiguity here, as `~` is a valid file/folder name in windows. If we want to refer to
      folder or file named `~`, we can use `./~`, thus keeping the `~` prefix reserved for referring to the root module.

[Github uses this syntax](https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax#relative-links)
exclusively for referring to local files. They use the `/` prefix to refer to the repository
root but advise to use relative links generally, as absolute links might not work well in clones of the repository or
when the scope of the project became bigger (e.g. we made our project a subfolder inside another folder).

#### Autolinks:

- `<module.md>`
- `<./module.md>`
- `<../module.md>`
- `</module.md>`
- `<~/module.md>`

Unfortunately, local files and folders can have names like `strong`, `i`, which are also HTML tags which would become
ambiguous: `<strong>` `</i>`. For this reason, most MarkDown parsers do not support this syntax for local files. There
are multiple possible solutions to this problem:

- **In case of ambiguity, interpret it as an html tag.** The problem is that we cannot be sure what tags exist within
  the context of evaluating the markdown, the user might even define their own
  [custom elements](https://developer.mozilla.org/en-US/docs/Web/API/Web_components/Using_custom_elements). Furthermore,
  custom elements are allowed to include `.` in their names, and conversely, file names are allowed to not include an
  extension.
- **Restrict or disallow the use of HTML elements.** Markdown is a small language and it cannot be used to express the
  needs of every user. Therefore, providing an escape hatch for users to express their needs in HTML is a useful feature
  that we should not sacrifice.
- **Require `./`, `~/` or `../` prefixes for local file references.** There are no such tags in HTML, so this would
  eliminate the ambiguity. The resulting references would look like this: `<./module.md>`, `<../module.md>`,
  `<~/module.md>`. This is an intuitive syntax, and it is clear from looking at the reference that it is referring to a
  file.
- Don't allow shorthand for referencing local files. This would leave us with the full link syntax for referring to
  local files: `[Link Text](./module.md)`. This is the most unambiguous syntax, but it is also the most verbose.
  The upside is that local file references would work well with existing tooling, and it is less work for us to
  implement.

### Symbol References
Referring to code entities is a common use case in documentation. We would like to provide a way to refer to these 
entities unambiguously, and respecting the scoping rules of the language (resolving the reference from the parent scope
relative to where the documentation is written).

We assume that when the documentation is outside any top-level code entity (e.g. within a file-level documentation
comment or in a `.hylodoc` file), we are in the scope of the parent module.

Here are some examples of how we could refer to code entities:

```hylo
MyModule.myFunction(x:y:_:)
ParentModule.MyModule.myFunction(x:y:_:)
myFunction(x:y:_:)
MyModule
ParentModule.MyModule
```

It will be possible to refer to any declaration  

#### Writing the Code Entity Name Inside the URL
Rust uses the following syntax:
```markdown
[](std::collections::HashMap::new)
```
Rust has the advantage that it does not have function overloading and its entity paths are separated by `::`.

Hylo paths contain `.` and `:` characters, which are also used in URLs. This makes it more difficult to distinguish
between a URL and a code entity reference.
```markdown
[](MyModule.myFunction(x:y:_:))
```

#### Custom Protocol
Writing a protocol name for referencing Hylo code entities is not the nicest solution, but it is certainly unambiguous.
This would work for both autolinks and full links.
```markdown
<hylo:myMethod(_:_:)>
[](hylo:myMethod(_:_:))
```

#### Double Backticks
This is what Docc uses. It is a concise syntax, and it is clear that it is referring to a code entity, without ambiguity
with URLs.
```markdown
``MyModule.myFunction(x:y:_:)``
```


# Final Design
## URLs
We support autolinks and full Markdown links for arbitrary URLs (except ones with the `file://` protocol). We will not
support implicit links, as they are not part of the CommonMark standard.

## Local File References
We will only support the full link syntax for local file references. The user is required to start the reference with 
either `../`, `./`, or `/`. This is the most unambiguous syntax, and it is also the most common one, supported by all
editors. The `/` prefix will serve as a pointer to the root of the entire project which might be different than the 
module that is currently being documented. This is so that absolute links can be resolved properly in a repository by
GitHub, which takes the root of the repository as the base for resolving absolute links.

## Symbol References
We will use the double backticks syntax for code entity references, just like Swift. This is a concise syntax, and it is
clear that it is referring to a code entity, without ambiguity with URLs.
```markdown
``MyModule.myFunction(x:y:_:)``
```
