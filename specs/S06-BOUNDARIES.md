# S06 - Boundaries: simple_telemetry

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_telemetry
**Date:** 2026-01-23

## Scope Boundaries

### In Scope
- Distributed tracing (spans, trace context)
- Metrics (counters, gauges, histograms)
- Structured logging with trace correlation
- W3C Trace Context propagation
- Console and JSON export

### Out of Scope
- **OTLP export** - No Jaeger/Zipkin/OTLP backends
- **Auto-instrumentation** - Manual instrumentation only
- **Sampling strategies** - All spans recorded
- **Baggage propagation** - No W3C Baggage support
- **Metric aggregation** - Raw values only
- **Log file rotation** - External responsibility

## API Boundaries

### Public API (SIMPLE_TELEMETRY facade)
- Tracing convenience methods
- Metrics convenience methods
- Logging convenience methods
- Context propagation

### Internal API (not exported)
- ID generation
- Span storage
- Metric calculation internals

## Integration Boundaries

### Input Boundaries

| Input Type | Format | Validation |
|------------|--------|------------|
| Service name | STRING | Non-empty |
| Span name | STRING | Non-empty |
| Metric name | STRING | Non-empty |
| Counter value | INTEGER_64 | >= 0 |
| traceparent | STRING | W3C format |

### Output Boundaries

| Output Type | Format | Notes |
|-------------|--------|-------|
| Trace ID | 32-hex STRING | Lowercase |
| Span ID | 16-hex STRING | Lowercase |
| traceparent | W3C STRING | version-trace-span-flags |
| Metrics export | TEXT | Counter: name=value |

## Performance Boundaries

### Expected Performance

| Operation | Time | Notes |
|-----------|------|-------|
| start_span | < 1 ms | ID generation |
| end_span | < 1 ms | Timestamp only |
| increment_counter | < 1 us | Integer add |
| record_histogram | < 1 us | Min/max update |

### Memory Usage

| Component | Per Instance | Notes |
|-----------|--------------|-------|
| Span | ~500 bytes | Without attributes |
| Counter | ~100 bytes | Name + value |
| Histogram | ~200 bytes | Stats + name |

## Extension Points

### Custom Exporters
1. Implement exporter interface
2. Receive completed spans/metrics
3. Format and send to backend

### Custom Samplers
1. Not currently supported
2. Future: implement sampler interface

## Dependency Boundaries

### Required Dependencies
- EiffelBase
- time library (DATE_TIME)

### Optional Dependencies
- simple_http (for OTLP export, future)
- simple_json (for JSON export)

## Interoperability

### Propagation Format
- W3C Trace Context (traceparent header)
- Compatible with: OpenTelemetry, Jaeger, Zipkin

### Not Compatible With
- B3 propagation (Zipkin legacy)
- AWS X-Ray format
- Datadog format
