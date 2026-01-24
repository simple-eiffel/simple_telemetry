# S07 - Specification Summary: simple_telemetry

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_telemetry
**Date:** 2026-01-23

## Executive Summary

simple_telemetry provides the three pillars of observability (tracing, metrics, logging) in a unified Eiffel library with W3C Trace Context compatibility for distributed systems.

## Key Statistics

| Metric | Value |
|--------|-------|
| Total Classes | 12 |
| Public Features | ~50 |
| LOC (estimated) | ~1500 |
| Dependencies | base, time |

## Architecture Overview

```
+-------------------+
|SIMPLE_TELEMETRY   |  <-- Facade
+-------------------+
    |       |       |
+------+ +-----+ +------+
|Tracer| |Meter| |Logger|
+------+ +-----+ +------+
    |       |
+-----+ +-------+
|Span | |Counter|
+-----+ |Gauge  |
    |   |Histo  |
+-------+-------+
|  Context      |
+---------------+
```

## Core Value Proposition

1. **Unified API** - Single facade for all observability
2. **Contract-Driven** - DBC for span lifecycle
3. **W3C Compatible** - Standard trace propagation
4. **Correlated Logs** - Automatic trace/span injection
5. **Pure Eiffel** - No external dependencies

## Contract Summary

| Category | Preconditions | Postconditions |
|----------|---------------|----------------|
| Span creation | Name not empty | Span active |
| Span end | Must be active | Not active, has end_time |
| Counter add | Value >= 0 | Value increased |
| Context parse | Valid traceparent | Context created |

## Feature Categories

| Category | Count | Purpose |
|----------|-------|---------|
| Tracing | 15 | Spans, context |
| Metrics | 12 | Counter, gauge, histogram |
| Logging | 5 | Correlated logging |
| Config | 4 | Enable/disable |
| Export | 4 | Console, JSON |

## Constraints Summary

1. Trace ID: 32-hex, Span ID: 16-hex
2. Counters are monotonic (value >= 0)
3. Spans must be ended exactly once
4. Not thread-safe (use SCOOP)

## Known Limitations

1. No OTLP/Jaeger/Zipkin export
2. No sampling (all spans recorded)
3. No auto-instrumentation
4. Manual context propagation

## Integration Points

| Library | Integration |
|---------|-------------|
| simple_http | Inject/extract context in HTTP headers |
| simple_sql | Database span instrumentation |
| simple_logger | Log correlation |

## Future Directions

1. OTLP exporter for backends
2. Sampling strategies
3. Auto-instrumentation hooks
4. Baggage propagation
