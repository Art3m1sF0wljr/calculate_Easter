# Save this as easter_calculator.jl and run it directly

using Dates

# ===============================
# Calendar Date Types
# ===============================

struct JDate  # Julian Date
    y::Int
    m::Int
    d::Int
end

struct GDate  # Gregorian Date
    y::Int
    m::Int
    d::Int
end

struct RJDate  # Revised Julian Date
    y::Int
    m::Int
    d::Int
end

# Display methods
Base.show(io::IO, d::JDate) = print(io, "$(d.y)-$(lpad(d.m, 2, '0'))-$(lpad(d.d, 2, '0'))")
Base.show(io::IO, d::GDate) = print(io, "$(d.y)-$(lpad(d.m, 2, '0'))-$(lpad(d.d, 2, '0'))")
Base.show(io::IO, d::RJDate) = print(io, "$(d.y)-$(lpad(d.m, 2, '0'))-$(lpad(d.d, 2, '0'))")

# ===============================
# Leap Year Functions
# ===============================

function is_julian_leap(year::Int)
    return year % 4 == 0
end

function is_gregorian_leap(year::Int)
    return (year % 4 == 0) && (year % 100 != 0) || (year % 400 == 0)
end

function is_revised_julian_leap(year::Int)
    # Revised Julian: leap if divisible by 4, 
    # except centuries not divisible by 900 with remainder 200 or 600
    if year % 4 != 0
        return false
    elseif year % 100 != 0
        return true
    else
        return year % 900 == 200 || year % 900 == 600
    end
end

# ===============================
# Julian-Gregorian Offset
# ===============================

function julian_gregorian_offset(year::Int)
    # Returns the number of days Julian is behind Gregorian
    if year < 1582
        return 0
    end
    
    # Standard offset calculation
    # From 1582-10-15 (Gregorian) = 1582-10-05 (Julian), offset is 10
    offset = 10
    
    # Add days for century years not leap in Gregorian
    centuries = div(year, 100)
    for c in 17:centuries  # Start from 17th century (1600s)
        if !is_gregorian_leap(c * 100)
            offset += 1
        end
    end
    
    return offset
end

# ===============================
# Calendar Conversions
# ===============================

function julian_to_gregorian(jd::JDate)
    year, month, day = jd.y, jd.m, jd.d
    
    if year < 1582
        return GDate(year, month, day)
    end
    
    offset = julian_gregorian_offset(year)
    
    # Create a Date object and add offset
    # We need to convert Julian date to proleptic Gregorian for Date to work
    # Date in Julia is proleptic Gregorian
    # So we'll work with the Julian date as if it were Gregorian, then adjust
    
    # Simple approach: use known reference point
    # 1582-10-15 Gregorian = 1582-10-05 Julian
    # So Julian date + offset = Gregorian date (approximately)
    
    # For dates after March 1, the offset applies to the year
    # For Jan-Feb, need to check if leap year affects
    actual_offset = offset
    if month <= 2 && is_julian_leap(year) && !is_gregorian_leap(year + offset)
        # Special case for Jan/Feb in leap years
        # This is handled by the general algorithm below
    end
    
    # Use a simple iterative approach
    j_date = Date(year, month, day)
    g_date = j_date + Day(offset)
    
    return GDate(Dates.year(g_date), Dates.month(g_date), Dates.day(g_date))
end

function gregorian_to_julian(gd::GDate)
    year, month, day = gd.y, gd.m, gd.d
    
    if year < 1582
        return JDate(year, month, day)
    end
    
    offset = julian_gregorian_offset(year)
    g_date = Date(year, month, day)
    j_date = g_date - Day(offset)
    
    return JDate(Dates.year(j_date), Dates.month(j_date), Dates.day(j_date))
end

