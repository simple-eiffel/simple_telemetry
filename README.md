<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.png" alt="simple_ library logo" width="400">
</p>

# simple_telemetry

**[Documentation](https://simple-eiffel.github.io/simple_telemetry/)** | **[GitHub](https://github.com/simple-eiffel/simple_telemetry)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()
[![SCOOP](https://img.shields.io/badge/SCOOP-compatible-orange.svg)]()

Distributed observability for Eiffel: tracing, metrics, and structured logging (OpenTelemetry-compatible).

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Beta**

## Overview

simple_telemetry provides observability primitives for Eiffel applications including distributed tracing with span context, metrics collection with counters/gauges/histograms, and structured logging with correlation IDs. Designed for OpenTelemetry compatibility.

```eiffel
-- Create a trace span
local
    telemetry: SIMPLE_TELEMETRY
    span: SIMPLE_SPAN
do
    create telemetry.make
    span := telemetry.start_span ("process_order")
    -- ... do work ...
    span.finish
end
```

## Features

- **Distributed Tracing** - Spans, trace context propagation
- **Metrics** - Counters, gauges, histograms
- **Structured Logging** - JSON logs with correlation IDs
- **Context Propagation** - Trace context across services
- **SCOOP Compatible** - Thread-safe telemetry collection

## Installation

1. Set the ecosystem environment variable (one-time setup for all simple_* libraries):
```bash
export SIMPLE_EIFFEL=/path/to/prod
```

2. Add to ECF:
```xml
<library name="simple_telemetry" location="$SIMPLE_EIFFEL/simple_telemetry/simple_telemetry.ecf"/>
```

## Dependencies

- simple_datetime - Timestamps

## License

MIT License
