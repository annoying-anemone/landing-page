# landing-page

Cigales.cloud landing page site

## Requirements

- [Dev Container / Codespaces](https://code.visualstudio.com/docs/devcontainers/containers)

Or in local environment:

- Docker & Docker Compose v2 (`docker compose`)
- Git

## Installation

- Clone the repository
- For dev container, open the folder in Visual Studio Code and select "Reopen in Container"

## Usage

### Dev container / Codespaces

**All usefull commands are in the `application/package.json`**

#### Start development environment

```shell
cd application

# Install dependencies
npm install

# Start application for development
npm run dev

# Visit website
# Click on CLI link in the dev container:
# Local    http://localhost:xxx/
```

#### Continuous integration tasks

```shell
# Run linter to fix
npm run fix

# Run linter to check
npm run check
```

### Local development

**All usefull commands are in the `Makefile`**

#### Help

```shell
make help
```

#### Start development environment in local

```shell
# Setup stack
make setup

# Start application for development
make start

# Visit website
make web
```

#### Continuous integration

```shell
# Run linter to fix
make lint-fix

# Run linter to check
make lint
```
