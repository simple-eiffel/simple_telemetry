note
	description: "[
		Structured logger with automatic trace correlation.

		Logs automatically include trace_id and span_id from the current
		span context, enabling correlation between logs and traces.

		Usage:
			logger := telemetry.logger
			logger.info ("User logged in")
			-- Output: [INFO] [trace_id=abc123 span_id=def456] User logged in
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TELEMETRY_LOGGER

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create logger with name.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			min_level := Level_debug
			output_to_console := True
			create log_history.make (100)
			history_limit := 100
		ensure
			name_set: name.same_string (a_name)
		end

feature -- Access

	name: STRING
			-- Logger name.

	tracer: detachable SIMPLE_TRACER
			-- Associated tracer for context correlation.

	min_level: INTEGER
			-- Minimum log level to record.

	output_to_console: BOOLEAN
			-- Should logs be written to console?

	history_limit: INTEGER
			-- Maximum logs to keep in history.

feature -- Level Constants

	Level_debug: INTEGER = 0
	Level_info: INTEGER = 1
	Level_warn: INTEGER = 2
	Level_error: INTEGER = 3

feature -- Logging

	log_debug (a_message: STRING)
			-- Log debug message.
		do
			log (Level_debug, a_message)
		end

	info (a_message: STRING)
			-- Log info message.
		do
			log (Level_info, a_message)
		end

	warn (a_message: STRING)
			-- Log warning message.
		do
			log (Level_warn, a_message)
		end

	error (a_message: STRING)
			-- Log error message.
		do
			log (Level_error, a_message)
		end

	log (a_level: INTEGER; a_message: STRING)
			-- Log message at specified level.
		require
			valid_level: a_level >= Level_debug and a_level <= Level_error
		local
			l_entry: SIMPLE_LOG_ENTRY
		do
			if a_level >= min_level then
				create l_entry.make (a_level, a_message)
				-- Add trace context if available
				if attached tracer as t then
					if attached t.current_span as s then
						l_entry.set_trace_context (s.trace_id, s.span_id)
					end
				end
				add_to_history (l_entry)
				if output_to_console then
					io.put_string (l_entry.to_string)
					io.put_new_line
				end
			end
		end

	log_structured (a_level: INTEGER; a_data: HASH_TABLE [ANY, STRING])
			-- Log structured data.
		require
			valid_level: a_level >= Level_debug and a_level <= Level_error
		local
			l_entry: SIMPLE_LOG_ENTRY
		do
			if a_level >= min_level then
				create l_entry.make_structured (a_level, a_data)
				if attached tracer as t then
					if attached t.current_span as s then
						l_entry.set_trace_context (s.trace_id, s.span_id)
					end
				end
				add_to_history (l_entry)
				if output_to_console then
					io.put_string (l_entry.to_string)
					io.put_new_line
				end
			end
		end

feature -- Configuration

	set_tracer (a_tracer: SIMPLE_TRACER)
			-- Set tracer for context correlation.
		do
			tracer := a_tracer
		ensure
			tracer_set: tracer = a_tracer
		end

	set_min_level (a_level: INTEGER)
			-- Set minimum log level.
		require
			valid_level: a_level >= Level_debug and a_level <= Level_error
		do
			min_level := a_level
		ensure
			level_set: min_level = a_level
		end

	enable_console
			-- Enable console output.
		do
			output_to_console := True
		ensure
			enabled: output_to_console
		end

	disable_console
			-- Disable console output.
		do
			output_to_console := False
		ensure
			disabled: not output_to_console
		end

	set_history_limit (a_limit: INTEGER)
			-- Set history limit.
		require
			positive: a_limit > 0
		do
			history_limit := a_limit
		ensure
			limit_set: history_limit = a_limit
		end

feature -- History

	recent_logs (a_count: INTEGER): ARRAYED_LIST [SIMPLE_LOG_ENTRY]
			-- Most recent log entries.
		require
			positive: a_count > 0
		local
			i, start_idx: INTEGER
		do
			create Result.make (a_count)
			start_idx := (log_history.count - a_count + 1).max (1)
			from i := start_idx until i > log_history.count loop
				Result.extend (log_history.i_th (i))
				i := i + 1
			end
		end

	logs_for_trace (a_trace_id: STRING): ARRAYED_LIST [SIMPLE_LOG_ENTRY]
			-- All logs for a specific trace.
		do
			create Result.make (10)
			across log_history as l loop
				if attached l.trace_id as tid and then tid.same_string (a_trace_id) then
					Result.extend (l)
				end
			end
		end

	clear_history
			-- Clear log history.
		do
			log_history.wipe_out
		ensure
			empty: log_history.is_empty
		end

feature {NONE} -- Implementation

	log_history: ARRAYED_LIST [SIMPLE_LOG_ENTRY]
			-- History of log entries.

	add_to_history (a_entry: SIMPLE_LOG_ENTRY)
			-- Add entry to history, trimming if needed.
		do
			log_history.extend (a_entry)
			if log_history.count > history_limit then
				log_history.start
				log_history.remove
			end
		end

invariant
	name_not_empty: not name.is_empty
	valid_min_level: min_level >= Level_debug and min_level <= Level_error
	positive_limit: history_limit > 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
