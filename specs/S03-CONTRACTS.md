# S03 - Contracts: simple_telemetry

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_telemetry
**Date:** 2026-01-23

## SIMPLE_TELEMETRY Contracts

### Initialization

```eiffel
make (a_service_name: READABLE_STRING_8)
    require
        name_not_empty: not a_service_name.is_empty
    ensure
        service_name_set: service_name.same_string (a_service_name)
        enabled: is_enabled
```

### Tracing Convenience

```eiffel
start_span (a_name: READABLE_STRING_8): SIMPLE_SPAN
    require
        name_not_empty: not a_name.is_empty
    ensure
        span_created: Result /= Void

with_span (a_name: READABLE_STRING_8; a_action: PROCEDURE)
    require
        name_not_empty: not a_name.is_empty
```

### Metrics Convenience

```eiffel
new_counter (a_name: READABLE_STRING_8): SIMPLE_COUNTER
    require
        name_not_empty: not a_name.is_empty
    ensure
        counter_created: Result /= Void

new_gauge (a_name: READABLE_STRING_8): SIMPLE_GAUGE
    require
        name_not_empty: not a_name.is_empty
    ensure
        gauge_created: Result /= Void

new_histogram (a_name: READABLE_STRING_8): SIMPLE_HISTOGRAM
    require
        name_not_empty: not a_name.is_empty
    ensure
        histogram_created: Result /= Void
```

### Context Propagation

```eiffel
extract_context (a_traceparent: READABLE_STRING_8): SIMPLE_TRACE_CONTEXT
    require
        valid_header: is_valid_traceparent (a_traceparent)
    ensure
        context_created: Result /= Void

inject_context (a_span: SIMPLE_SPAN): STRING
    require
        span_attached: a_span /= Void
    ensure
        valid_header: is_valid_traceparent (Result)
```

## SIMPLE_SPAN Contracts

```eiffel
set_attribute (key: STRING; value: ANY)
    require
        key_not_empty: not key.is_empty
        value_attached: value /= Void

add_event (name: STRING)
    require
        name_not_empty: not name.is_empty

end_span
    require
        is_active: is_active
    ensure
        ended: not is_active
        has_end_time: end_time /= Void
```

## SIMPLE_COUNTER Contracts

```eiffel
add (value: INTEGER_64)
    require
        non_negative: value >= 0  -- Counters are monotonic
```

## Invariants

```eiffel
class SIMPLE_TELEMETRY
invariant
    service_name_not_empty: not service_name.is_empty
    tracer_attached: tracer /= Void
    meter_attached: meter /= Void
    logger_attached: logger /= Void
end

class SIMPLE_SPAN
invariant
    trace_id_valid: trace_id.count = 32
    span_id_valid: span_id.count = 16
end
```
