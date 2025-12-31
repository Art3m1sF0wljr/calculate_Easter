using Dates

# ===============================
# Calendar Date Types
# ===============================

struct JulianDate
    year::Int
    month::Int
    day::Int
end

struct GregorianDate
    year::Int
    month::Int
    day::Int
end

struct RevisedJulianDate
    year::Int
    month::Int
    day::Int
end

# ===============================
# Leap Year Functions
# ===============================

function is_julian_leap_year(year::Int)
    """Julian calendar: leap year if divisible by 4."""
    return year % 4 == 0
end

function is_gregorian_leap_year(year::Int)
    """Gregorian calendar: leap year if divisible by 4, but not by 100 unless divisible by 400."""
    return (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0)
end

function is_revised_julian_leap_year(year::Int)
    """
    Revised Julian calendar: 
    - Divisible by 4 AND not divisible by 100, OR
    - Divisible by 900 with remainder 200 OR 600
    """
    if (year % 4 == 0) && (year % 100 != 0)
        return true
    elseif year % 900 == 200 || year % 900 == 600
        return true
    else
        return false
    end
end

# ===============================
# Accurate Calendar Conversions
# ===============================

function julian_to_gregorian_acc(jd::JulianDate)
    """
    Convert Julian date to Gregorian date using accurate offset calculation.
    The offset depends on the century and accounts for the Gregorian reform in 1582.
    """
    year, month, day = jd.year, jd.month, jd.day
    
    # For dates after 1582, calculate offset based on century
    if year >= 1582
        # Calculate centuries since year 1
        centuries = div(year - 1, 100)
        
        # Offset formula: 10 days initially, plus 1 day for each non-Gregorian-leap-century
        offset = 10
        for c in 16:centuries
            century_year = c * 100 + 1
            if !is_gregorian_leap_year(century_year)
                offset += 1
            end
        end
        
        # Apply offset
        gdate = Date(year, month, day) + Day(offset)
        return GregorianDate(year(gdate), month(gdate), day(gdate))
    else
        # Before Gregorian reform, Julian was the official calendar
        return GregorianDate(year, month, day)
    end
end

function gregorian_to_julian_acc(gd::GregorianDate)
    """
    Convert Gregorian date to Julian date using accurate offset calculation.
    """
    year, month, day = gd.year, gd.month, gd.day
    
    if year >= 1582
        # Calculate centuries since year 1
        centuries = div(year - 1, 100)
        
        # Calculate offset (same as in julian_to_gregorian)
        offset = 10
        for c in 16:centuries
            century_year = c * 100 + 1
            if !is_gregorian_leap_year(century_year)
                offset += 1
            end
        end
        
        # Subtract offset
        jdate = Date(year, month, day) - Day(offset)
        return JulianDate(year(jdate), month(jdate), day(jdate))
    else
        return JulianDate(year, month, day)
    end
end

function gregorian_to_revised_julian_acc(gd::GregorianDate)
    """
    Convert Gregorian to Revised Julian.
    They differ only when their leap year rules give different results.
    """
    year, month, day = gd.year, gd.month, gd.day
    
    # If leap year status is the same, dates are identical
    if is_gregorian_leap_year(year) == is_revised_julian_leap_year(year)
        return RevisedJulianDate(year, month, day)
    else
        # They differ! This happens in years like 2800, 2900, etc.
        # The Revised Julian calendar will have Feb 29 when Gregorian doesn't, or vice versa
        
        # Create a date object and check if it's affected by leap year differences
        date_obj = Date(year, month, day)
        
        # The difference only matters for dates after February
        if month > 2 || (month == 2 && day == 29)
            # After February, if one is leap and other isn't, dates shift
            if is_gregorian_leap_year(year) && !is_revised_julian_leap_year(year)
                # Gregorian has Feb 29 but Revised Julian doesn't
                # So from March 1 onward, Revised Julian is one day behind
                if month > 2 || (month == 2 && day == 29)
                    new_date = date_obj - Day(1)
                    return RevisedJulianDate(year(new_date), month(new_date), day(new_date))
                end
            elseif !is_gregorian_leap_year(year) && is_revised_julian_leap_year(year)
                # Revised Julian has Feb 29 but Gregorian doesn't
                # So from March 1 onward, Revised Julian is one day ahead
                if month > 2
                    new_date = date_obj + Day(1)
                    return RevisedJulianDate(year(new_date), month(new_date), day(new_date))
                end
            end
        end
        return RevisedJulianDate(year, month, day)
    end
end

