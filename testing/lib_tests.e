note
	description: "Tests for simple_telemetry library"
	author: "Larry Rix"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature -- Trace Context Tests

	test_trace_context_creation
			-- Test creating new trace context.
		local
			ctx: SIMPLE_TRACE_CONTEXT
		do
			create ctx.make_new
			assert_true ("has_trace_id", ctx.trace_id.count = 32)
			assert_true ("has_span_id", ctx.span_id.count = 16)
			assert_true ("is_valid", ctx.is_valid)
			assert_true ("is_sampled", ctx.is_sampled)
		end

	test_trace_context_child
			-- Test creating child context.
		local
			parent, child: SIMPLE_TRACE_CONTEXT
		do
			create parent.make_new
			create child.make_child (parent)
			assert_true ("same_trace_id", child.trace_id.same_string (parent.trace_id))
			assert_true ("different_span_id", not child.span_id.same_string (parent.span_id))
			assert_true ("has_parent", attached child.parent_span_id)
		end

	test_trace_context_traceparent
			-- Test W3C traceparent format.
		local
			ctx: SIMPLE_TRACE_CONTEXT
			header: STRING
		do
			create ctx.make_new
			header := ctx.to_traceparent
			assert_true ("valid_length", header.count = 55)
			assert_true ("valid_format", ctx.is_valid_traceparent (header))
			assert_true ("has_dashes", header.occurrences ('-') = 3)
		end

	test_trace_context_parse
			-- Test parsing traceparent header.
		local
			original, parsed: SIMPLE_TRACE_CONTEXT
			header: STRING
		do
			create original.make_new
			header := original.to_traceparent
			create parsed.from_traceparent (header)
			assert_true ("trace_id_matches", parsed.trace_id.same_string (original.trace_id))
			assert_true ("span_id_matches", parsed.span_id.same_string (original.span_id))
		end

feature -- Span Tests

	test_span_creation
			-- Test creating a span.
		local
			span: SIMPLE_SPAN
		do
			create span.make ("test-operation", "test-tracer")
			assert_true ("has_name", span.name.same_string ("test-operation"))
			assert_true ("is_active", span.is_active)
			assert_true ("is_recording", span.is_recording)
			assert_true ("has_context", span.context /= Void)
		end

	test_span_attributes
			-- Test span attributes.
		local
			span: SIMPLE_SPAN
		do
			create span.make ("test", "tracer")
			span.set_string_attribute ("user_id", "123")
			span.set_integer_attribute ("count", 42)
			assert_true ("has_user_id", span.attributes.has ("user_id"))
			assert_true ("has_count", span.attributes.has ("count"))
		end

	test_span_events
			-- Test span events.
		local
			span: SIMPLE_SPAN
		do
			create span.make ("test", "tracer")
			span.add_event ("checkpoint")
			assert_true ("has_event", span.events.count = 1)
			assert_true ("event_name", span.events.first.name.same_string ("checkpoint"))
		end

	test_span_end
			-- Test ending a span.
		local
			span: SIMPLE_SPAN
		do
			create span.make ("test", "tracer")
			assert_true ("active_before", span.is_active)
			span.end_span
			assert_true ("not_active_after", not span.is_active)
			assert_true ("has_end_time", span.end_time /= Void)
		end

	test_span_status
			-- Test span status.
		local
			span: SIMPLE_SPAN
		do
			create span.make ("test", "tracer")
			span.set_status_ok
			assert_true ("is_ok", span.status_code = span.Status_ok)
			span.set_status_error ("Something failed")
			assert_true ("is_error", span.status_code = span.Status_error)
			assert_true ("has_message", attached span.status_message)
		end

feature -- Tracer Tests

	test_tracer_creation
			-- Test creating a tracer.
		local
			tracer: SIMPLE_TRACER
		do
			create tracer.make ("test-service")
			assert_true ("has_name", tracer.name.same_string ("test-service"))
			assert_true ("is_enabled", tracer.is_enabled)
			assert_true ("no_current_span", tracer.current_span = Void)
		end

	test_tracer_start_span
			-- Test starting spans.
		local
			tracer: SIMPLE_TRACER
			span: SIMPLE_SPAN
		do
			create tracer.make ("test")
			span := tracer.start_span ("operation")
			assert_true ("span_created", span /= Void)
			assert_true ("is_current", tracer.current_span = span)
			assert_true ("count_one", tracer.active_span_count = 1)
		end

	test_tracer_nested_spans
			-- Test nested spans.
		local
			tracer: SIMPLE_TRACER
			parent, child: SIMPLE_SPAN
		do
			create tracer.make ("test")
			parent := tracer.start_span ("parent")
			child := tracer.start_span ("child")
			assert_true ("child_is_current", tracer.current_span = child)
			assert_true ("same_trace", child.trace_id.same_string (parent.trace_id))
			assert_true ("has_parent_id", attached child.parent_span_id)
			assert_true ("count_two", tracer.active_span_count = 2)
		end

