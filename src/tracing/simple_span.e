note
	description: "[
		A span represents a single unit of work in a trace.

		Spans are the building blocks of distributed tracing. Each span has:
		- Name describing the operation
		- Start and end time
		- Attributes (key-value metadata)
		- Events (timestamped annotations)
		- Status (ok, error)
		- Parent/child relationships

		Usage:
			span := tracer.start_span ("operation")
			span.set_attribute ("user_id", "123")
			span.add_event ("checkpoint")
			-- do work
			span.end_span
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SPAN

create
	make,
	make_with_parent,
	make_with_context

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8; a_tracer_name: READABLE_STRING_8)
			-- Create new root span.
		require
			name_not_empty: not a_name.is_empty
			tracer_name_not_empty: not a_tracer_name.is_empty
		do
			create name.make_from_string (a_name)
			create tracer_name.make_from_string (a_tracer_name)
			create context.make_new
			create start_time.make_now
			create attributes.make (5)
			create events.make (5)
			kind := Kind_internal
			status_code := Status_unset
			is_active := True
			is_recording := True
		ensure
			name_set: name.same_string (a_name)
			is_active: is_active
			is_recording: is_recording
		end

	make_with_parent (a_name: READABLE_STRING_8; a_tracer_name: READABLE_STRING_8; a_parent: SIMPLE_SPAN)
			-- Create child span from parent.
		require
			name_not_empty: not a_name.is_empty
			tracer_name_not_empty: not a_tracer_name.is_empty
			parent_active: a_parent.is_active
		do
			create name.make_from_string (a_name)
			create tracer_name.make_from_string (a_tracer_name)
			create context.make_child (a_parent.context)
			create start_time.make_now
			create attributes.make (5)
			create events.make (5)
			kind := Kind_internal
			status_code := Status_unset
			is_active := True
			is_recording := True
		ensure
			name_set: name.same_string (a_name)
			same_trace: trace_id.same_string (a_parent.trace_id)
			different_span: not span_id.same_string (a_parent.span_id)
			has_parent: attached parent_span_id
		end

	make_with_context (a_name: READABLE_STRING_8; a_tracer_name: READABLE_STRING_8; a_context: SIMPLE_TRACE_CONTEXT)
			-- Create span from external trace context.
		require
			name_not_empty: not a_name.is_empty
			tracer_name_not_empty: not a_tracer_name.is_empty
			context_valid: a_context.is_valid
		do
			create name.make_from_string (a_name)
			create tracer_name.make_from_string (a_tracer_name)
			create context.make_child (a_context)
			create start_time.make_now
			create attributes.make (5)
			create events.make (5)
			kind := Kind_internal
			status_code := Status_unset
			is_active := True
			is_recording := True
		ensure
			name_set: name.same_string (a_name)
			same_trace: trace_id.same_string (a_context.trace_id)
			is_active: is_active
			is_recording: is_recording
		end

feature -- Access

	name: STRING
			-- Span name describing the operation.

	tracer_name: STRING
			-- Name of tracer that created this span.

	context: SIMPLE_TRACE_CONTEXT
			-- Trace context with trace/span IDs.

	trace_id: STRING
			-- Trace identifier (from context).
		do
			Result := context.trace_id
		end

	span_id: STRING
			-- Span identifier (from context).
		do
			Result := context.span_id
		end

	parent_span_id: detachable STRING
			-- Parent span ID if this is a child span.
		do
			Result := context.parent_span_id
		end

	start_time: SIMPLE_DATE_TIME
			-- When span started.

	end_time: detachable SIMPLE_DATE_TIME
			-- When span ended (Void if still active).

	attributes: HASH_TABLE [ANY, STRING]
			-- Span attributes (metadata).

	events: ARRAYED_LIST [SIMPLE_SPAN_EVENT]
			-- Events that occurred during span.

	kind: INTEGER
			-- Span kind (client, server, internal, etc.).

	status_code: INTEGER
			-- Status code (ok, error, unset).

	status_message: detachable STRING
			-- Optional status message (usually for errors).

feature -- Status

	is_active: BOOLEAN
			-- Is span still active (not ended)?

	is_recording: BOOLEAN
			-- Should this span record events and attributes?

	is_sampled: BOOLEAN
			-- Is this span part of a sampled trace?
		do
			Result := context.is_sampled
		end

	duration_ms: INTEGER_64
			-- Duration in milliseconds (0 if not ended).
		local
			l_end: SIMPLE_DATE_TIME
		do
			if attached end_time as et then
				l_end := et
			else
				create l_end.make_now
			end
			Result := duration_between (start_time, l_end)
		end