function revised_julian_to_gregorian_acc(rjd::RevisedJulianDate)
    """
    Convert Revised Julian to Gregorian.
    Inverse of gregorian_to_revised_julian_acc.
    """
    year, month, day = rjd.year, rjd.month, rjd.day
    
    if is_gregorian_leap_year(year) == is_revised_julian_leap_year(year)
        return GregorianDate(year, month, day)
    else
        date_obj = Date(year, month, day)
        
        if month > 2 || (month == 2 && day == 29)
            if is_gregorian_leap_year(year) && !is_revised_julian_leap_year(year)
                if month > 2 || (month == 2 && day == 29)
                    new_date = date_obj + Day(1)
                    return GregorianDate(year(new_date), month(new_date), day(new_date))
                end
            elseif !is_gregorian_leap_year(year) && is_revised_julian_leap_year(year)
                if month > 2
                    new_date = date_obj - Day(1)
                    return GregorianDate(year(new_date), month(new_date), day(new_date))
                end
            end
        end
        return GregorianDate(year, month, day)
    end
end

function julian_to_revised_julian_acc(jd::JulianDate)
    """
    Convert Julian to Revised Julian via Gregorian.
    """
    greg = julian_to_gregorian_acc(jd)
    return gregorian_to_revised_julian_acc(greg)
end

function revised_julian_to_julian_acc(rjd::RevisedJulianDate)
    """
    Convert Revised Julian to Julian via Gregorian.
    """
    greg = revised_julian_to_gregorian_acc(rjd)
    return gregorian_to_julian_acc(greg)
end

# ===============================
# Easter Computations (Corrected)
# ===============================

function catholic_easter_corrected(year::Int)
    """Compute Catholic Easter in Gregorian calendar."""
    a = year % 19
    b = div(year, 100)
    c = year % 100
    d = div(b, 4)
    e = b % 4
    f = div(b + 8, 25)
    g = div(b - f + 1, 3)
    h = (19 * a + b - d - g + 15) % 30
    i = div(c, 4)
    k = c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = div(a + 11 * h + 22 * l, 451)
    
    month = div(h + l - 7 * m + 114, 31)
    day = ((h + l - 7 * m + 114) % 31) + 1
    
    return GregorianDate(year, month, day)
end

function orthodox_easter_julian_corrected(year::Int)
    """Compute Orthodox Easter in Julian calendar (Russian tradition)."""
    # Using Meeus Julian algorithm
    a = year % 4
    b = year % 7
    c = year % 19
    d = (19 * c + 15) % 30
    e = (2 * a + 4 * b - d + 34) % 7
    
    month = 3  # March
    day = d + e + 22
    
    if day > 31
        month = 4
        day -= 31
    end
    
    return JulianDate(year, month, day)
end

function orthodox_easter_revised_julian_corrected(year::Int)
    """Compute Orthodox Easter in Revised Julian calendar (Romanian tradition)."""
    # Most Revised Julian churches use the Gregorian calculation for Easter
    # after adopting the Revised Julian calendar in 1923
    if year >= 1923
        # Use Gregorian Easter calculation but interpret it in Revised Julian calendar
        greg_easter = catholic_easter_corrected(year)
        # Convert to Revised Julian calendar
        return gregorian_to_revised_julian_acc(greg_easter)
    else
        # Before 1923, use Julian calendar calculation
        julian_easter = orthodox_easter_julian_corrected(year)
        # Convert Julian to Revised Julian
        return julian_to_revised_julian_acc(julian_easter)
    end
end

# ===============================
# Display Functions
# ===============================

function show_calendar_info(year::Int)
    """Show information about calendar differences for a given year."""
    println("\n" * "="^60)
    println("CALENDAR INFORMATION FOR YEAR $year")
    println("="^60)
    
    # Leap year status
    println("\nLeap Year Status:")
    println("  Julian:       $(is_julian_leap_year(year) ? "LEAP" : "Common")")
    println("  Gregorian:    $(is_gregorian_leap_year(year) ? "LEAP" : "Common")")
    println("  Revised Jul:  $(is_revised_julian_leap_year(year) ? "LEAP" : "Common")")
    
    # Calculate offset between Julian and Gregorian
    if year >= 1582
        centuries = div(year - 1, 100)
        offset = 10
        for c in 16:centuries
            century_year = c * 100 + 1
            if !is_gregorian_leap_year(century_year)
                offset += 1
            end
        end
        println("\nJulian-Gregorian Offset: $offset days")
        println("  (Julian calendar is $offset days behind Gregorian)")
    end
    
    # Check for divergence between Gregorian and Revised Julian
    if is_gregorian_leap_year(year) != is_revised_julian_leap_year(year)
        println("\n⚠️  WARNING: Gregorian and Revised Julian calendars DIVERGE in $year")
        if is_gregorian_leap_year(year)
            println("  Gregorian has Feb 29, Revised Julian does NOT")
        else
            println("  Revised Julian has Feb 29, Gregorian does NOT")
        end
    else
        println("\nGregorian and Revised Julian calendars AGREE in $year")
    end
    
    # Show future divergence points
    if year >= 2800
        println("\nFuture divergence years:")
        println("  2800: Revised Julian leap, Gregorian common")
        println("  2900: Revised Julian common, Gregorian common")
        println("  3000: Both common")
        println("  3100: Revised Julian common, Gregorian common")
        println("  3200: Revised Julian leap, Gregorian leap")
    end
