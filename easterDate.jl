# Save this as easter_calculator.jl and run it directly

using Dates

# ===============================
# Calendar Date Types (with unique names)
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
    if (year % 4 == 0) && (year % 100 != 0)
        return true
    elseif year % 900 == 200 || year % 900 == 600
        return true
    else
        return false
    end
end

# ===============================
# Calendar Conversions
# ===============================

function julian_to_gregorian(jd::JDate)
    year, month, day = jd.y, jd.m, jd.d
    
    if year >= 1582
        centuries = div(year - 1, 100)
        offset = 10
        for c in 16:centuries
            century_year = c * 100 + 1
            if !is_gregorian_leap(century_year)
                offset += 1
            end
        end
        
        gdate = Date(year, month, day) + Day(offset)
        return GDate(Dates.year(gdate), Dates.month(gdate), Dates.day(gdate))
    else
        return GDate(year, month, day)
    end
end

function gregorian_to_julian(gd::GDate)
    year, month, day = gd.y, gd.m, gd.d
    
    if year >= 1582
        centuries = div(year - 1, 100)
        offset = 10
        for c in 16:centuries
            century_year = c * 100 + 1
            if !is_gregorian_leap(century_year)
                offset += 1
            end
        end
        
        jdate = Date(year, month, day) - Day(offset)
        return JDate(Dates.year(jdate), Dates.month(jdate), Dates.day(jdate))
    else
        return JDate(year, month, day)
    end
end

function gregorian_to_revised_julian(gd::GDate)
    year, month, day = gd.y, gd.m, gd.d
    
    if is_gregorian_leap(year) == is_revised_julian_leap(year)
        return RJDate(year, month, day)
    else
        date_obj = Date(year, month, day)
        
        if month > 2 || (month == 2 && day == 29)
            if is_gregorian_leap(year) && !is_revised_julian_leap(year)
                if month > 2 || (month == 2 && day == 29)
                    new_date = date_obj - Day(1)
                    return RJDate(Dates.year(new_date), Dates.month(new_date), Dates.day(new_date))
                end
            elseif !is_gregorian_leap(year) && is_revised_julian_leap(year)
                if month > 2
                    new_date = date_obj + Day(1)
                    return RJDate(Dates.year(new_date), Dates.month(new_date), Dates.day(new_date))
                end
            end
        end
        return RJDate(year, month, day)
    end
end

function revised_julian_to_gregorian(rjd::RJDate)
    year, month, day = rjd.y, rjd.m, rjd.d
    
    if is_gregorian_leap(year) == is_revised_julian_leap(year)
        return GDate(year, month, day)
    else
        date_obj = Date(year, month, day)
        
        if month > 2 || (month == 2 && day == 29)
            if is_gregorian_leap(year) && !is_revised_julian_leap(year)
                if month > 2 || (month == 2 && day == 29)
                    new_date = date_obj + Day(1)
                    return GDate(Dates.year(new_date), Dates.month(new_date), Dates.day(new_date))
                end
            elseif !is_gregorian_leap(year) && is_revised_julian_leap(year)
                if month > 2
                    new_date = date_obj - Day(1)
                    return GDate(Dates.year(new_date), Dates.month(new_date), Dates.day(new_date))
                end
            end
        end
        return GDate(year, month, day)
    end
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
    
    month = 3
    day = d + e + 22
    
    if day > 31
        month = 4
        day -= 31
    end
    
    return JDate(year, month, day)
end

function orthodox_easter_revised_julian_date(year::Int)
    if year >= 1923
        greg_easter = catholic_easter_date(year)
        return gregorian_to_revised_julian(greg_easter)
    else
        julian_easter = orthodox_easter_julian_date(year)
        return julian_to_revised_julian(julian_easter)
    end
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
        centuries = div(year - 1, 100)
        offset = 10
        for c in 16:centuries
            century_year = c * 100 + 1
            if !is_gregorian_leap(century_year)
                offset += 1
            end
        end
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
    
    println("\n" * "="^60)
    println("CONVERSIONS")
    println("="^60)
    
    println("\nCatholic Easter in other calendars:")
    cath_to_jul = gregorian_to_julian(cath_easter)
    cath_to_rev = gregorian_to_revised_julian(cath_easter)
    println("  Julian:       $cath_to_jul")
    println("  Revised Jul:  $cath_to_rev")
    
    println("\nOrthodox Julian Easter in other calendars:")
    orth_j_to_greg = julian_to_gregorian(orth_j_easter)
    orth_j_to_rev = julian_to_revised_julian(orth_j_easter)
    println("  Gregorian:    $orth_j_to_greg")
    println("  Revised Jul:  $orth_j_to_rev")
    
    println("\nOrthodox Revised Julian Easter in other calendars:")
    orth_r_to_greg = revised_julian_to_gregorian(orth_r_easter)
    orth_r_to_jul = revised_julian_to_julian(orth_r_easter)
    println("  Gregorian:    $orth_r_to_greg")
    println("  Julian:       $orth_r_to_jul")
    
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
            centuries = div(y - 1, 100)
            offset = 10
            for c in 16:centuries
                century_year = c * 100 + 1
                if !is_gregorian_leap(century_year)
                    offset += 1
                end
            end
            println("  Julian-Gregorian offset: $offset days")
        end
    end
end

# Run the program
if abspath(PROGRAM_FILE) == @__FILE__
    main()
else
    # If loaded in REPL or notebook, you can call compute_easters(year) directly
    println("Easter calculator loaded. Use compute_easters(year) to calculate.")
end