feature -- Metric Tests

	test_counter
			-- Test counter metric.
		local
			counter: SIMPLE_COUNTER
		do
			create counter.make ("requests")
			assert_true ("starts_zero", counter.value = 0)
			counter.increment
			assert_true ("is_one", counter.value = 1)
			counter.add (10)
			assert_true ("is_eleven", counter.value = 11)
		end

	test_gauge
			-- Test gauge metric.
		local
			gauge: SIMPLE_GAUGE
		do
			create gauge.make ("temperature")
			gauge.record (23.5)
			assert_true ("value_set", gauge.value = 23.5)
			gauge.add (1.0)
			assert_true ("value_added", gauge.value = 24.5)
		end

	test_histogram
			-- Test histogram metric.
		local
			histogram: SIMPLE_HISTOGRAM
		do
			create histogram.make ("latency")
			histogram.record (10)
			histogram.record (20)
			histogram.record (30)
			assert_true ("count_three", histogram.count = 3)
			assert_true ("sum_sixty", histogram.sum = 60)
			assert_true ("min_ten", histogram.min = 10)
			assert_true ("max_thirty", histogram.max = 30)
		end

	test_meter
			-- Test meter factory.
		local
			meter: SIMPLE_METER
			c1, c2: SIMPLE_COUNTER
		do
			create meter.make ("test")
			c1 := meter.new_counter ("requests")
			c2 := meter.new_counter ("requests")
			assert_true ("same_counter", c1 = c2)
			assert_true ("one_counter", meter.counter_count = 1)
		end

feature -- Logger Tests

	test_logger_levels
			-- Test logger levels.
		local
			logger: SIMPLE_TELEMETRY_LOGGER
		do
			create logger.make ("test")
			logger.disable_console
			logger.info ("test message")
			assert_true ("logs_recorded", logger.recent_logs (10).count > 0)
		end

	test_logger_trace_correlation
			-- Test log trace correlation.
		local
			tracer: SIMPLE_TRACER
			logger: SIMPLE_TELEMETRY_LOGGER
			span: SIMPLE_SPAN
			logs: ARRAYED_LIST [SIMPLE_LOG_ENTRY]
		do
			create tracer.make ("test")
			create logger.make ("test")
			logger.set_tracer (tracer)
			logger.disable_console
			span := tracer.start_span ("operation")
			logger.info ("within span")
			logs := logger.recent_logs (1)
			assert_true ("has_log", logs.count = 1)
			assert_true ("has_trace_id", attached logs.first.trace_id)
		end

feature -- Telemetry Facade Tests

	test_telemetry_creation
			-- Test creating telemetry facade.
		local
			telemetry: SIMPLE_TELEMETRY
		do
			create telemetry.make ("my-service")
			assert_true ("has_service_name", telemetry.service_name.same_string ("my-service"))
			assert_true ("has_tracer", telemetry.tracer /= Void)
			assert_true ("has_meter", telemetry.meter /= Void)
			assert_true ("has_logger", telemetry.logger /= Void)
		end

	test_telemetry_convenience_tracing
			-- Test convenience tracing methods.
		local
			telemetry: SIMPLE_TELEMETRY
			span: SIMPLE_SPAN
		do
			create telemetry.make ("test")
			span := telemetry.start_span ("operation")
			assert_true ("span_created", span /= Void)
			assert_true ("is_current", telemetry.current_span = span)
		end

	test_telemetry_convenience_metrics
			-- Test convenience metric methods.
		local
			telemetry: SIMPLE_TELEMETRY
		do
			create telemetry.make ("test")
			telemetry.increment_counter ("requests")
			assert_true ("counter_exists", telemetry.counter_count = 1)
			telemetry.record_latency ("latency_ms", 42.0)
			assert_true ("histogram_exists", telemetry.histogram_count = 1)
		end

	test_telemetry_export_metrics
			-- Test metrics export.
		local
			telemetry: SIMPLE_TELEMETRY
			export_text: STRING
		do
			create telemetry.make ("test")
			telemetry.increment_counter ("requests")
			telemetry.new_gauge ("connections").record (5)
			export_text := telemetry.export_metrics
			assert_true ("has_counters", export_text.has_substring ("Counters"))
			assert_true ("has_gauges", export_text.has_substring ("Gauges"))
		end

end
