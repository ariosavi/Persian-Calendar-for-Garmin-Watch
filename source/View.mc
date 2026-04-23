import Toybox.WatchUi as Ui;
import Toybox.Time.Gregorian;
import Toybox.Time;
import Toybox.Graphics as Gfx;
import Toybox.System;
import Toybox.Math;
import Toybox.Application.Properties;

class PersianCalendarView extends Ui.View {
    // Class constants
    static const PERSIAN_MONTH_NAMES = ["Far.", "Ord.", "Kho.", "Tir.", "Mor.", "Sha.", "Meh.", "Aba.", "Aza.", "Dey.", "Bah.", "Esf."];
    static const GREGORIAN_MONTH_NAMES = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."];
    static const WEEKDAY_LABELS = ['S', 'S', 'M', 'T', 'W', 'T', 'F']; // Sat, Sun, Mon, Tue, Wed, Thu, Fri

    // Display properties
    var font = Gfx.FONT_XTINY;
    var lineSpacing = Gfx.getFontHeight(Gfx.FONT_XTINY) + 2;
    var centerY = 60;
    var centerX = 60;
    var xSpacing = 30;

    // Currently displayed month and year in the calendar
    var currentMonthView = 1;
    var currentYearView = 1400;

    var isGregorian = false;
    var weekStartShift = 0; // Default Saturday

    // Initialization method (called once)
    function initialize() {
        View.initialize();
        loadWeekStartPreference();
        // Initialize calendar based on today's Gregorian date converted to Jalali
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var result = getApp().gregorianToJalali(today.year, today.month, today.day);
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
        // Reload setting in case user changed it from phone/app settings.
        loadWeekStartPreference();
    }

