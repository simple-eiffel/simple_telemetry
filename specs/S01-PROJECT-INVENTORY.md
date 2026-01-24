# S01 - Project Inventory: simple_telemetry

**Document Type:** BACKWASH (reverse-engineered from implementation)
**Library:** simple_telemetry
**Version:** 1.0
**Date:** 2026-01-23

## Overview

Unified telemetry library providing the three pillars of observability: tracing (spans), metrics (counters, gauges, histograms), and logging with W3C Trace Context compatibility.

## Project Files

### Core Source Files
| File | Purpose |
|------|---------|
| `src/simple_telemetry.e` | Main facade class |

### Tracing Source Files
| File | Purpose |
|------|---------|
| `src/tracing/simple_tracer.e` | Span creation and management |
| `src/tracing/simple_span.e` | Individual trace span |
| `src/tracing/simple_trace_context.e` | W3C trace context |
| `src/tracing/simple_span_event.e` | Span event annotations |

### Metrics Source Files
| File | Purpose |
|------|---------|
| `src/metrics/simple_meter.e` | Metric instrument factory |
| `src/metrics/simple_counter.e` | Monotonic counter |
| `src/metrics/simple_gauge.e` | Point-in-time value |
| `src/metrics/simple_histogram.e` | Value distribution |

### Logging Source Files
| File | Purpose |
|------|---------|
| `src/logging/simple_telemetry_logger.e` | Trace-correlated logging |

### Exporter Source Files
| File | Purpose |
|------|---------|
| `src/exporters/simple_console_exporter.e` | Console output |
| `src/exporters/simple_json_exporter.e` | JSON file output |

### Configuration Files
| File | Purpose |
|------|---------|
| `simple_telemetry.ecf` | EiffelStudio project configuration |
| `simple_telemetry.rc` | Windows resource file |

## Dependencies

### ISE Libraries
- base (core Eiffel classes)
- time (DATE_TIME)

### simple_* Libraries
- None required (standalone)

## Build Targets
- `simple_telemetry` - Main library
- `simple_telemetry_tests` - Test suite
