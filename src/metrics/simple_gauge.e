note
	description: "Point-in-time numeric metric that can go up or down"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_GAUGE

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create gauge with name.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			value := 0.0
		ensure
			name_set: name.same_string (a_name)
			starts_zero: value = 0.0
		end

feature -- Access

	name: STRING
			-- Gauge name.

	value: REAL_64
			-- Current gauge value.

	description: detachable STRING
			-- Optional description.

	unit: detachable STRING
			-- Optional unit of measurement.

feature -- Recording

	record (a_value: REAL_64)
			-- Record current value.
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

	add (a_delta: REAL_64)
			-- Add to current value.
		do
			value := value + a_delta
		ensure
			increased: value = old value + a_delta
		end

	subtract (a_delta: REAL_64)
			-- Subtract from current value.
		do
			value := value - a_delta
		ensure
			decreased: value = old value - a_delta
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

feature -- Conversion

	to_string: STRING
			-- String representation.
		do
			create Result.make (50)
			Result.append (name)
			Result.append (": ")
			Result.append (value.out)
			if attached unit as u then
				Result.append (" ")
				Result.append (u)
			end
		end

invariant
	name_not_empty: not name.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