feature -- Kind constants

	Kind_internal: INTEGER = 0
	Kind_server: INTEGER = 1
	Kind_client: INTEGER = 2
	Kind_producer: INTEGER = 3
	Kind_consumer: INTEGER = 4

feature -- Status constants

	Status_unset: INTEGER = 0
	Status_ok: INTEGER = 1
	Status_error: INTEGER = 2

feature -- Modification

	set_attribute (a_key: STRING; a_value: ANY)
			-- Set span attribute.
		require
			key_not_empty: not a_key.is_empty
			is_recording: is_recording
		do
			attributes.force (a_value, a_key)
		ensure
			has_attribute: attributes.has (a_key)
		end

	set_string_attribute (a_key: STRING; a_value: STRING)
			-- Set string attribute.
		require
			key_not_empty: not a_key.is_empty
			is_recording: is_recording
		do
			attributes.force (a_value, a_key)
		end

	set_integer_attribute (a_key: STRING; a_value: INTEGER_64)
			-- Set integer attribute.
		require
			key_not_empty: not a_key.is_empty
			is_recording: is_recording
		do
			attributes.force (a_value, a_key)
		end

	set_kind (a_kind: INTEGER)
			-- Set span kind.
		require
			valid_kind: a_kind >= Kind_internal and a_kind <= Kind_consumer
		do
			kind := a_kind
		ensure
			kind_set: kind = a_kind
		end

	add_event (a_name: READABLE_STRING_8)
			-- Add event to span.
		require
			name_not_empty: not a_name.is_empty
			is_recording: is_recording
		local
			l_event: SIMPLE_SPAN_EVENT
		do
			create l_event.make (a_name)
			events.extend (l_event)
		ensure
			event_added: events.count = old events.count + 1
		end

	add_event_with_attributes (a_name: READABLE_STRING_8; a_attributes: HASH_TABLE [ANY, STRING])
			-- Add event with attributes.
		require
			name_not_empty: not a_name.is_empty
			is_recording: is_recording
		local
			l_event: SIMPLE_SPAN_EVENT
		do
			create l_event.make_with_data (a_name, a_attributes)
			events.extend (l_event)
		ensure
			event_added: events.count = old events.count + 1
		end

	set_status (a_code: INTEGER; a_message: detachable STRING)
			-- Set span status.
		require
			valid_code: a_code >= Status_unset and a_code <= Status_error
		do
			status_code := a_code
			status_message := a_message
		ensure
			code_set: status_code = a_code
			message_set: status_message = a_message
		end

	set_status_ok
			-- Set status to OK.
		do
			set_status (Status_ok, Void)
		ensure
			is_ok: status_code = Status_ok
		end

	set_status_error (a_message: STRING)
			-- Set status to error with message.
		require
			message_not_empty: not a_message.is_empty
		do
			set_status (Status_error, a_message)
		ensure
			is_error: status_code = Status_error
		end

	end_span
			-- End the span.
		require
			is_active: is_active
		do
			create end_time.make_now
			is_active := False
		ensure
			not_active: not is_active
			has_end_time: end_time /= Void
		end

feature -- Conversion

	to_string: STRING
			-- String representation for logging.
		do
			create Result.make (100)
			Result.append ("[")
			Result.append (context.short_trace_id)
			Result.append (":")
			Result.append (context.short_span_id)
			Result.append ("] ")
			Result.append (name)
			Result.append (" (")
			Result.append_integer_64 (duration_ms)
			Result.append ("ms)")
			if status_code = Status_error then
				Result.append (" ERROR")
				if attached status_message as msg then
					Result.append (": ")
					Result.append (msg)
				end
			end
		end

	kind_name: STRING
			-- Human-readable kind name.
		do
			inspect kind
			when Kind_internal then Result := "INTERNAL"
			when Kind_server then Result := "SERVER"
			when Kind_client then Result := "CLIENT"
			when Kind_producer then Result := "PRODUCER"
			when Kind_consumer then Result := "CONSUMER"
			else Result := "UNKNOWN"
			end
		end

feature {NONE} -- Implementation

	duration_between (a_start, a_end: SIMPLE_DATE_TIME): INTEGER_64
			-- Milliseconds between two times.
		do
			Result := (a_end.to_timestamp - a_start.to_timestamp) * 1000
		end

invariant
	name_not_empty: not name.is_empty
	context_attached: context /= Void
	start_time_attached: start_time /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
