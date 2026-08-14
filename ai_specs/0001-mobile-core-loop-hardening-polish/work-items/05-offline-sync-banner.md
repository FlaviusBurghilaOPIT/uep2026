---
type: Work Item
title: Persistent Offline Sync Banner for Pending Dose Queue
parent: ../spec.md
---

## What to build

Render a persistent top banner ("Saved offline. Will sync when connected.") whenever the local pending-dose-log queue has un-flushed entries, so patients logging offline know their entry wasn't lost. Clear the banner automatically once the queue successfully flushes to the backend.

## Required context

- `docs/product/10-implementation-plan.md` Issue #12.
- `docs/product/03-safety-and-edge-cases.md` Case 3 (Offline Use When a Dose Is Logged) and Case 4 (App Restarted Before Sync).
- `docs/ux/06-content-system.md` Category 9 for exact banner copy.
- **Open question carried from the Spec:** the exact current location/shape of the offline pending-dose-log queue (referred to as `PendingQueueTable` in `docs/ux/08-prioritized-ux-backlog.md` but not yet located in a source-file scan) — confirm during implementation; it likely lives in or near `mobile/lib/features/today/providers/today_agenda_notifier.dart` or a local persistence layer introduced by earlier offline-handling work.
- `docs/product/09-measurement-plan.md` §2.4 — `Un-Synced Offline Log Stagnation` safety counter-metric needs a timestamp on queued entries to be computable.

## Acceptance criteria

- [x] Banner with the exact copy from `docs/ux/06-content-system.md` Category 9 renders on `Today` whenever the pending queue is non-empty.
- [x] Banner clears automatically immediately after a successful background flush of all queued entries.
- [x] Queued entries carry a timestamp sufficient to compute the `>24h` un-synced-stagnation safety counter-metric later (this Work Item does not need to compute/display that metric itself, only make it computable).
- [x] Unit test simulating: log while offline → banner state true → simulated reconnect/flush → banner state false.

## Covers

- User Stories: 6
- Requirements: Interactive Notifications & Reliability 13
- Interview Ledger: L1

## Blocked by

4 — lands after the interactive-notifications Work Item since both touch the same offline-log write path.
