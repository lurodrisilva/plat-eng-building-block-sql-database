# CloudNativePG 1.28 Documentation Summary

This note summarizes the main topics covered on the CloudNativePG 1.28
documentation landing page.

## What CloudNativePG Is

- Kubernetes operator for PostgreSQL that manages clusters via a `Cluster` custom
resource.
- Primary instance handles writes; optional replicas provide high availability and
read scaling.
- Uses declarative configuration and automation for Day 2 operations.
- Supports in-cluster and external application connectivity, including PgBouncer
pooling.

## Architecture and Operation Basics

- Operator manages services for read-write and read-only access to instances.
- Automated failover and switchover are core behaviors; no manual intervention
required.
- Replica clusters enable distributed topologies across multiple Kubernetes
clusters.
- Persistent volumes are managed directly (not via StatefulSets).

## Container Images

- Operator images are published in GitHub Container Registry with Debian
distroless and UBI variants, signed with SBOM/provenance attestations.
- PostgreSQL operand images are provided for supported Debian releases and PG
versions, with `minimal` and `standard` flavors.
- `system` images are deprecated; plan to move to `minimal` or `standard` with a
supported backup approach.

## Core Features

- High availability with automated failover, replica recreation, and optional
synchronous replication.
- Declarative management of PostgreSQL settings, roles, databases, schemas,
extensions, and tablespaces.
- Scalable instance counts with read-write and read-only services.
- Backup and recovery via CNPG-I plugins, including WAL archiving and PITR.
- Volume snapshot backups where storage classes support them.
- TLS support with custom certificates and client authentication.
- Rolling updates for operator and PostgreSQL minor versions.
- JSON logging and Prometheus metrics endpoint.
- `kubectl` plugin for operational workflows.
- Hibernation and fencing for operational safety and resource control.

## Getting Started Pointers

- Quickstart for local testing (Kind or Minikube).
- "Before you start" for Kubernetes and PostgreSQL prerequisites.
- Supported Kubernetes versions are listed in the Supported releases page.