end

function compute_all_easters_corrected(year::Int)
    println("\n" * "="^60)
    println("EASTER COMPUTATIONS FOR YEAR $year")
    println("="^60)
    
    # Compute Easters
    cath_easter = catholic_easter_corrected(year)
    orth_j_easter = orthodox_easter_julian_corrected(year)
    orth_r_easter = orthodox_easter_revised_julian_corrected(year)
    
    # Display in native calendars
    println("\n1. CATHOLIC EASTER (Gregorian):")
    println("   Date: $(cath_easter.year)-$(lpad(cath_easter.month, 2, '0'))-$(lpad(cath_easter.day, 2, '0'))")
    
    println("\n2. ORTHODOX EASTER - Russian (Julian):")
    println("   Date: $(orth_j_easter.year)-$(lpad(orth_j_easter.month, 2, '0'))-$(lpad(orth_j_easter.day, 2, '0'))")
    
    println("\n3. ORTHODOX EASTER - Romanian (Revised Julian):")
    println("   Date: $(orth_r_easter.year)-$(lpad(orth_r_easter.month, 2, '0'))-$(lpad(orth_r_easter.day, 2, '0'))")
    
    # Conversions
    println("\n" * "="^60)
    println("CONVERSIONS")
    println("="^60)
    
    # Catholic to others
    println("\nCatholic Easter in other calendars:")
    cath_to_jul = gregorian_to_julian_acc(cath_easter)
    cath_to_rev = gregorian_to_revised_julian_acc(cath_easter)
    println("  Julian:       $(cath_to_jul.year)-$(lpad(cath_to_jul.month, 2, '0'))-$(lpad(cath_to_jul.day, 2, '0'))")
    println("  Revised Jul:  $(cath_to_rev.year)-$(lpad(cath_to_rev.month, 2, '0'))-$(lpad(cath_to_rev.day, 2, '0'))")
    
    # Orthodox Julian to others
    println("\nOrthodox Julian Easter in other calendars:")
    orth_j_to_greg = julian_to_gregorian_acc(orth_j_easter)
    orth_j_to_rev = julian_to_revised_julian_acc(orth_j_easter)
    println("  Gregorian:    $(orth_j_to_greg.year)-$(lpad(orth_j_to_greg.month, 2, '0'))-$(lpad(orth_j_to_greg.day, 2, '0'))")
    println("  Revised Jul:  $(orth_j_to_rev.year)-$(lpad(orth_j_to_rev.month, 2, '0'))-$(lpad(orth_j_to_rev.day, 2, '0'))")
    
    # Orthodox Revised Julian to others
    println("\nOrthodox Revised Julian Easter in other calendars:")
    orth_r_to_greg = revised_julian_to_gregorian_acc(orth_r_easter)
    orth_r_to_jul = revised_julian_to_julian_acc(orth_r_easter)
    println("  Gregorian:    $(orth_r_to_greg.year)-$(lpad(orth_r_to_greg.month, 2, '0'))-$(lpad(orth_r_to_greg.day, 2, '0'))")
    println("  Julian:       $(orth_r_to_jul.year)-$(lpad(orth_r_to_jul.month, 2, '0'))-$(lpad(orth_r_to_jul.day, 2, '0'))")
    
    show_calendar_info(year)
    
    return (catholic=cath_easter, orthodox_julian=orth_j_easter, orthodox_revised=orth_r_easter)
end

# ===============================
# Test Function with Critical Years
# ===============================

function test_critical_years()
    println("TESTING CRITICAL YEARS FOR CALENDAR DIVERGENCE")
    println("="^60)
    
    critical_years = [
        1582,  # Gregorian reform
        1700,  # Julian leap but Gregorian common
        1900,  # Julian leap but Gregorian common
        2000,  # All agree (leap in all)
        2100,  # Julian leap but Gregorian common (offset increases)
        2400,  # All agree (leap in all)
        2800,  # Revised Julian diverges from Gregorian
        2900,  # All common
        3000,  # All common
    ]
    
    for year in critical_years
        println("\n" * "="^60)
        println("YEAR $year")
        println("="^60)
        compute_all_easters_corrected(year)
    end
end

# ===============================
# Main Function
# ===============================

if abspath(PROGRAM_FILE) == @__FILE__
    println("ACCURATE EASTER DATE CALCULATOR")
    println("With correct calendar conversions")
    println("-"^60)
    
    print("Enter a year (1583-4099 recommended, or press Enter for test): ")
    input = readline()
    
    if strip(input) == ""
        # Run tests
        test_critical_years()
    else
        try
            year = parse(Int, input)
            compute_all_easters_corrected(year)
        catch e
            println("Error: $e")
            println("Using year 2025 as example")
            compute_all_easters_corrected(2025)
        end
    end
end
