# Website Design

## Table of Contents
- [Getting Started](#getting-started)
- [Updating Templates](#updating-templates)
- [Updating Assets](#updating-assets)

## Getting Started
Install nodejs: https://nodejs.org/en/learn/getting-started/how-to-install-nodejs
Run the following command to verify that it works.
```shell
node -v && npm -v
```

After installing npm we can start working on the web-design with a live preview. This can be done using the `npm run dev` command which will start a webserver from which the pages can be viewed as changes you make get applied.
When your work is done, the `npm run build` command can be used to build the application. In the next two sections you can read more on how this process works and how to apply the changes you have made.

## Updating Templates
After implementing changes to the styling or JavaScript of the web design you might wish to apply changes to the templates used to render the documentation.
For rendering dynamic content the Swift package [Stencil](https://github.com/stencilproject/Stencil) is being used.
The templates can be found at `Sources/WebsiteGen/Resources/templates`. These templates fall into three categories explained in the next three sections.

### 1. Layouts
This category currently consists only of `layout.html` which forms the basic structure of the website deciding where the Breadcrumb, Table of Contents and Tree Navigation go.

### 2. Page Types
This category consists of layout templates for each of the target types: assets and symbols. These files decide which components will be present in the content of the page.
The files for this category can be found directly under the templates directory together with the layout of the website as the template for different page types are a sub-division of layouts.

### 3. Components
This category of templates can be found under `page_components` and consist of each of the parts that make up the content for each of the pages. This category also includes `page_components/tree_item.html` which is used to render the items of the tree navigation.

## Updating Assets
In `vite.config.js` there is an automation defined using the `vite-plugin-cp` dependency to copy certain assets to the Swift project at `Sources/WebsiteGen/Resources/assets` to reduce the manual labour for updating these files when making changes.
Currently the only assets that it copies over are:
- Every (nested) asset in `public/icons`
- Every image with an extension of `[svg,png,jpg,gif]` in `public`
- Bundled CSS from `src/css` and bundled JS from `src/js`

> Note: The SCSS gets minimized during the bundling process. It is therefore required that any class you wish to be present in the bundle is present in a .html file either directly under the `web-design` directory or in the `public` directory.

Adding additional assets might also require you to extend the target list in `vite.config.js` with the files you wish to automatically copy to Swift. The format of these targets and other options can be found at: https://www.npmjs.com/package/vite-plugin-cp.