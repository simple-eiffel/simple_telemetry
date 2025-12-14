note
	description: "Monotonically increasing counter metric"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_COUNTER

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create counter with name.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			value := 0
		ensure
			name_set: name.same_string (a_name)
			starts_zero: value = 0
		end

feature -- Access

	name: STRING
			-- Counter name.

	value: INTEGER_64
			-- Current counter value.

	description: detachable STRING
			-- Optional description.

	unit: detachable STRING
			-- Optional unit of measurement.

feature -- Recording

	add (a_delta: INTEGER_64)
			-- Add to counter.
		require
			non_negative: a_delta >= 0
		do
			value := value + a_delta
		ensure
			increased: value = old value + a_delta
		end

	increment
			-- Add 1 to counter.
		do
			value := value + 1
		ensure
			incremented: value = old value + 1
		end

feature -- Configuration

	set_description (a_desc: STRING)
			-- Set description.
		do
			description := a_desc
		ensure
			description_set: description = a_desc
		end

	set_unit (a_unit: STRING)
			-- Set unit.
		do
			unit := a_unit
		ensure
			unit_set: unit = a_unit
		end

	reset
			-- Reset counter to zero.
		do
			value := 0
		ensure
			reset: value = 0
		end

feature -- Conversion

	to_string: STRING
			-- String representation.
		do
			create Result.make (50)
			Result.append (name)
			Result.append (": ")
			Result.append_integer_64 (value)
			if attached unit as u then
				Result.append (" ")
				Result.append (u)
			end
		end

invariant
	name_not_empty: not name.is_empty
	non_negative: value >= 0

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
