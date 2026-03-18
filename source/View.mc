using Toybox.WatchUi as Ui;
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Math;

class PersianCalendarView extends Ui.View {
    // Display properties
    var font = Gfx.FONT_XTINY;
    var lineSpacing = Gfx.getFontHeight(Gfx.FONT_XTINY) + 2;
    var centerY = 60;
    var centerX = 60;
    var xSpacing = 30;

    // Currently displayed month and year in the calendar
    var currentMonthView = 1;
    var currentYearView = 1400;

    // Instance of PersianCalendarApp (created only once)
    var persianCalendarApp;
    var isGregorian = false;

    // Initialization method (called once)
    function initialize() {
        View.initialize();
        persianCalendarApp = new PersianCalendarApp();

        // Initialize calendar based on today's Gregorian date converted to Jalali
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var result = persianCalendarApp.gregorianToJalali(today.year, today.month, today.day);
        currentMonthView = result.get("month");
        currentYearView = result.get("year");
    }

    // Layout setup when the view size is determined
    function onLayout(dc) {
        centerY = (dc.getHeight() / 2) - (lineSpacing / 2) - 70;
        centerX = (dc.getWidth() / 2) - (2 * Gfx.getFontHeight(font));
        setLayout(Rez.Layouts.MainLayout(dc));
    }

    function onShow() {
        // Optional: Additional code when the view is shown can be added here
    }

