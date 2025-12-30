# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

pg_graphql is a PostgreSQL extension (written in Rust using pgrx) that adds GraphQL support directly to PostgreSQL. It reflects a GraphQL schema from the existing SQL schema and resolves queries entirely within the database.

## Build Commands

```bash
# Build and install the extension to the pgrx-managed Postgres
cargo pgrx install

# Build and install with specific PostgreSQL version (14-18 supported)
cargo pgrx install --features pg16

# Build for release
cargo pgrx install --release --features pg16
```

## Testing

Tests are SQL-based regression tests in `test/sql/` with expected outputs in `test/expected/`.

```bash
# Build and run all tests (requires pgrx install first)
cargo pgrx install; ./bin/installcheck

# Run a single test (e.g., test/sql/aliases.sql)
./bin/installcheck aliases

# Run tests via Docker (CI approach)
PG_VERSION=16 docker compose -f .ci/docker-compose.yml run test
```

When writing or modifying tests:
- Test outputs go to `./results/`
- If the result in `./results/` is correct, copy it to `./test/expected/` to update the expected output
- Use `pgrx_pg_sys::submodules::elog::info!` macro to debug (output appears in `.out` files)

## Interactive Development

```bash
# Launch psql with extension installed
cargo pgrx run pg16

# Then in psql:
create extension pg_graphql cascade;
select graphql.resolve($$ { __typename } $$);
```

## Architecture

### Core Flow
1. `lib.rs` - Entry point, exposes `graphql._internal_resolve()` function to PostgreSQL
2. `sql/resolve.sql` - Wraps the internal function as `graphql.resolve()` with error handling
3. `graphql.rs` - GraphQL schema types (`__Schema`, type definitions, introspection)
4. `sql_types.rs` - Loads PostgreSQL catalog metadata (tables, columns, functions, foreign keys, etc.)
5. `builder.rs` - Builds query/mutation execution plans from parsed GraphQL
6. `transpile.rs` - Transpiles execution plans to SQL and executes via SPI
7. `resolve.rs` - Orchestrates parsing, validation, and execution of GraphQL documents

### Key Modules
- `graphql.rs` (~173KB) - GraphQL type system, schema reflection, field resolution logic
- `transpile.rs` - SQL generation with parameterized queries
- `sql_types.rs` - PostgreSQL catalog introspection, directive parsing (`@graphql({...})`)
- `builder.rs` - AST builders for queries, mutations, connections, aggregates
- `parser_util.rs` - GraphQL document parsing utilities
- `merge.rs` - Field merging for GraphQL selection sets

### SQL Components
- `sql/directives.sql` - Comment directive parsing functions
- `sql/load_sql_context.sql` - Loads database schema metadata
- `sql/resolve.sql` - Public API wrapper with exception handling

## Configuration

Configuration uses SQL comment directives in the format `@graphql({...})`:
- Schema level: `comment on schema public is e'@graphql({"inflect_names": true})'`
- Table level: `comment on table foo is e'@graphql({"totalCount": {"enabled": true}})'`
- Column/constraint level for renaming fields and relationships

## Supported PostgreSQL Versions

Features in Cargo.toml: pg14, pg15, pg16, pg17, pg18 (default is pg18)