    // Called to update the display
    function onUpdate(dc) {
        font = Gfx.FONT_XTINY;
        dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
        dc.clear();

        // Get today's Gregorian date and convert it to Jalali for highlighting
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var todayJalali = getApp().gregorianToJalali(today.year, today.month, today.day);
        var currentMonth = todayJalali.get("month");
        var currentYear = todayJalali.get("year");

        // Calculate header position
        var headerY = 8;
        var headerX = Math.round(dc.getWidth() / 2).toNumber();

        // Draw the month and year as a header at the top of the screen if not in the current month view
        if (currentMonthView != currentMonth || currentYearView != currentYear) {
            var headerText;
            var headerColor;
            
            if (isGregorian) {
                // Convert Jalali month/year to Gregorian equivalent
                var gregorianDate = getApp().jalaliToGregorian(currentYearView, currentMonthView, 1);
                var gregorianMonth = gregorianDate.get("month");
                var gregorianYear = gregorianDate.get("year");
                headerText = GREGORIAN_MONTH_NAMES[gregorianMonth - 1] + " " + gregorianYear.toString();
                headerColor = Gfx.COLOR_WHITE;
            } else {
                var displayYear = getApp().getDisplayJalaliYear(currentYearView);
                headerText = PERSIAN_MONTH_NAMES[currentMonthView - 1] + " " + displayYear.toString();
                headerColor = Gfx.COLOR_DK_GREEN;
            }
            
            dc.setColor(headerColor, Gfx.COLOR_TRANSPARENT);
            dc.drawText(headerX, headerY, font, headerText, Gfx.TEXT_JUSTIFY_CENTER);
        } else {
            // Draw the date string as a header at the top of the screen
            var dateStr = isGregorian ? getApp().getGregorianDateStr() : getApp().getJalaliDateStr();
            if (isGregorian) {
                dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
            } else {
                dc.setColor(Gfx.COLOR_DK_GREEN, Gfx.COLOR_TRANSPARENT);
            }
            dc.drawText(headerX, headerY, font, dateStr, Gfx.TEXT_JUSTIFY_CENTER);
        }

        drawMonthTable(dc, currentMonthView, currentYearView, currentMonth, currentYear, todayJalali.get("day"), today.month, today.day, today.year);
    }
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
                var gregorianMidDay = getApp().jalaliToGregorian(viewYear, viewMonth, 15);
                displayMonth = gregorianMidDay.get("month");
                displayYear = gregorianMidDay.get("year");
            }
            
            // Get number of days in Gregorian month
            monthDays = getApp().getGregorianMonthDays(displayMonth, displayYear);
            
            // Get first weekday of Gregorian month
            weekDay = getApp().getGregorianWeekDay(displayMonth, displayYear);
        } else {
            // Use Jalali month structure
            monthDays = getApp().getJalaliMonthDays(viewMonth, viewYear);
            weekDay = getApp().getJalaliWeekDay(viewMonth, viewYear);
        }
        
        // Convert Garmin weekday numbering (Sun=1 ... Sat=7) to Saturday-based index (Sat=0 ... Fri=6).
        weekDay = weekDay == 7 ? 0 : weekDay;
        // Shift the index based on user-selected first day of week.
        var firstDayColumn = (weekDay - weekStartShift + 7) % 7;
        
        var weeksNeeded = Math.ceil((firstDayColumn + monthDays) / 7.0).toNumber();
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

        // Determine weekday header color based on device dimensions
        var weekDayHeaderColor = (dc.getWidth() == 208 && dc.getHeight() == 208) ? Gfx.COLOR_LT_GRAY : Gfx.COLOR_DK_GRAY;

        // Draw weekday header
        var xPos = startX;
        for (var i = 0; i < WEEKDAY_LABELS.size(); i++) {
            var weekDayLabelIndex = (i + weekStartShift) % 7;
            dc.setColor(weekDayHeaderColor, Gfx.COLOR_TRANSPARENT);
            dc.drawText(xPos, startY, font, WEEKDAY_LABELS[weekDayLabelIndex].toString(), Gfx.TEXT_JUSTIFY_CENTER);
            xPos += Math.round(dc.getWidth() / 9.0) + 1;
        }

        // Draw calendar days
        var dayIterator = 1;
        var yPos = startY + ySpacing;

        while (dayIterator <= monthDays) {
            xPos = startX;
            for (var i = 0; i < 7; i++) {
                if (dayIterator != 1 || firstDayColumn == i) {
                    // Check if this is today's date
                    var isToday = false;
                    if (isGregorian) {
                        isToday = (displayMonth == todayGregorianMonth && displayYear == todayGregorianYear && dayIterator == todayGregorianDay);
                    } else {
                        // Compare Jalali dates directly
                        isToday = (viewMonth == currentMonth && viewYear == currentYear && dayIterator == currentDay);
                    }
                    
                    // Highlight the current day in blue
                    if (isToday) {
                        dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
                    } else if (isGregorian) {
                        // Gregorian calendar: Sunday is red for holiday.
                        var sundayColumn = (1 - weekStartShift + 7) % 7;
                        if (i == sundayColumn) {
                            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
                        } else {
                            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                        }
                    } else {
                        // Jalali calendar: Friday is red for holiday.
                        var fridayColumn = (6 - weekStartShift + 7) % 7;
                        if (i == fridayColumn) {
                            dc.setColor(Gfx.COLOR_DK_RED, Gfx.COLOR_TRANSPARENT);
                        } else {
                            dc.setColor(Gfx.COLOR_WHITE, Gfx.COLOR_TRANSPARENT);
                        }
                    }

                    var dateText = dayIterator.toString();
                    dc.drawText(xPos, yPos, font, dateText, Gfx.TEXT_JUSTIFY_CENTER);
                    dayIterator++;
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

    function loadWeekStartPreference() {
        var weekStartDay = Properties.getValue("weekStartDay");

        if (weekStartDay == 0 || weekStartDay == "0" || weekStartDay == 0.0 || weekStartDay == "Saturday") {
            weekStartShift = 0;
        } else if (weekStartDay == 1 || weekStartDay == "1" || weekStartDay == 1.0 || weekStartDay == "Sunday") {
            weekStartShift = 1;
        } else if (weekStartDay == 2 || weekStartDay == "2" || weekStartDay == 2.0 || weekStartDay == "Monday") {
            weekStartShift = 2;
        } else {
            // Default to Saturday for invalid, unset, or legacy values.
            weekStartShift = 0;
        }
    }
}

