note
	description: "Test application for simple_telemetry"
	author: "Larry Rix"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run tests.
		local
			tests: LIB_TESTS
		do
			create tests
			io.put_string ("simple_telemetry test runner%N")
			io.put_string ("===============================%N%N")

			passed := 0
			failed := 0

			-- Trace Context Tests
			io.put_string ("Trace Context Tests%N")
			io.put_string ("-------------------%N")
			run_test (agent tests.test_trace_context_creation, "test_trace_context_creation")
			run_test (agent tests.test_trace_context_child, "test_trace_context_child")
			run_test (agent tests.test_trace_context_traceparent, "test_trace_context_traceparent")
			run_test (agent tests.test_trace_context_parse, "test_trace_context_parse")

			-- Span Tests
			io.put_string ("%NSpan Tests%N")
			io.put_string ("----------%N")
			run_test (agent tests.test_span_creation, "test_span_creation")
			run_test (agent tests.test_span_attributes, "test_span_attributes")
			run_test (agent tests.test_span_events, "test_span_events")
			run_test (agent tests.test_span_end, "test_span_end")
			run_test (agent tests.test_span_status, "test_span_status")

			-- Tracer Tests
			io.put_string ("%NTracer Tests%N")
			io.put_string ("------------%N")
			run_test (agent tests.test_tracer_creation, "test_tracer_creation")
			run_test (agent tests.test_tracer_start_span, "test_tracer_start_span")
			run_test (agent tests.test_tracer_nested_spans, "test_tracer_nested_spans")

			-- Metric Tests
			io.put_string ("%NMetric Tests%N")
			io.put_string ("------------%N")
			run_test (agent tests.test_counter, "test_counter")
			run_test (agent tests.test_gauge, "test_gauge")
			run_test (agent tests.test_histogram, "test_histogram")
			run_test (agent tests.test_meter, "test_meter")

			-- Logger Tests
			io.put_string ("%NLogger Tests%N")
			io.put_string ("------------%N")
			run_test (agent tests.test_logger_levels, "test_logger_levels")
			run_test (agent tests.test_logger_trace_correlation, "test_logger_trace_correlation")

			-- Telemetry Facade Tests
			io.put_string ("%NTelemetry Facade Tests%N")
			io.put_string ("----------------------%N")
			run_test (agent tests.test_telemetry_creation, "test_telemetry_creation")
			run_test (agent tests.test_telemetry_convenience_tracing, "test_telemetry_convenience_tracing")
			run_test (agent tests.test_telemetry_convenience_metrics, "test_telemetry_convenience_metrics")
			run_test (agent tests.test_telemetry_export_metrics, "test_telemetry_export_metrics")

			io.put_string ("%N===============================%N")
			io.put_string ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				io.put_string ("TESTS FAILED%N")
			else
				io.put_string ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				io.put_string ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			io.put_string ("  FAIL: " + a_name + "%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