# Revised Julian is identical to Gregorian from 1900-2799
function gregorian_to_revised_julian(gd::GDate)
    # For the period 1900-2799, they are identical
    if gd.y >= 1900 && gd.y <= 2799
        return RJDate(gd.y, gd.m, gd.d)
    end
    
    # For other years, need to check leap year differences
    if is_gregorian_leap(gd.y) == is_revised_julian_leap(gd.y)
        return RJDate(gd.y, gd.m, gd.d)
    else
        # The calendars diverge by 1 day after Feb 28
        if is_gregorian_leap(gd.y) && !is_revised_julian_leap(gd.y)
            # Gregorian has Feb 29, Revised Julian doesn't
            # Dates after Feb 28 in Gregorian are 1 day ahead
            if (gd.m > 2 || (gd.m == 2 && gd.d == 29))
                g_date = Date(gd.y, gd.m, gd.d)
                rj_date = g_date - Day(1)
                return RJDate(Dates.year(rj_date), Dates.month(rj_date), Dates.day(rj_date))
            end
        elseif !is_gregorian_leap(gd.y) && is_revised_julian_leap(gd.y)
            # Revised Julian has Feb 29, Gregorian doesn't
            # Dates after Feb 28 in Revised Julian are 1 day ahead
            if gd.m > 2
                g_date = Date(gd.y, gd.m, gd.d)
                rj_date = g_date + Day(1)
                return RJDate(Dates.year(rj_date), Dates.month(rj_date), Dates.day(rj_date))
            end
        end
    end
    
    return RJDate(gd.y, gd.m, gd.d)
end

function revised_julian_to_gregorian(rjd::RJDate)
    # For the period 1900-2799, they are identical
    if rjd.y >= 1900 && rjd.y <= 2799
        return GDate(rjd.y, rjd.m, rjd.d)
    end
    
    # For other years, reverse of gregorian_to_revised_julian
    if is_gregorian_leap(rjd.y) == is_revised_julian_leap(rjd.y)
        return GDate(rjd.y, rjd.m, rjd.d)
    else
        if is_gregorian_leap(rjd.y) && !is_revised_julian_leap(rjd.y)
            # Gregorian has Feb 29, Revised Julian doesn't
            # Dates after Feb 28 in Revised Julian are 1 day behind Gregorian
            if rjd.m > 2
                rj_date = Date(rjd.y, rjd.m, rjd.d)
                g_date = rj_date + Day(1)
                return GDate(Dates.year(g_date), Dates.month(g_date), Dates.day(g_date))
            end
        elseif !is_gregorian_leap(rjd.y) && is_revised_julian_leap(rjd.y)
            # Revised Julian has Feb 29, Gregorian doesn't
            # Dates after Feb 28 in Gregorian are 1 day behind Revised Julian
            if rjd.m > 2 || (rjd.m == 2 && rjd.d == 29)
                rj_date = Date(rjd.y, rjd.m, rjd.d)
                g_date = rj_date - Day(1)
                return GDate(Dates.year(g_date), Dates.month(g_date), Dates.day(g_date))
            end
        end
    end
    
    return GDate(rjd.y, rjd.m, rjd.d)
end

function julian_to_revised_julian(jd::JDate)
    greg = julian_to_gregorian(jd)
    return gregorian_to_revised_julian(greg)
end

function revised_julian_to_julian(rjd::RJDate)
    greg = revised_julian_to_gregorian(rjd)
    return gregorian_to_julian(greg)
end

# ===============================
# Easter Computations
# ===============================

function catholic_easter_date(year::Int)
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
    
    return GDate(year, month, day)
end

function orthodox_easter_julian_date(year::Int)
    a = year % 4
    b = year % 7
    c = year % 19
    d = (19 * c + 15) % 30
    e = (2 * a + 4 * b - d + 34) % 7
    
    month = div(d + e + 114, 31)
    day = ((d + e + 114) % 31) + 1
    
    return JDate(year, month, day)
end

function orthodox_easter_revised_julian_date(year::Int)
    # CRITICAL: Revised Julian uses the JULIAN calculation for Easter
    # This is the same as the Julian calendar Easter, converted to Revised Julian
    julian_easter = orthodox_easter_julian_date(year)
    return julian_to_revised_julian(julian_easter)
end

# ===============================
# Display Functions
# ===============================

