# Development Rules

## General

- Never redesign the architecture.
- Never introduce new frameworks.
- Never create unnecessary features.
- Keep the MVP simple.

---

## Backend

Language: Python

Framework: FastAPI

Use asyncio only.

Do not use Flask.

Do not use Django.

SQLite only.

---

## Flutter

Material 3

No Riverpod

No Bloc

API driven.

---

## Dashboard

HTML

Tailwind CDN

Vanilla JavaScript

No React.

No Vue.

---

## Architecture

Flutter must never communicate directly with the Proxy.

Everything goes through FastAPI.

Proxy owns business logic.

Dashboard is read-only.