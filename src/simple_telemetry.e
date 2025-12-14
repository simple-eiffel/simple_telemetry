note
	description: "[
		Unified telemetry facade providing tracing, metrics, and logging.

		simple_telemetry provides the three pillars of observability:
		- Tracing: Distributed request tracking via spans
		- Metrics: Counters, gauges, and histograms
		- Logging: Structured logs with trace correlation

		W3C Trace Context compatible for distributed tracing.

		Usage:
			telemetry := create {SIMPLE_TELEMETRY}.make ("my-service")

			-- Tracing
			span := telemetry.tracer.start_span ("operation")
			span.set_attribute ("user_id", "123")
			span.end_span

			-- Metrics
			telemetry.meter.new_counter ("requests").increment
			telemetry.meter.new_histogram ("latency_ms").record (42)

			-- Logging (auto-correlates with current span)
			telemetry.logger.info ("Processing request")
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TELEMETRY

create
	make

feature {NONE} -- Initialization

	make (a_service_name: READABLE_STRING_8)
			-- Create telemetry for service.
		require
			name_not_empty: not a_service_name.is_empty
		do
			create service_name.make_from_string (a_service_name)
			create tracer.make (a_service_name)
			create meter.make (a_service_name)
			create logger.make (a_service_name)
			logger.set_tracer (tracer)
			is_enabled := True
		ensure
			service_name_set: service_name.same_string (a_service_name)
			enabled: is_enabled
		end

feature -- Access

	service_name: STRING
			-- Name of the service being instrumented.

	tracer: SIMPLE_TRACER
			-- Tracer for creating spans.

	meter: SIMPLE_METER
			-- Meter for creating metrics.

	logger: SIMPLE_TELEMETRY_LOGGER
			-- Logger with trace correlation.

feature -- Status

	is_enabled: BOOLEAN
			-- Is telemetry enabled?

feature -- Configuration

	enable
			-- Enable telemetry.
		do
			is_enabled := True
			tracer.enable
		ensure
			enabled: is_enabled
		end

	disable
			-- Disable telemetry.
		do
			is_enabled := False
			tracer.disable
		ensure
			disabled: not is_enabled
		end

feature -- Convenience: Tracing

	start_span (a_name: READABLE_STRING_8): SIMPLE_SPAN
			-- Start a new span.
		require
			name_not_empty: not a_name.is_empty
		do
			Result := tracer.start_span (a_name)
		ensure
			span_created: Result /= Void
		end

	with_span (a_name: READABLE_STRING_8; a_action: PROCEDURE)
			-- Execute action within an auto-closing span.
		require
			name_not_empty: not a_name.is_empty
		do
			tracer.with_span (a_name, a_action)
		end

	current_span: detachable SIMPLE_SPAN
			-- Currently active span.
		do
			Result := tracer.current_span
		end

feature -- Convenience: Metrics

	new_counter (a_name: READABLE_STRING_8): SIMPLE_COUNTER
			-- Create or get counter.
		require
			name_not_empty: not a_name.is_empty
		do
			Result := meter.new_counter (a_name)
		ensure
			counter_created: Result /= Void
		end

	new_gauge (a_name: READABLE_STRING_8): SIMPLE_GAUGE
			-- Create or get gauge.
		require
			name_not_empty: not a_name.is_empty
		do
			Result := meter.new_gauge (a_name)
		ensure
			gauge_created: Result /= Void
		end

	new_histogram (a_name: READABLE_STRING_8): SIMPLE_HISTOGRAM
			-- Create or get histogram.
		require
			name_not_empty: not a_name.is_empty
		do
			Result := meter.new_histogram (a_name)
		ensure
			histogram_created: Result /= Void
		end

	increment_counter (a_name: READABLE_STRING_8)
			-- Increment a counter by 1.
		require
			name_not_empty: not a_name.is_empty
		do
			meter.new_counter (a_name).increment
		end

	record_latency (a_name: READABLE_STRING_8; a_ms: REAL_64)
			-- Record latency measurement.
		require
			name_not_empty: not a_name.is_empty
		do
			meter.new_histogram (a_name).record (a_ms)
		end

feature -- Convenience: Logging

	log_debug (a_message: STRING)
			-- Log debug message.
		do
			logger.log_debug (a_message)
		end

	info (a_message: STRING)
			-- Log info message.
		do
			logger.info (a_message)
		end

	warn (a_message: STRING)
			-- Log warning message.
		do
			logger.warn (a_message)
		end

	error (a_message: STRING)
			-- Log error message.
		do
			logger.error (a_message)
		end

feature -- Context Propagation

	extract_context (a_traceparent: READABLE_STRING_8): SIMPLE_TRACE_CONTEXT
			-- Extract trace context from incoming traceparent header.
		require
			valid_header: is_valid_traceparent (a_traceparent)
		do
			create Result.from_traceparent (a_traceparent)
		ensure
			context_created: Result /= Void
		end

	inject_context (a_span: SIMPLE_SPAN): STRING
			-- Get traceparent header for outgoing request.
		require
			span_attached: a_span /= Void
		do
			Result := a_span.context.to_traceparent
		ensure
			valid_header: is_valid_traceparent (Result)
		end

	is_valid_traceparent (a_header: READABLE_STRING_8): BOOLEAN
			-- Is header in valid W3C traceparent format?
		local
			l_ctx: SIMPLE_TRACE_CONTEXT
		do
			create l_ctx.make_new
			Result := l_ctx.is_valid_traceparent (a_header)
		end

feature -- Statistics

	active_span_count: INTEGER
			-- Number of active spans.
		do
			Result := tracer.active_span_count
		end

	completed_span_count: INTEGER
			-- Number of completed spans.
		do
			Result := tracer.completed_span_count
		end

	counter_count: INTEGER
			-- Number of counters.
		do
			Result := meter.counter_count
		end

	gauge_count: INTEGER
			-- Number of gauges.
		do
			Result := meter.gauge_count
		end

	histogram_count: INTEGER
			-- Number of histograms.
		do
			Result := meter.histogram_count
		end

feature -- Export

	export_spans: ARRAYED_LIST [SIMPLE_SPAN]
			-- Get all completed spans.
		do
			Result := tracer.recent_spans (1000)
		end

	export_metrics: STRING
			-- Export all metrics as text.
		do
			create Result.make (500)
			Result.append ("# Counters%N")
			across meter.all_counters as c loop
				Result.append (c.to_string)
				Result.append ("%N")
			end
			Result.append ("%N# Gauges%N")
			across meter.all_gauges as g loop
				Result.append (g.to_string)
				Result.append ("%N")
			end
			Result.append ("%N# Histograms%N")
			across meter.all_histograms as h loop
				Result.append (h.to_string)
				Result.append ("%N")
			end
		end

invariant
	service_name_not_empty: not service_name.is_empty
	tracer_attached: tracer /= Void
	meter_attached: meter /= Void
	logger_attached: logger /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
