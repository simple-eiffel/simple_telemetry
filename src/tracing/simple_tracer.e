note
	description: "[
		Creates and manages spans for distributed tracing.

		A tracer creates spans that represent units of work. Spans can be
		nested to form a trace tree showing the call hierarchy.

		Usage:
			tracer := create {SIMPLE_TRACER}.make ("my-service")

			-- Start a span
			span := tracer.start_span ("operation")
			span.set_attribute ("user_id", "123")

			-- Nested span (child of current)
			child := tracer.start_span ("sub-operation")
			child.end_span

			span.end_span

			-- Or use scoped spans
			tracer.with_span ("operation", agent do_work)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_TRACER

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create tracer with name.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			create span_stack.make (10)
			create completed_spans.make (100)
			is_enabled := True
		ensure
			name_set: name.same_string (a_name)
			enabled: is_enabled
		end

feature -- Access

	name: STRING
			-- Tracer name (usually service name).

	current_span: detachable SIMPLE_SPAN
			-- Currently active span (top of stack).
		do
			if not span_stack.is_empty then
				Result := span_stack.item
			end
		end

	active_span_count: INTEGER
			-- Number of active spans.
		do
			Result := span_stack.count
		end

	completed_span_count: INTEGER
			-- Number of completed spans.
		do
			Result := completed_spans.count
		end

feature -- Status

	is_enabled: BOOLEAN
			-- Is tracing enabled?

feature -- Span Creation

	start_span (a_name: READABLE_STRING_8): SIMPLE_SPAN
			-- Start a new span as child of current span (or root if none).
		require
			name_not_empty: not a_name.is_empty
		do
			if attached current_span as l_parent then
				create Result.make_with_parent (a_name, name, l_parent)
			else
				create Result.make (a_name, name)
			end
			span_stack.put (Result)
		ensure
			span_created: Result /= Void
			span_active: Result.is_active
			span_pushed: current_span = Result
		end

	start_span_with_parent (a_name: READABLE_STRING_8; a_parent: SIMPLE_SPAN): SIMPLE_SPAN
			-- Start a new span as child of specific parent.
		require
			name_not_empty: not a_name.is_empty
			parent_active: a_parent.is_active
		do
			create Result.make_with_parent (a_name, name, a_parent)
			span_stack.put (Result)
		ensure
			span_created: Result /= Void
			same_trace: Result.trace_id.same_string (a_parent.trace_id)
		end

	start_span_with_kind (a_name: READABLE_STRING_8; a_kind: INTEGER): SIMPLE_SPAN
			-- Start span with specific kind.
		require
			name_not_empty: not a_name.is_empty
			valid_kind: a_kind >= {SIMPLE_SPAN}.Kind_internal and a_kind <= {SIMPLE_SPAN}.Kind_consumer
		do
			Result := start_span (a_name)
			Result.set_kind (a_kind)
		ensure
			span_created: Result /= Void
			kind_set: Result.kind = a_kind
		end

	start_span_with_context (a_name: READABLE_STRING_8; a_context: SIMPLE_TRACE_CONTEXT): SIMPLE_SPAN
			-- Start span from external trace context (e.g., incoming HTTP request).
		require
			name_not_empty: not a_name.is_empty
			context_valid: a_context.is_valid
		do
			create Result.make_with_context (a_name, name, a_context)
			span_stack.put (Result)
		ensure
			span_created: Result /= Void
			same_trace: Result.trace_id.same_string (a_context.trace_id)
		end

feature -- Span Lifecycle

	end_current_span
			-- End the current span.
		require
			has_current_span: current_span /= Void
		do
			if attached span_stack.item as l_span then
				l_span.end_span
				span_stack.remove
				completed_spans.extend (l_span)
			end
		ensure
			stack_decreased: active_span_count = old active_span_count - 1
		end

	end_span (a_span: SIMPLE_SPAN)
			-- End a specific span.
		require
			span_attached: a_span /= Void
			span_active: a_span.is_active
		do
			a_span.end_span
			-- Remove from stack if it's there
			remove_from_stack (a_span)
			completed_spans.extend (a_span)
		ensure
			span_ended: not a_span.is_active
		end

feature -- Scoped Spans

	with_span (a_name: READABLE_STRING_8; a_action: PROCEDURE)
			-- Execute action within a span that's automatically ended.
		require
			name_not_empty: not a_name.is_empty
			action_attached: a_action /= Void
		local
			l_span: SIMPLE_SPAN
			l_retried: BOOLEAN
		do
			if not l_retried then
				l_span := start_span (a_name)
				a_action.call (Void)
				l_span.set_status_ok
				end_span (l_span)
			end
		rescue
			if attached current_span as l_err_span then
				if l_err_span.is_active then
					l_err_span.set_status_error ("Exception occurred")
					end_span (l_err_span)
				end
			end
			l_retried := True
			retry
		end

feature -- Configuration

	enable
			-- Enable tracing.
		do
			is_enabled := True
		ensure
			enabled: is_enabled
		end

	disable
			-- Disable tracing.
		do
			is_enabled := False
		ensure
			disabled: not is_enabled
		end

feature -- History

	recent_spans (a_count: INTEGER): ARRAYED_LIST [SIMPLE_SPAN]
			-- Most recently completed spans (up to count).
		require
			positive_count: a_count > 0
		local
			i, start_idx: INTEGER
		do
			create Result.make (a_count)
			start_idx := (completed_spans.count - a_count + 1).max (1)
			from i := start_idx until i > completed_spans.count loop
				Result.extend (completed_spans.i_th (i))
				i := i + 1
			end
		end

	clear_history
			-- Clear completed spans.
		do
			completed_spans.wipe_out
		ensure
			empty: completed_span_count = 0
		end

feature {NONE} -- Implementation

	span_stack: ARRAYED_STACK [SIMPLE_SPAN]
			-- Stack of active spans.

	completed_spans: ARRAYED_LIST [SIMPLE_SPAN]
			-- History of completed spans.

	remove_from_stack (a_span: SIMPLE_SPAN)
			-- Remove span from stack if present.
		local
			l_temp: ARRAYED_LIST [SIMPLE_SPAN]
		do
			-- Only remove from top if it matches
			if not span_stack.is_empty and then span_stack.item = a_span then
				span_stack.remove
			end
		end

invariant
	name_not_empty: not name.is_empty
	span_stack_attached: span_stack /= Void
	completed_spans_attached: completed_spans /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
