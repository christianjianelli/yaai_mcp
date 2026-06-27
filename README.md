# yaai_mcp
ABAP AI tools - MCP tools

This repository provides a set of Model Context Protocol (MCP) tools built on top of the ABAP AI Tools Function Calling library. It exposes these tools as REST endpoints, allowing the [abap-mcp-server](https://github.com/christianjianelli/abap-mcp-server) to serve them to any MCP-compatible clients.  

This library is part of the [ABAP AI tools](https://github.com/christianjianelli/yaai) ecosystem.

## Available Tools

### ABAP Dictionary (DDIC) Management

- **Domains**
  - Read, search, create, update, delete domains
  - Manage fixed values
  - Manage translations for domain fixed values

- **Data Elements**
  - Read, search, create, update, delete data elements with built-in types or domain references
  - Manage translations for data element labels

- **Structures**
  - Read, search, create, update, delete structures

- **Tables**
  - Read, search, create, update, delete transparent tables
  - Manage technical settings (data class, size category)

- **Table Types**
  - Read, search, create, update, delete table types

- **CDS views**
  - Read, search, create, update, delete CDS views

### SQL Tools

- **SQL**
  - Perform SELECT, INSERT, UPDATE and DELETE statements on the SAP system

### Transport Management

- **Transport Requests**
  - Create workbench and customizing requests
  - Search and read transport request details

### ABAP Coding

- **ABAP Class**
  - Read, search, create, update, check, activate ABAP Classes

- **ABAP Interface**
  - Read, search, create, update, check, activate ABAP Interfaces

- **ABAP Function Module**
  - Read ABAP function module source code

- **ABAP Program/Include** 
  - Read ABAP program/include source code


## Installation

### Prerequisites

The ABAP system must have the following package installed:

 - **[ABAP AI tools](https://github.com/christianjianelli/yaai)**
 - **[ABAP AI tools - Function Calling Library](https://github.com/christianjianelli/yaai_fc)**

### Installation Steps

See the [Installation Guide](/docs/installation.md)