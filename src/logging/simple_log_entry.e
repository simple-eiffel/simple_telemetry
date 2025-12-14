note
	description: "A single log entry with optional trace correlation"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_LOG_ENTRY

create
	make,
	make_structured

feature {NONE} -- Initialization

	make (a_level: INTEGER; a_message: STRING)
			-- Create log entry.
		require
			valid_level: a_level >= 0 and a_level <= 3
		do
			level := a_level
			create message.make_from_string (a_message)
			create timestamp.make_now
			create attributes.make (0)
		ensure
			level_set: level = a_level
			message_set: message.same_string (a_message)
		end

	make_structured (a_level: INTEGER; a_data: HASH_TABLE [ANY, STRING])
			-- Create structured log entry.
		require
			valid_level: a_level >= 0 and a_level <= 3
		do
			level := a_level
			if attached {STRING} a_data.item ("message") as m then
				create message.make_from_string (m)
			else
				create message.make_from_string ("(structured)")
			end
			create timestamp.make_now
			attributes := a_data
		ensure
			level_set: level = a_level
		end

feature -- Access

	level: INTEGER
			-- Log level (0=DEBUG, 1=INFO, 2=WARN, 3=ERROR).

	message: STRING
			-- Log message.

	timestamp: DATE_TIME
			-- When log was created.

	attributes: HASH_TABLE [ANY, STRING]
			-- Structured attributes.

	trace_id: detachable STRING
			-- Trace ID for correlation.

	span_id: detachable STRING
			-- Span ID for correlation.

feature -- Modification

	set_trace_context (a_trace_id, a_span_id: STRING)
			-- Set trace context.
		do
			trace_id := a_trace_id.twin
			span_id := a_span_id.twin
		ensure
			trace_id_set: attached trace_id as t implies t.same_string (a_trace_id)
			span_id_set: attached span_id as s implies s.same_string (a_span_id)
		end

	set_attribute (a_key: STRING; a_value: ANY)
			-- Add attribute.
		do
			attributes.force (a_value, a_key)
		end

feature -- Conversion

	level_name: STRING
			-- Human-readable level name.
		do
			inspect level
			when 0 then Result := "DEBUG"
			when 1 then Result := "INFO"
			when 2 then Result := "WARN"
			when 3 then Result := "ERROR"
			else Result := "UNKNOWN"
			end
		end

	to_string: STRING
			-- String representation.
		local
			l_keys: ARRAY [STRING]
			i: INTEGER
			l_first: BOOLEAN
		do
			create Result.make (100)
			Result.append ("[")
			Result.append (level_name)
			Result.append ("] ")

			-- Add trace context if available
			if attached trace_id as tid then
				Result.append ("[trace_id=")
				Result.append (tid.substring (1, (8).min (tid.count)))
				if attached span_id as sid then
					Result.append (" span_id=")
					Result.append (sid.substring (1, (8).min (sid.count)))
				end
				Result.append ("] ")
			end

			Result.append (message)

			-- Add attributes if any
			if attributes.count > 0 then
				Result.append (" {")
				l_keys := attributes.current_keys
				l_first := True
				from i := l_keys.lower until i > l_keys.upper loop
					if not l_first then
						Result.append (", ")
					end
					Result.append (l_keys.item (i))
					Result.append ("=")
					if attached attributes.item (l_keys.item (i)) as l_val then
						if attached {STRING} l_val as str then
							Result.append (str)
						else
							Result.append (l_val.out)
						end
					end
					l_first := False
					i := i + 1
				end
				Result.append ("}")
			end
		end

invariant
	valid_level: level >= 0 and level <= 3
	message_attached: message /= Void
	timestamp_attached: timestamp /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
