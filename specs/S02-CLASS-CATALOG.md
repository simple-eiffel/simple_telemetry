# S02 - Class Catalog: simple_telemetry

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_telemetry
**Date:** 2026-01-23

## Class Hierarchy

```
SIMPLE_TELEMETRY (facade)
|
+-- Tracing
|   +-- SIMPLE_TRACER
|   +-- SIMPLE_SPAN
|   +-- SIMPLE_TRACE_CONTEXT
|   +-- SIMPLE_SPAN_EVENT
|
+-- Metrics
|   +-- SIMPLE_METER
|   +-- SIMPLE_COUNTER
|   +-- SIMPLE_GAUGE
|   +-- SIMPLE_HISTOGRAM
|
+-- Logging
|   +-- SIMPLE_TELEMETRY_LOGGER
|
+-- Exporters
    +-- SIMPLE_CONSOLE_EXPORTER
    +-- SIMPLE_JSON_EXPORTER
```

## Class Descriptions

### SIMPLE_TELEMETRY (Facade)
Main entry point unifying tracing, metrics, and logging. Provides convenience methods and context propagation.

**Creation:** `make (a_service_name: STRING)`

### SIMPLE_TRACER
Creates and manages spans. Maintains current span context and active span stack.

### SIMPLE_SPAN
Single unit of work with:
- Name, start/end time
- Trace ID (32-hex), Span ID (16-hex)
- Parent span reference
- Attributes (key-value)
- Events (timestamped annotations)
- Status (OK, ERROR, UNSET)

### SIMPLE_TRACE_CONTEXT
W3C Trace Context implementation:
- traceparent header format: `{version}-{trace_id}-{span_id}-{flags}`
- tracestate for vendor-specific data

### SIMPLE_SPAN_EVENT
Timestamped annotation within a span with name and optional attributes.

### SIMPLE_METER
Factory for metric instruments. Caches instruments by name.

### SIMPLE_COUNTER
Monotonically increasing value. Supports increment with optional attributes.

### SIMPLE_GAUGE
Point-in-time value. Records current measurement.

### SIMPLE_HISTOGRAM
Distribution of values. Records measurements for statistical analysis.

### SIMPLE_TELEMETRY_LOGGER
Structured logger with automatic trace correlation. Injects trace_id/span_id into log records.

## Class Count Summary
- Facade: 1
- Tracing: 4
- Metrics: 4
- Logging: 1
- Exporters: 2
- **Total: 12 classes**
