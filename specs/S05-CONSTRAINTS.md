# S05 - Constraints: simple_telemetry

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_telemetry
**Date:** 2026-01-23

## Identifier Constraints

### Trace ID
```
Format:  32 hexadecimal characters
Bits:    128
Example: 0af7651916cd43dd8448eb211c80319c
```

### Span ID
```
Format:  16 hexadecimal characters
Bits:    64
Example: b7ad6b7169203331
```

### Service Name
- Must not be empty
- Recommended: lowercase with hyphens
- Example: "my-service", "user-api"

## Span Constraints

### Lifecycle
```eiffel
-- A span must be ended exactly once
is_active = True  --> end_span --> is_active = False

-- Cannot end an already-ended span
end_span requires is_active
```

### Timing
```eiffel
-- End time must be after or equal to start time
end_time >= start_time (guaranteed by implementation)
```

### Hierarchy
- A span can have at most one parent
- Parent must be active when child is created
- Child inherits trace_id from parent

## Counter Constraints

### Monotonicity
```eiffel
-- Counters can only increase
add (value: INTEGER_64)
    require
        non_negative: value >= 0
```

### Value Range
```
Type: INTEGER_64
Min:  0
Max:  9,223,372,036,854,775,807
```

## Histogram Constraints

### Recording
- Any REAL_64 value can be recorded
- Negative values allowed (e.g., temperature)
- Implementation maintains: count, sum, min, max

## W3C Trace Context Constraints

### traceparent Header
```
Pattern: ^00-[a-f0-9]{32}-[a-f0-9]{16}-[0-9a-f]{2}$

Invalid if:
- trace_id is all zeros
- span_id is all zeros
- version is not 00
```

### Flags
```
0x00 = not sampled
0x01 = sampled
Other values reserved
```

## Memory Constraints

### Span Retention
- Completed spans retained in memory
- `recent_spans(limit)` returns most recent
- No automatic pruning (manual export needed)

### Attribute Limits
- No hard limit on attributes per span
- Recommended: < 128 attributes
- Keys should be short strings

## Threading Constraints

### Not Thread-Safe
- SIMPLE_TRACER assumes single-threaded access
- For SCOOP: wrap in separate processor
- current_span is per-tracer, not global

### Context Propagation
- Manual propagation via traceparent header
- Inject before outgoing HTTP requests
- Extract from incoming HTTP requests

## OTEL Compatibility

### Semantic Conventions
Following OpenTelemetry naming where applicable:
- `http.method`, `http.status_code`
- `db.system`, `db.statement`
- `rpc.service`, `rpc.method`

### Export Format
- Not OTLP compatible (future)
- Console and JSON exporters only
