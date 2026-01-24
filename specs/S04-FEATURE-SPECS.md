# S04 - Feature Specifications: simple_telemetry

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_telemetry
**Date:** 2026-01-23

## Core Features

### SIMPLE_TELEMETRY (Facade)

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `(service_name: STRING)` | Create telemetry facade |
| `service_name` | `: STRING` | Service identifier |
| `tracer` | `: SIMPLE_TRACER` | Tracer instance |
| `meter` | `: SIMPLE_METER` | Meter instance |
| `logger` | `: SIMPLE_TELEMETRY_LOGGER` | Logger instance |
| `is_enabled` | `: BOOLEAN` | Telemetry enabled? |
| `enable` | `()` | Enable telemetry |
| `disable` | `()` | Disable telemetry |
| `start_span` | `(name: STRING): SIMPLE_SPAN` | Start new span |
| `with_span` | `(name: STRING; action: PROCEDURE)` | Auto-closing span |
| `current_span` | `: detachable SIMPLE_SPAN` | Active span |
| `new_counter` | `(name: STRING): SIMPLE_COUNTER` | Create counter |
| `new_gauge` | `(name: STRING): SIMPLE_GAUGE` | Create gauge |
| `new_histogram` | `(name: STRING): SIMPLE_HISTOGRAM` | Create histogram |
| `increment_counter` | `(name: STRING)` | Increment by 1 |
| `record_latency` | `(name: STRING; ms: REAL_64)` | Record latency |
| `log_debug` | `(message: STRING)` | Debug log |
| `info` | `(message: STRING)` | Info log |
| `warn` | `(message: STRING)` | Warning log |
| `error` | `(message: STRING)` | Error log |
| `extract_context` | `(traceparent: STRING): SIMPLE_TRACE_CONTEXT` | Parse incoming |
| `inject_context` | `(span: SIMPLE_SPAN): STRING` | Generate outgoing |
| `export_spans` | `: LIST [SIMPLE_SPAN]` | Get completed spans |
| `export_metrics` | `: STRING` | Export metrics text |

### SIMPLE_TRACER

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make` | `(name: STRING)` | Create tracer |
| `start_span` | `(name: STRING): SIMPLE_SPAN` | Start span |
| `start_span_with_parent` | `(name: STRING; parent: SIMPLE_SPAN): SIMPLE_SPAN` | Child span |
| `with_span` | `(name: STRING; action: PROCEDURE)` | Scoped span |
| `current_span` | `: detachable SIMPLE_SPAN` | Active span |
| `enable` | `()` | Enable tracing |
| `disable` | `()` | Disable tracing |
| `active_span_count` | `: INTEGER` | Open spans |
| `completed_span_count` | `: INTEGER` | Closed spans |
| `recent_spans` | `(limit: INTEGER): LIST [SIMPLE_SPAN]` | Get recent spans |

### SIMPLE_SPAN

| Feature | Signature | Description |
|---------|-----------|-------------|
| `name` | `: STRING` | Span name |
| `trace_id` | `: STRING` | 32-hex trace ID |
| `span_id` | `: STRING` | 16-hex span ID |
| `parent_span_id` | `: detachable STRING` | Parent ID |
| `start_time` | `: DATE_TIME` | Start timestamp |
| `end_time` | `: detachable DATE_TIME` | End timestamp |
| `is_active` | `: BOOLEAN` | Still running? |
| `set_attribute` | `(key: STRING; value: ANY)` | Add attribute |
| `add_event` | `(name: STRING)` | Add event |
| `set_status` | `(code: INTEGER; message: STRING)` | Set status |
| `end_span` | `()` | Complete span |
| `context` | `: SIMPLE_TRACE_CONTEXT` | Get context |

### SIMPLE_TRACE_CONTEXT

| Feature | Signature | Description |
|---------|-----------|-------------|
| `make_new` | `()` | Generate new IDs |
| `from_traceparent` | `(header: STRING)` | Parse header |
| `trace_id` | `: STRING` | Trace ID |
| `span_id` | `: STRING` | Span ID |
| `trace_flags` | `: INTEGER` | Flags (sampled) |
| `to_traceparent` | `: STRING` | Generate header |
| `is_valid_traceparent` | `(header: STRING): BOOLEAN` | Validate format |

### Metrics Classes

| Class | Feature | Description |
|-------|---------|-------------|
| SIMPLE_COUNTER | `increment` | Add 1 |
| SIMPLE_COUNTER | `add(n)` | Add n (n >= 0) |
| SIMPLE_COUNTER | `value` | Current value |
| SIMPLE_GAUGE | `record(v)` | Set value |
| SIMPLE_GAUGE | `value` | Current value |
| SIMPLE_HISTOGRAM | `record(v)` | Record measurement |
| SIMPLE_HISTOGRAM | `count` | Number of recordings |
| SIMPLE_HISTOGRAM | `sum` | Sum of values |
| SIMPLE_HISTOGRAM | `min` | Minimum value |
| SIMPLE_HISTOGRAM | `max` | Maximum value |

## W3C Trace Context Format

```
traceparent: {version}-{trace_id}-{span_id}-{flags}
Example: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01

version:   00 (2 hex digits)
trace_id:  32 hex digits (128-bit)
span_id:   16 hex digits (64-bit)
flags:     01 = sampled, 00 = not sampled
```
