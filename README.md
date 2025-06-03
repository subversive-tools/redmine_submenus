# Redmine Sub-Menus Plugin

> Transform your Redmine navigation with intelligent dropdown menus and powerful portfolio management capabilities.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Redmine Version](https://img.shields.io/badge/Redmine-4.0%2B-red.svg)](https://www.redmine.org/)

## 🚀 What is Sub-Menus?

The Sub-Menus plugin revolutionizes how you navigate and manage projects in Redmine. What starts as enhanced navigation evolves into a comprehensive portfolio management solution.

**Core Features:**
- 🧭 **Smart Navigation**: Dropdown menus for instant access to subprojects and wiki subpages
- 📊 **Portfolio Management**: Visual kanban boards for project organization
- 🎯 **Flexible Views**: List, table, and kanban displays for different use cases
- ⚡ **Interactive Controls**: Drag-and-drop project status management
- 🔧 **Easy Integration**: Works seamlessly with existing Redmine workflows

## 📷 Screenshots

### Project Navigation with Dropdown
![Project dropdown showing subprojects with quick navigation](https://github.com/user-attachments/assets/a22f9dc3-65c9-42e8-b7a6-2216acc74f69)

### Kanban Portfolio View
*Visual project management with status-based organization*

## 🛠️ Installation

### Requirements
- **Redmine**: Version 4.0.0 or higher
- **Ruby**: Compatible with your Redmine installation
- **Permissions**: Admin access for initial setup

### Quick Setup

1. **Download & Extract**
   ```bash
   cd /path/to/redmine/plugins
   git clone https://github.com/modoq/redmine_submenus.git
   ```

2. **Restart Redmine**
   ```bash
   # For development
   bundle exec rails server

   # For production (passenger/nginx)
   sudo systemctl restart redmine
   ```

3. **Configure Plugin**
   - Navigate to **Administration → Plugins**
   - Click **Configure** next to "Sub-Menus"
   - Enable desired features and customize dropdown symbol

### Portfolio Management Setup (Optional)

For kanban functionality, create a custom field:

1. Go to **Administration → Custom Fields → Projects**
2. Create new field with these settings:
   - **Name**: `Project Status`
   - **Format**: `List`
   - **Possible values**: Add your project phases (e.g., `Planning-p`, `Development-i`, `Complete-d`)

## 📖 Usage Guide

### 1. Navigation Dropdowns

**Project Dropdowns**
- Appear automatically next to project titles
- Show accessible subprojects
- Maintain current tab context (Issues, Wiki, etc.)

**Wiki Dropdowns**
- Display on wiki pages with subpages
- Provide quick access to child pages
- Respect user permissions

### 2. Wiki Macros

#### {{subprojects}} - Project Lists & Portfolio Views

**Basic Usage**
```wiki
{{subprojects}}
{{subprojects(view=table)}}
{{subprojects(view=kanban)}}
```

**Advanced Options**
```wiki
{{subprojects(view=table, depth=3, roles=Manager+Developer)}}
{{subprojects(view=kanban)}}
{{subprojects(view=list, depth=2)}}
```

**Parameters:**
- `view`: `list` (default), `table`, or `kanban`
- `depth`: Hierarchy levels to display in list or table view (default: 1)
- `roles`: Show specific roles in table view (`Manager+Developer` or `all`)

#### {{subpages}} - Wiki Navigation

**Usage**
```wiki
{{subpages}}
{{subpages(view=table, depth=2)}}
```

### 3. Kanban Portfolio Management

The kanban view transforms static project lists into interactive portfolio dashboards.

**Features:**
- **Visual Organization**: Projects displayed as cards in status columns
- **Drag & Drop**: Move projects between statuses instantly
- **Real-time Updates**: Changes persist in Redmine database
- **Color Coding**: Visual status indicators with customizable themes
- **Project Details**: Cards show description, team members, and key info

**Status Color Coding:**
- 🟡 **Yellow** (`-p` suffix): Pool of ideas, backlog
- 🔵 **Blue** (`-i` suffix): In-progress, implementation, active 
- 🟢 **Green** (`-d` suffix): Done, deleverd, finished

**Example Status Values:**
```
Ideas-p
Development-i
Testing-i
Deployment-i
Done-d
```

## ⚙️ Configuration

### Plugin Settings

Access via **Administration → Plugins → Sub-Menus → Configure**

| Setting | Description | Default |
|---------|-------------|---------|
| Show Subprojects Menu | Enable project dropdowns | ✅ Enabled |
| Show Subwiki Menu | Enable wiki page dropdowns | ✅ Enabled |
| Dropdown Menu Symbol | Icon for dropdown trigger | `»` |

### Custom Field Setup

For portfolio management features:

1. **Field Name**: Must be exactly `Project Status`
2. **Field Type**: List
3. **Scope**: Projects
4. **Values**: Your workflow statuses (with optional `-p`/`-i`/`-d` suffixes)

## 🎨 Customization

### CSS Styling

The plugin includes comprehensive CSS classes for customization:

```css
/* Dropdown menus */
.drdn { /* Dropdown container */ }
.drdn-trigger { /* Clickable trigger */ }
.drdn-content { /* Dropdown content */ }

/* Kanban boards */
.kanban-board { /* Board container */ }
.kanban-column { /* Status columns */ }
.kanban-card { /* Project cards */ }

/* Status colors */
.meta-pool { /* Planning phase */ }
.meta-implementation { /* Active phase */ }
.meta-done { /* Completed phase */ }
```

### Status Suffix System

Organize your workflow with intelligent status naming:

- **Planning Phase**: `Research-p`, `Design-p`, `Planning-p`
- **Implementation Phase**: `Development-i`, `Testing-i`, `Review-i`
- **Completion Phase**: `Deployed-d`, `Closed-d`, `Archived-d`

## 🔧 Troubleshooting

### Common Issues

**Dropdown not appearing?**
- Check plugin is enabled in Administration
- Verify user has access to subprojects/subpages
- Ensure subprojects exist and are active

**Kanban view shows warning?**
- Create "Project Status" custom field (exact name required)
- Set field type to "List"
- Add at least one possible value

**Drag & drop not working?**
- Check browser JavaScript is enabled
- Verify user has project edit permissions
- Ensure custom field is properly configured


## 🤝 Contributing

We welcome contributions! Here's how to get started:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/yourusername/redmine_submenus.git

# Link to development Redmine
ln -s /path/to/redmine_submenus /path/to/redmine/plugins/

# Test changes
bundle exec rails server
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

- 🐛 **Issues**: [GitHub Issues](https://github.com/modoq/redmine_submenus/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/modoq/redmine_submenus/discussions)
- 📧 **Contact**: [Project Author](https://github.com/modoq)

---

*"From breadcrumbs to portfolio boards - navigate your projects like never before."*
