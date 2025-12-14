note
	description: "[
		W3C Trace Context compatible trace/span identification.

		Implements the W3C Trace Context specification for distributed tracing.
		Format: traceparent = {version}-{trace-id}-{span-id}-{flags}

		Example: 00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01

		Usage:
			ctx := create {SIMPLE_TRACE_CONTEXT}.make_new
			header := ctx.to_traceparent

			-- Or parse from incoming request
			ctx2 := create {SIMPLE_TRACE_CONTEXT}.from_traceparent (header)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TRACE_CONTEXT

create
	make_new,
	make_child,
	from_traceparent

feature {NONE} -- Initialization

	make_new
			-- Create new trace context with generated IDs.
		do
			version := "00"
			trace_id := generate_trace_id
			span_id := generate_span_id
			trace_flags := 1  -- Sampled by default
		ensure
			version_set: version.same_string ("00")
			trace_id_valid: trace_id.count = 32
			span_id_valid: span_id.count = 16
		end

	make_child (a_parent: SIMPLE_TRACE_CONTEXT)
			-- Create child context from parent (same trace, new span).
		require
			parent_attached: a_parent /= Void
		do
			version := a_parent.version
			trace_id := a_parent.trace_id.twin
			parent_span_id := a_parent.span_id.twin
			span_id := generate_span_id
			trace_flags := a_parent.trace_flags
			trace_state := a_parent.trace_state
		ensure
			same_trace: trace_id.same_string (a_parent.trace_id)
			different_span: not span_id.same_string (a_parent.span_id)
			parent_linked: attached parent_span_id as p implies p.same_string (a_parent.span_id)
		end

	from_traceparent (a_header: READABLE_STRING_8)
			-- Parse from W3C traceparent header.
		require
			header_not_empty: not a_header.is_empty
			valid_format: is_valid_traceparent (a_header)
		local
			l_parts: LIST [READABLE_STRING_8]
		do
			l_parts := a_header.split ('-')
			version := l_parts.i_th (1).to_string_8
			trace_id := l_parts.i_th (2).to_string_8
			span_id := l_parts.i_th (3).to_string_8
			trace_flags := hex_to_integer (l_parts.i_th (4).to_string_8)
		ensure
			trace_id_set: not trace_id.is_empty
			span_id_set: not span_id.is_empty
		end

feature -- Access

	version: STRING
			-- Version of trace context format (always "00").

	trace_id: STRING
			-- 32-hex trace identifier (shared across all spans in trace).

	span_id: STRING
			-- 16-hex span identifier (unique per span).

	parent_span_id: detachable STRING
			-- Parent span ID if this is a child span.

	trace_flags: INTEGER
			-- Trace flags (bit 0 = sampled).

	trace_state: detachable STRING
			-- Optional vendor-specific trace state.

feature -- Status

	is_sampled: BOOLEAN
			-- Should this trace be recorded?
		do
			Result := (trace_flags & 1) = 1
		end

	is_valid: BOOLEAN
			-- Is this context valid?
		do
			Result := trace_id.count = 32 and span_id.count = 16
		end

feature -- Conversion

	to_traceparent: STRING
			-- Convert to W3C traceparent header format.
		do
			create Result.make (55)
			Result.append (version)
			Result.append_character ('-')
			Result.append (trace_id)
			Result.append_character ('-')
			Result.append (span_id)
			Result.append_character ('-')
			Result.append (integer_to_hex (trace_flags, 2))
		ensure
			valid_format: is_valid_traceparent (Result)
		end

	short_trace_id: STRING
			-- First 8 characters of trace ID (for display).
		do
			Result := trace_id.substring (1, 8)
		end

	short_span_id: STRING
			-- First 8 characters of span ID (for display).
		do
			Result := span_id.substring (1, 8)
		end

feature -- Modification

	set_sampled (a_sampled: BOOLEAN)
			-- Set sampled flag.
		do
			if a_sampled then
				trace_flags := trace_flags | 1
			else
				trace_flags := trace_flags & 0xFE
			end
		ensure
			sampled_set: is_sampled = a_sampled
		end

	set_trace_state (a_state: STRING)
			-- Set vendor-specific trace state.
		do
			trace_state := a_state
		ensure
			state_set: trace_state = a_state
		end

feature -- Validation

	is_valid_traceparent (a_header: READABLE_STRING_8): BOOLEAN
			-- Is header in valid traceparent format?
		local
			l_parts: LIST [READABLE_STRING_8]
		do
			if a_header.count = 55 and a_header.occurrences ('-') = 3 then
				l_parts := a_header.split ('-')
				if l_parts.count = 4 then
					Result := l_parts.i_th (1).count = 2 and
							  l_parts.i_th (2).count = 32 and
							  l_parts.i_th (3).count = 16 and
							  l_parts.i_th (4).count = 2
				end
			end
		end

feature {NONE} -- Implementation

	generate_trace_id: STRING
			-- Generate 32-hex trace ID.
		do
			Result := generate_hex_id (32)
		ensure
			valid_length: Result.count = 32
		end

	generate_span_id: STRING
			-- Generate 16-hex span ID.
		do
			Result := generate_hex_id (16)
		ensure
			valid_length: Result.count = 16
		end

	generate_hex_id (a_length: INTEGER): STRING
			-- Generate random hex string of given length.
		local
			l_random: RANDOM
			l_seed: INTEGER
			l_dt: SIMPLE_DATE_TIME
			i: INTEGER
			l_counter: INTEGER
		do
			create l_dt.make_now
			l_counter := shared_id_counter.item
			l_seed := (l_dt.to_timestamp \\ 1000000).as_integer_32 + l_counter
			shared_id_counter.put (l_counter + 1)
			create l_random.set_seed (l_seed)
			l_random.forth

			create Result.make (a_length)
			from i := 1 until i > a_length loop
				l_random.forth
				Result.append_character (hex_chars.item ((l_random.item \\ 16) + 1))
				i := i + 1
			end
		end

	hex_chars: STRING = "0123456789abcdef"
			-- Hexadecimal characters.

	shared_id_counter: CELL [INTEGER]
			-- Shared counter across all instances to ensure unique IDs.
		once
			create Result.put (0)
		end

	hex_to_integer (a_hex: READABLE_STRING_8): INTEGER
			-- Convert hex string to integer.
		local
			i: INTEGER
			c: CHARACTER
		do
			from i := 1 until i > a_hex.count loop
				c := a_hex.item (i).as_lower
				Result := Result * 16
				if c >= '0' and c <= '9' then
					Result := Result + (c.code - ('0').code)
				elseif c >= 'a' and c <= 'f' then
					Result := Result + (c.code - ('a').code + 10)
				end
				i := i + 1
			end
		end

	integer_to_hex (a_value: INTEGER; a_length: INTEGER): STRING
			-- Convert integer to hex string of given length.
		local
			l_val, l_digit: INTEGER
			i: INTEGER
		do
			create Result.make_filled ('0', a_length)
			l_val := a_value
			from i := a_length until i < 1 or l_val = 0 loop
				l_digit := l_val \\ 16
				Result.put (hex_chars.item (l_digit + 1), i)
				l_val := l_val // 16
				i := i - 1
			end
		end

invariant
	version_valid: version.count = 2
	trace_id_valid: trace_id.count = 32
	span_id_valid: span_id.count = 16

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