    // Called to update the display
    function onUpdate(dc) {
        font = Gfx.FONT_XTINY;
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        // Get today's Gregorian date and convert it to Jalali for highlighting
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var todayJalali = persianCalendarApp.gregorianToJalali(today.year, today.month, today.day);
        var currentMonth = todayJalali.get("month");
        var currentYear = todayJalali.get("year");

        // Calculate header position
        var headerY = 8;
        var headerX = Math.round(dc.getWidth() / 2).toNumber();

        // Draw the month and year as a header at the top of the screen if not in the current month view
        if (currentMonthView != currentMonth || currentYearView != currentYear) {
            var persianMonthNames = ["Far.", "Ord.", "Kho.", "Tir.", "Mor.", "Sha.", "Meh.", "Aba.", "Aza.", "Dey.", "Bah.", "Esf."];
            var gregorianMonthNames = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."];
            
            var headerText;
            var headerColor;
            
            if (isGregorian) {
                // Convert Jalali month/year to Gregorian equivalent
                var gregorianDate = persianCalendarApp.jalaliToGregorian(currentYearView, currentMonthView, 1);
                var gregorianMonth = gregorianDate.get("month");
                var gregorianYear = gregorianDate.get("year");
                headerText = gregorianMonthNames[gregorianMonth - 1] + " " + gregorianYear.toString();
                headerColor = Gfx.COLOR_LT_GRAY;
            } else {
                headerText = persianMonthNames[currentMonthView - 1] + " " + currentYearView.toString();
                headerColor = Gfx.COLOR_DK_GREEN;
            }
            
            dc.setColor(headerColor, Gfx.COLOR_TRANSPARENT);
            dc.drawText(headerX, headerY, font, headerText, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            // Draw the date string as a header at the top of the screen
            dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
            var dateStr = isGregorian ? persianCalendarApp.getGregorianDateStr() : persianCalendarApp.getJalaliDateStr();
            dc.drawText(headerX, headerY, font, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        drawMonthTable(dc, currentMonthView, currentYearView, currentMonth, currentYear, todayJalali.get("day"), today.month, today.day, today.year);

    }

    // Draws the calendar month table
    public function drawMonthTable(dc, viewMonth, viewYear, currentMonth, currentYear, currentDay, todayGregorianMonth, todayGregorianDay, todayGregorianYear) {
        var marginLeft = 15;
        var startX = Math.round(dc.getWidth() / 9.0) + marginLeft;
        
        // Calculate header height and bottom margin for responsive layout
        var headerHeight = 10; // Space for month/date header above calendar
        var bottomMargin = 5;  // Minimum space at bottom
        var availableHeight = dc.getHeight() - headerHeight - bottomMargin;
        
        // Determine month structure based on display mode
        var displayMonth = viewMonth;
        var displayYear = viewYear;
        var monthDays;
        var weekDay;
        
        if (isGregorian) {
            // If viewing today in Gregorian mode, use today's actual Gregorian month
            // This handles the case where a Persian month spans two Gregorian months
            if (viewMonth == currentMonth && viewYear == currentYear) {
                displayMonth = todayGregorianMonth;
                displayYear = todayGregorianYear;
            } else {
                // Get the Gregorian equivalent month and year (using the middle of the month to be more accurate)
                var gregorianMidDay = persianCalendarApp.jalaliToGregorian(viewYear, viewMonth, 15);
                displayMonth = gregorianMidDay.get("month");
                displayYear = gregorianMidDay.get("year");
            }
            
            // Get number of days in Gregorian month
            monthDays = get_gregorian_month_days(displayMonth, displayYear);
            
            // Get first weekday of Gregorian month
            weekDay = get_gregorian_week_day(displayMonth, displayYear);
        } else {
            // Use Jalali month structure
            monthDays = get_month_days(viewMonth, viewYear);
            weekDay = get_week_day(viewMonth, viewYear);
        }
        
        if (weekDay == 7) {
            weekDay = 0;
        }
        
        var weeksNeeded = Math.ceil((weekDay + monthDays) / 7.0).toNumber();
        var totalHeightNeeded = (weeksNeeded + 1) * lineSpacing; // +1 for weekday header
        
        // Calculate dynamic spacing to fit all content
        var ySpacing = lineSpacing;
        if (totalHeightNeeded > availableHeight) {
            ySpacing = (availableHeight - lineSpacing) / weeksNeeded;
            if (ySpacing < 1) {
                ySpacing = 1;
            }
        }
        
        // Calculate starting Y position to center vertically with available space
        var startY = Math.round((availableHeight - totalHeightNeeded) / 2.0).toNumber();
        if (startY < 5) {
            startY = 5;
        }

        // Draw weekday header
        var weekDays = ['S', 'S', 'M', 'T', 'W', 'T', 'F'];
        var xPos = startX;
        for (var i = 0; i < weekDays.size(); i++) {
            // Set color based on device dimensions
            if (dc.getWidth() == 208 && dc.getHeight() == 208) {
                dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Gfx.COLOR_DK_GRAY, Gfx.COLOR_TRANSPARENT);
            }
            dc.drawText(xPos, startY, font, weekDays[i].toString(), Gfx.TEXT_JUSTIFY_CENTER);
            xPos += Math.round(dc.getWidth() / 9.0) + 1;
        }

        // Draw calendar days
        var dayIterator = 1;
        var yPos = startY + ySpacing;
        var jalaliIteratorDay = 1;

        while (dayIterator <= monthDays) {
            xPos = startX;
            for (var i = 0; i < 7; i++) {
                if (dayIterator != 1 || weekDay == i) {
                    // Check if this is today's date
                    var isToday = false;
                    if (isGregorian) {
                        isToday = (displayMonth == todayGregorianMonth && displayYear == todayGregorianYear && dayIterator == todayGregorianDay);
                    } else {
                        // Compare Jalali dates directly
                        isToday = (viewMonth == currentMonth && viewYear == currentYear && jalaliIteratorDay == currentDay);
                    }
                    
                    // Highlight the current day in blue
                    if (isToday) {
                        dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
                    // Normal color for Gregorian dates
                    } else if(isGregorian) {
                        dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
                    } else {
                        // Different color for last column
                        if (i == 6) {
                            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
                        // Normal color for other cells
                        } else {
                            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                        }
                    }

                    var dateText = dayIterator.toString();
                    dc.drawText(xPos, yPos, font, dateText, Gfx.TEXT_JUSTIFY_CENTER);
                    dayIterator++;
                    if (!isGregorian) {
                        jalaliIteratorDay++;
                    }
                    if (dayIterator > monthDays) {
                        break;
                    }
                }
                xPos += Math.round(dc.getWidth() / 9.0) + 1;
            }
            yPos += ySpacing;
        }
    }

    // Toggle display mode between Gregorian and Jalali dates
    public function toggleDisplayMode() {
        isGregorian = !isGregorian;
        Ui.requestUpdate();
    }

    public function showPreviousMonth() {
        if (currentMonthView == 1) {
            currentMonthView = 12;
            currentYearView--;
        } else {
            currentMonthView--;
        }
        Ui.requestUpdate();
    }

    public function showNextMonth() {
        if (currentMonthView == 12) {
            currentMonthView = 1;
            currentYearView++;
        } else {
            currentMonthView++;
        }
        Ui.requestUpdate();
    }

    function onHide() {
        // Optional: Clean up resources here if needed
    }
}

// Helper function to get the number of days in a Persian month (for months 1-12)
function get_month_days(month, year) {
    // Persian calendar: months 1-6 have 31 days, months 7-11 have 30 days, month 12 has 29 days (30 in leap years)
    var monthDays = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
    if (month >= 1 && month <= 12) {
        var days = monthDays[month - 1];
        // Check for leap year and adjust Esfand (month 12)
        if (month == 12 && is_jalali_leap_year(year)) {
            days = 30;
        }
        return days;
    }
    return 0;
}

// Helper function to determine if a Persian year is a leap year
function is_jalali_leap_year(year) {
    // Persian calendar leap year: year % 5 == 3 means years ending in 03, 08, 13, 18, 23, 28, etc.
    return (year % 5) == 3;
}

// Helper function to calculate the weekday of the first day of the given Jalali month/year
function get_week_day(month, year) {
    var gregorian = (new PersianCalendarApp()).jalaliToGregorian(year, month, 1);
    var options = {
        :year  => gregorian.get("year"),
        :month => gregorian.get("month"),
        :day   => gregorian.get("day")
    };
    var date = Gregorian.moment(options);
    var firstDayInfo = Gregorian.info(date, Time.FORMAT_SHORT);
    return firstDayInfo.day_of_week;
}

// Helper function to get the number of days in a Gregorian month
function get_gregorian_month_days(month, year) {
    var monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    
    // Check for leap year
    var isLeap = false;
    if (year % 400 == 0) {
        isLeap = true;
    } else if (year % 100 == 0) {
        isLeap = false;
    } else if (year % 4 == 0) {
        isLeap = true;
    }
    
    if (month == 2 && isLeap) {
        return 29;
    }
    
    if (month >= 1 && month <= 12) {
        return monthDays[month - 1];
    }
    return 0;
}

// Helper function to calculate the weekday of the first day of the given Gregorian month/year
function get_gregorian_week_day(month, year) {
    var options = {
        :year  => year,
        :month => month,
        :day   => 1
    };
    var date = Gregorian.moment(options);
    var firstDayInfo = Gregorian.info(date, Time.FORMAT_SHORT);
    return firstDayInfo.day_of_week;
}
