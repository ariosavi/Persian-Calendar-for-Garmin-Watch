import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class PersianCalendarApp extends Application.AppBase {
  // Called when the application initializes
  function initialize() {
    AppBase.initialize();
  }

  // Called on application startup
  function onStart(state as Dictionary?) as Void {}

  // Called when the application is exiting
  function onStop(state as Dictionary?) as Void {}

  // Returns the initial view of the application
  function getInitialView() as [Views] or [Views, InputDelegates] {
    var view = new PersianCalendarView();
    var delegate = new PersianCalendarDelegate(view);

    return [
      view,
      delegate
    ];
  }

  // Returns the glance view of the application
  (:glance)
  function getGlanceView() {
    return [new PersianCalendarGlanceView()];
  }

  // Converts a Gregorian date to a Jalali date.
  // gy: Gregorian year, gm: Gregorian month, gd: Gregorian day
  function gregorianToJalali(gy, gm, gd) {
    var gy2 = gm > 2 ? gy + 1 : gy;
    var g_d_m = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
    var days =
      355666 +
      365 * gy +
      ((gy2 + 3) / 4).toNumber() -
      ((gy2 + 99) / 100).toNumber() +
      ((gy2 + 399) / 400).toNumber() +
      gd +
      g_d_m[gm - 1];

    var jy = -1595 + 33 * (days / 12053).toNumber();
    days %= 12053;
    jy += 4 * (days / 1461).toNumber();
    days %= 1461;
    if (days > 365) {
      jy += ((days - 1) / 365).toNumber();
      days = (days - 1) % 365;
    }

    var jalaliObject = {
      "year" => 0,
      "month" => 0,
      "day" => 0,
    };
    jalaliObject.put("year", jy);
    if (days < 186) {
      jalaliObject.put("month", 1 + (days / 31).toNumber());
      jalaliObject.put("day", 1 + (days % 31));
    } else {
      jalaliObject.put("month", 7 + ((days - 186) / 30).toNumber());
      jalaliObject.put("day", 1 + ((days - 186) % 30));
    }
    return jalaliObject;
  }

  // Converts a Jalali date to a Gregorian date.
  // jy: Jalali year, jm: Jalali month, jd: Jalali day
  function jalaliToGregorian(jy, jm, jd) {
    jy += 1595;
    var days =
      -355668 +
      365 * jy +
      (jy / 33).toNumber() * 8 +
      (((jy % 33) + 3) / 4).toNumber() +
      jd +
      (jm < 7 ? (jm - 1) * 31 : (jm - 7) * 30 + 186);

    var gy = 400 * (days / 146097).toNumber();
    days %= 146097;
    if (days > 36524) {
      days = days - 1;
      gy += 100 * (days / 36524).toNumber();
      days %= 36524;
      if (days >= 365) {
        days = days + 1;
      }
    }
    gy += 4 * (days / 1461).toNumber();
    days %= 1461;
    if (days > 365) {
      gy += ((days - 1) / 365).toNumber();
      days = (days - 1) % 365;
    }
    var gd = days + 1;
    var gm;

    var sal_a = [
      0,
      31,
      (gy % 4 == 0 && gy % 100 != 0) || gy % 400 == 0 ? 29 : 28,
      31,
      30,
      31,
      30,
      31,
      31,
      30,
      31,
      30,
      31,
    ];
    for (gm = 0; gm < 13 && gd > sal_a[gm]; gm++) {
      gd -= sal_a[gm];
    }

    var gregorianObject = {
      "year" => 0,
      "month" => 0,
      "day" => 0,
    };
    gregorianObject.put("year", gy);
    gregorianObject.put("month", gm);
    gregorianObject.put("day", gd);
    return gregorianObject;
  }

  // Returns the current Jalali date as a string in "year<sep>mm<sep>dd" format.
  function getJalaliDateStr() {
    var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var jalali = gregorianToJalali(today.year, today.month, today.day);

    // Ensure month and day are two digits
    var monthVal = jalali.get("month").toNumber();
    var dayVal = jalali.get("day").toNumber();
    var monthStr =
      monthVal < 10 ? "0" + monthVal.toString() : monthVal.toString();
    var dayStr = dayVal < 10 ? "0" + dayVal.toString() : dayVal.toString();

    var displayYear = getDisplayJalaliYear(jalali.get("year").toNumber());
    var sep = getDateSeparator();
    var jalaliStr = displayYear.toString() + sep + monthStr + sep + dayStr;
    return jalaliStr;
  }

  // Converts base Jalali year to user-selected display year.
  function getDisplayJalaliYear(baseJalaliYear as Number) as Number {
    var yearMode = Properties.getValue("persianYearMode");

    // 0 => Hijri, 1 => Shahanshahi
    if (yearMode == 0 || yearMode == "0" || yearMode == 0.0) {
      return baseJalaliYear;
    }

    // Default mode is Shahanshahi.
    return baseJalaliYear + 1180;
  }

  // Returns the current Gregorian date as a string in "year<sep>mm<sep>dd" format.
  function getGregorianDateStr() {
    var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    var monthStr =
      today.month < 10 ? "0" + today.month.toString() : today.month.toString();
    var dayStr =
      today.day < 10 ? "0" + today.day.toString() : today.day.toString();

    var sep = getDateSeparator();
    var gregorianStr = today.year.toString() + sep + monthStr + sep + dayStr;
    return gregorianStr;
  }

  // Returns the user-selected date separator character.
  // 0 => "/", 1 => "-", 2 => ".", 3 => " "
  function getDateSeparator() as String {
    var sepMode = Properties.getValue("dateSeparator");
    if (sepMode == 1 || sepMode == "1" || sepMode == 1.0) {
      return "-";
    }
    if (sepMode == 2 || sepMode == "2" || sepMode == 2.0) {
      return ".";
    }
    if (sepMode == 3 || sepMode == "3" || sepMode == 3.0) {
      return " ";
    }
    // Default to slash.
    return "/";
  }
  // Determine if a Persian year is a leap year using the 33-year cycle.
  function isJalaliLeapYear(year as Number) as Boolean {
    var r = year % 33;
    return r == 1 || r == 5 || r == 9 || r == 13 || r == 17 || r == 22 || r == 26 || r == 30;
  }

  // Get the number of days in a Jalali month.
  function getJalaliMonthDays(month as Number, year as Number) as Number {
    if (month < 1 || month > 12) {
      return 0;
    }
    var monthDays = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];
    var days = monthDays[month - 1];
    if (month == 12 && isJalaliLeapYear(year)) {
      days = 30;
    }
    return days;
  }

  // Calculate the weekday of the first day of a Jalali month/year (Garmin: Sun=1..Sat=7)
  function getJalaliWeekDay(month as Number, year as Number) as Number {
    var gregorian = jalaliToGregorian(year, month, 1);
    var options = {
      :year  => gregorian.get("year"),
      :month => gregorian.get("month"),
      :day   => gregorian.get("day")
    };
    var date = Gregorian.moment(options);
    var firstDayInfo = Gregorian.info(date, Time.FORMAT_SHORT);
    return firstDayInfo.day_of_week;
  }

  // Determine if a Gregorian year is a leap year.
  function isGregorianLeapYear(year as Number) as Boolean {
    if (year % 400 == 0) {
      return true;
    } else if (year % 100 == 0) {
      return false;
    } else if (year % 4 == 0) {
      return true;
    }
    return false;
  }

  // Get the number of days in a Gregorian month.
  function getGregorianMonthDays(month as Number, year as Number) as Number {
    if (month < 1 || month > 12) {
      return 0;
    }
    var monthDays = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    if (month == 2 && isGregorianLeapYear(year)) {
      return 29;
    }
    return monthDays[month - 1];
  }

  // Calculate the weekday of the first day of a Gregorian month/year (Garmin: Sun=1..Sat=7)
  function getGregorianWeekDay(month as Number, year as Number) as Number {
    var options = {
      :year  => year,
      :month => month,
      :day   => 1
    };
    var date = Gregorian.moment(options);
    var firstDayInfo = Gregorian.info(date, Time.FORMAT_SHORT);
    return firstDayInfo.day_of_week;
  }
}

// Returns the current instance of PersianCalendarApp.
function getApp() as PersianCalendarApp {
  return Application.getApp() as PersianCalendarApp;
}