function show_calendar_info(year::Int)
    println("\n" * "="^60)
    println("CALENDAR INFORMATION FOR YEAR $year")
    println("="^60)
    
    println("\nLeap Year Status:")
    println("  Julian:       $(is_julian_leap(year) ? "LEAP" : "Common")")
    println("  Gregorian:    $(is_gregorian_leap(year) ? "LEAP" : "Common")")
    println("  Revised Jul:  $(is_revised_julian_leap(year) ? "LEAP" : "Common")")
    
    if year >= 1582
        offset = julian_gregorian_offset(year)
        println("\nJulian-Gregorian Offset: $offset days")
        println("  (Julian calendar is $offset days behind Gregorian)")
    end
    
    if is_gregorian_leap(year) != is_revised_julian_leap(year)
        println("\n⚠️  Gregorian and Revised Julian calendars DIVERGE in $year")
        if is_gregorian_leap(year)
            println("  Gregorian has Feb 29, Revised Julian does NOT")
        else
            println("  Revised Julian has Feb 29, Gregorian does NOT")
        end
    else
        println("\nGregorian and Revised Julian calendars AGREE in $year")
    end
end

function compute_easters(year::Int)
    println("\n" * "="^60)
    println("EASTER COMPUTATIONS FOR YEAR $year")
    println("="^60)
    
    cath_easter = catholic_easter_date(year)
    orth_j_easter = orthodox_easter_julian_date(year)
    orth_r_easter = orthodox_easter_revised_julian_date(year)
    
    println("\n1. CATHOLIC EASTER (Gregorian):")
    println("   Date: $cath_easter")
    
    println("\n2. ORTHODOX EASTER - Russian (Julian):")
    println("   Date: $orth_j_easter")
    
    println("\n3. ORTHODOX EASTER - Romanian (Revised Julian):")
    println("   Date: $orth_r_easter")
    
    # Convert to comparable dates
    println("\n" * "="^60)
    println("COMPARISON (all in Gregorian calendar)")
    println("="^60)
    
    orth_j_in_greg = julian_to_gregorian(orth_j_easter)
    orth_r_in_greg = revised_julian_to_gregorian(orth_r_easter)
    
    println("\nCatholic Easter:     $cath_easter")
    println("Orthodox (Julian):   $orth_j_in_greg")
    println("Orthodox (Revised):  $orth_r_in_greg")
    
    if cath_easter == orth_r_in_greg
        println("\n✅ Catholic and Revised Julian Orthodox Easter COINCIDE")
    else
        diff = Dates.value(Date(orth_r_in_greg.y, orth_r_in_greg.m, orth_r_in_greg.d) - 
                          Date(cath_easter.y, cath_easter.m, cath_easter.d))
        println("\nDifference between Catholic and Revised Julian Orthodox Easter: $diff days")
    end
    
    if orth_j_in_greg == orth_r_in_greg
        println("✅ Julian and Revised Julian Orthodox Easter COINCIDE in Gregorian calendar")
    end
    
    show_calendar_info(year)
    
    return (catholic=cath_easter, orthodox_julian=orth_j_easter, orthodox_revised=orth_r_easter)
end

# ===============================
# Main Program
# ===============================

function main()
    println("EASTER DATE CALCULATOR")
    println("Computes Catholic and Orthodox Easter dates with calendar conversions")
    println("-"^60)
    
    print("Enter a year (1583-4099 recommended): ")
    input = readline()
    
    if strip(input) == ""
        year = Dates.year(now())
        println("Using current year: $year")
    else
        try
            year = parse(Int, input)
        catch
            println("Invalid input. Using 2025.")
            year = 2025
        end
    end
    
    compute_easters(year)
    
    # Show some examples
    println("\n" * "="^60)
    println("EXAMPLES OF IMPORTANT YEARS")
    println("="^60)
    
    example_years = [2000, 2100, 2800]
    for y in example_years
        println("\nYear $y:")
        println("  Julian leap: $(is_julian_leap(y))")
        println("  Gregorian leap: $(is_gregorian_leap(y))")
        println("  Revised Julian leap: $(is_revised_julian_leap(y))")
        
        if y >= 1582
            offset = julian_gregorian_offset(y)
            println("  Julian-Gregorian offset: $offset days")
        end
    end
end

# Run the program
if abspath(PROGRAM_FILE) == @__FILE__
    main()
else
    println("Easter calculator loaded. Use compute_easters(year) to calculate.")
end
