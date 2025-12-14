note
	description: "Event that occurred during a span's lifetime"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_SPAN_EVENT

create
	make,
	make_with_data

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create event with name.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			create timestamp.make_now
			create attributes.make (0)
		ensure
			name_set: name.same_string (a_name)
		end

	make_with_data (a_name: READABLE_STRING_8; a_attributes: HASH_TABLE [ANY, STRING])
			-- Create event with name and attributes.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			create timestamp.make_now
			attributes := a_attributes
		ensure
			name_set: name.same_string (a_name)
			attributes_set: attributes = a_attributes
		end

feature -- Access

	name: STRING
			-- Event name.

	timestamp: SIMPLE_DATE_TIME
			-- When event occurred.

	attributes: HASH_TABLE [ANY, STRING]
			-- Event attributes.

feature -- Modification

	set_attribute (a_key: STRING; a_value: ANY)
			-- Add or update attribute.
		require
			key_not_empty: not a_key.is_empty
		do
			attributes.force (a_value, a_key)
		ensure
			has_attribute: attributes.has (a_key)
		end

feature -- Conversion

	to_string: STRING
			-- String representation.
		do
			create Result.make (50)
			Result.append (name)
			Result.append (" at ")
			Result.append (timestamp.out)
			if attributes.count > 0 then
				Result.append (" (")
				Result.append_integer (attributes.count)
				Result.append (" attrs)")
			end
		end

invariant
	name_not_empty: not name.is_empty
	timestamp_attached: timestamp /= Void

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
