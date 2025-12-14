note
	description: "Factory for creating metric instruments"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_METER

create
	make

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create meter with name.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			create counters.make (10)
			create gauges.make (10)
			create histograms.make (10)
		ensure
			name_set: name.same_string (a_name)
		end

feature -- Access

	name: STRING
			-- Meter name (usually service name).

feature -- Counter Factory

	new_counter (a_name: READABLE_STRING_8): SIMPLE_COUNTER
			-- Create new counter.
		require
			name_not_empty: not a_name.is_empty
		do
			if counters.has (a_name.to_string_8) then
				check attached counters.item (a_name.to_string_8) as c then Result := c end
			else
				create Result.make (a_name)
				counters.put (Result, a_name.to_string_8)
			end
		ensure
			counter_created: Result /= Void
			registered: counters.has (a_name.to_string_8)
		end

	counter (a_name: READABLE_STRING_8): detachable SIMPLE_COUNTER
			-- Get existing counter by name.
		do
			Result := counters.item (a_name.to_string_8)
		end

feature -- Gauge Factory

	new_gauge (a_name: READABLE_STRING_8): SIMPLE_GAUGE
			-- Create new gauge.
		require
			name_not_empty: not a_name.is_empty
		do
			if gauges.has (a_name.to_string_8) then
				check attached gauges.item (a_name.to_string_8) as g then Result := g end
			else
				create Result.make (a_name)
				gauges.put (Result, a_name.to_string_8)
			end
		ensure
			gauge_created: Result /= Void
			registered: gauges.has (a_name.to_string_8)
		end

	gauge (a_name: READABLE_STRING_8): detachable SIMPLE_GAUGE
			-- Get existing gauge by name.
		do
			Result := gauges.item (a_name.to_string_8)
		end

feature -- Histogram Factory

	new_histogram (a_name: READABLE_STRING_8): SIMPLE_HISTOGRAM
			-- Create new histogram with default buckets.
		require
			name_not_empty: not a_name.is_empty
		do
			if histograms.has (a_name.to_string_8) then
				check attached histograms.item (a_name.to_string_8) as h then Result := h end
			else
				create Result.make (a_name)
				histograms.put (Result, a_name.to_string_8)
			end
		ensure
			histogram_created: Result /= Void
			registered: histograms.has (a_name.to_string_8)
		end

	new_histogram_with_buckets (a_name: READABLE_STRING_8; a_buckets: ARRAY [REAL_64]): SIMPLE_HISTOGRAM
			-- Create histogram with custom buckets.
		require
			name_not_empty: not a_name.is_empty
			has_buckets: a_buckets.count > 0
		do
			if histograms.has (a_name.to_string_8) then
				check attached histograms.item (a_name.to_string_8) as h then Result := h end
			else
				create Result.make_with_buckets (a_name, a_buckets)
				histograms.put (Result, a_name.to_string_8)
			end
		ensure
			histogram_created: Result /= Void
		end

	histogram (a_name: READABLE_STRING_8): detachable SIMPLE_HISTOGRAM
			-- Get existing histogram by name.
		do
			Result := histograms.item (a_name.to_string_8)
		end

feature -- Statistics

	counter_count: INTEGER
			-- Number of counters.
		do
			Result := counters.count
		end

	gauge_count: INTEGER
			-- Number of gauges.
		do
			Result := gauges.count
		end

	histogram_count: INTEGER
			-- Number of histograms.
		do
			Result := histograms.count
		end

	all_counters: ARRAYED_LIST [SIMPLE_COUNTER]
			-- All registered counters.
		do
			create Result.make (counters.count)
			across counters as c loop
				Result.extend (c)
			end
		end

	all_gauges: ARRAYED_LIST [SIMPLE_GAUGE]
			-- All registered gauges.
		do
			create Result.make (gauges.count)
			across gauges as g loop
				Result.extend (g)
			end
		end

	all_histograms: ARRAYED_LIST [SIMPLE_HISTOGRAM]
			-- All registered histograms.
		do
			create Result.make (histograms.count)
			across histograms as h loop
				Result.extend (h)
			end
		end

feature {NONE} -- Implementation

	counters: HASH_TABLE [SIMPLE_COUNTER, STRING]
			-- Registered counters.

	gauges: HASH_TABLE [SIMPLE_GAUGE, STRING]
			-- Registered gauges.

	histograms: HASH_TABLE [SIMPLE_HISTOGRAM, STRING]
			-- Registered histograms.

invariant
	name_not_empty: not name.is_empty

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
