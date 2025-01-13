# Sub-Menus

Welcome to the Sub-Menus plugin for Redmine!

## Overview

The Sub-Menus plugin enhances your Redmine experience by adding intuitive dropdown menus to project and wiki titles, as well as versatile wiki macros for embedding subproject or wiki subpages as lists or tables directly within your content. These features provide additional ways to navigate through your projects and wiki pages alongside the traditional breadcrumb trail.

🍭 "While the breadcrumb trail guides you back home, Sub-Menus point you straight to the gingerbread house!"

## Installation and Configuration

### Installation

The Sub-Menus plugin is compatible with Redmine versions 4.0.X and above.

1. Download the plugin from https://github.com/modoq/redmine_submenus
2. Extract the plugin files to the `plugins` directory of your Redmine installation.
3. Restart your Redmine server.

### Configuration

Navigate to the Redmine administration panel. Open the configuration of the Plugin and activate/deactivate Sub-Menus for projects and wiki pages. Adjust the dropdown menu symbol to align with your preferences.

## How to Use

### Sub-menus for Projects and Wiki Pages

#### Sub-menus for Projects

When you navigate to a project in Redmine, a dropdown menu icon will appear next to the project title. This menu provides a convenient way to access the subprojects of the current project.&#x20;

Only projects you have access to will be shown. Clicking on a subproject will lead you directly to that subproject while maintaining the current tab context (e.g., Issues, Files, etc.).

#### Sub-menus for Wiki Pages

In the Wiki section of a project, a dropdown menu icon appears next to the wiki page title. The menu lists links to all subpages directly under the current wiki page.

🌶️ These dropdown menus are dynamically generated based on your permissions and the project's structure, making navigation simpler and more intuitive.

### Wiki Macros

The plugin includes two powerful macros to enhance navigation within your wiki content:

#### {{subprojects}}

This macro allows you to embed a list of subprojects directly into a wiki page. Usage:

```
{{subprojects}}
```

##### Options:

- `view=list` (default): Displays the subprojects as a nested list.
- `view=table`: Displays the subprojects in a table format.
- `roles=role1+role2+…+roleX`: Includes columns for specified roles in the table view (e.g., `roles=Manager+Developer`). Use `roles=all` to include all roles.
- `depth=1` (default): Specifies the depth of the hierarchy to display. Increase this to show subprojects at deeper levels.

Example:

```
{{subprojects(view=table, depth=3, roles=Manager+Developer)}}
```

#### {{subwikis}}

This macro enables you to list wiki subpages on a wiki page. Usage:

```
{{subwikis}}
```

##### Options:

- `view=list` (default): Displays the subpages as a nested list.
- `view=table`: Displays the subpages in a table format.
- `depth=1` (default): Specifies the depth of the hierarchy to display. Increase this to show subpages at deeper levels.

Example:

```
{{subwikis(view=table, depth=2)}}
```

These macros provide flexibility for users who prefer structured information directly within their content, offering precise control over the displayed lists or tables.

## Support and Contribution

🩹 If you need assistance or want to contribute to the development of this plugin, visit https://github.com/modoq/redmine_submenus. We welcome your feedback and contributions!

## Licensing

This plugin is licensed under the [MIT License](LICENSE). Refer to the license file for detailed information.

