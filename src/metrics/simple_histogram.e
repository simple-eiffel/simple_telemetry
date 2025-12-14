note
	description: "Distribution metric for recording measurements like latency"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_HISTOGRAM

create
	make,
	make_with_buckets

feature {NONE} -- Initialization

	make (a_name: READABLE_STRING_8)
			-- Create histogram with default buckets.
		require
			name_not_empty: not a_name.is_empty
		do
			create name.make_from_string (a_name)
			create bucket_boundaries.make_from_array ({ARRAY [REAL_64]} <<5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0, 1000.0, 2500.0, 5000.0, 10000.0>>)
			create bucket_counts.make_filled (0, 0, bucket_boundaries.count)
			count := 0
			sum := 0.0
			min := {REAL_64}.max_value
			max := {REAL_64}.min_value
		ensure
			name_set: name.same_string (a_name)
			starts_empty: count = 0
		end

	make_with_buckets (a_name: READABLE_STRING_8; a_buckets: ARRAY [REAL_64])
			-- Create histogram with custom bucket boundaries.
		require
			name_not_empty: not a_name.is_empty
			has_buckets: a_buckets.count > 0
		do
			create name.make_from_string (a_name)
			create bucket_boundaries.make_from_array (a_buckets)
			create bucket_counts.make_filled (0, 0, bucket_boundaries.count)
			count := 0
			sum := 0.0
			min := {REAL_64}.max_value
			max := {REAL_64}.min_value
		ensure
			name_set: name.same_string (a_name)
			buckets_set: bucket_boundaries.count = a_buckets.count
		end

feature -- Access

	name: STRING
			-- Histogram name.

	count: INTEGER_64
			-- Number of recorded values.

	sum: REAL_64
			-- Sum of all recorded values.

	min: REAL_64
			-- Minimum recorded value.

	max: REAL_64
			-- Maximum recorded value.

	mean: REAL_64
			-- Average of recorded values.
		require
			has_values: count > 0
		do
			Result := sum / count
		end

	description: detachable STRING
			-- Optional description.

	unit: detachable STRING
			-- Optional unit of measurement.

	bucket_boundaries: ARRAY [REAL_64]
			-- Upper bounds for each bucket.

	bucket_counts: ARRAY [INTEGER_64]
			-- Count of values in each bucket.

feature -- Recording

	record (a_value: REAL_64)
			-- Record a measurement.
		local
			i: INTEGER
			l_found: BOOLEAN
		do
			count := count + 1
			sum := sum + a_value
			if a_value < min then
				min := a_value
			end
			if a_value > max then
				max := a_value
			end

			-- Find bucket
			from i := bucket_boundaries.lower until i > bucket_boundaries.upper or l_found loop
				if a_value <= bucket_boundaries.item (i) then
					bucket_counts.put (bucket_counts.item (i) + 1, i)
					l_found := True
				end
				i := i + 1
			end
			-- Overflow bucket (last)
			if not l_found then
				bucket_counts.put (bucket_counts.item (bucket_counts.upper) + 1, bucket_counts.upper)
			end
		ensure
			count_increased: count = old count + 1
			sum_increased: sum = old sum + a_value
		end

feature -- Statistics

	percentile (p: REAL_64): REAL_64
			-- Approximate percentile value (0-100).
		require
			has_values: count > 0
			valid_percentile: p >= 0 and p <= 100
		local
			l_target: INTEGER_64
			l_cumulative: INTEGER_64
			i: INTEGER
		do
			l_target := ((p / 100.0) * count).truncated_to_integer_64
			from i := bucket_boundaries.lower until i > bucket_boundaries.upper or l_cumulative >= l_target loop
				l_cumulative := l_cumulative + bucket_counts.item (i)
				if l_cumulative >= l_target then
					Result := bucket_boundaries.item (i)
				end
				i := i + 1
			end
			if l_cumulative < l_target then
				Result := max
			end
		end

	p50: REAL_64
			-- 50th percentile (median).
		require
			has_values: count > 0
		do
			Result := percentile (50)
		end

	p90: REAL_64
			-- 90th percentile.
		require
			has_values: count > 0
		do
			Result := percentile (90)
		end

	p99: REAL_64
			-- 99th percentile.
		require
			has_values: count > 0
		do
			Result := percentile (99)
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
			-- Reset histogram.
		do
			count := 0
			sum := 0.0
			min := {REAL_64}.max_value
			max := {REAL_64}.min_value
			bucket_counts.fill_with (0)
		ensure
			reset: count = 0
		end

feature -- Conversion

	to_string: STRING
			-- String representation.
		do
			create Result.make (100)
			Result.append (name)
			Result.append (": count=")
			Result.append_integer_64 (count)
			if count > 0 then
				Result.append (" min=")
				Result.append (min.out)
				Result.append (" max=")
				Result.append (max.out)
				Result.append (" avg=")
				Result.append (mean.out)
			end
			if attached unit as u then
				Result.append (" ")
				Result.append (u)
			end
		end

invariant
	name_not_empty: not name.is_empty
	non_negative_count: count >= 0
	buckets_match: bucket_counts.count = bucket_boundaries.count + 1

note
	copyright: "Copyright (c) 2025, Larry Rix"
	license: "MIT License"

end
