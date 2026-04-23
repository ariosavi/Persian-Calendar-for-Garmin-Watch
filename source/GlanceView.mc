import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Application.Properties;

(:glance)
class PersianCalendarGlanceView extends WatchUi.GlanceView {
  var jalaliText as String?;
  var gregorianText as String?;

  function initialize() {
    GlanceView.initialize();
  }

  function onLayout(dc as Graphics.Dc) as Void {
    var app = getApp();
    jalaliText = app.getJalaliDateStr();
    gregorianText = app.getGregorianDateStr();
  }

  function onUpdate(dc as Graphics.Dc) as Void {
    var mediumTextHeight = Graphics.getFontHeight(Graphics.FONT_MEDIUM);
    var showGregorian = shouldShowGregorianInGlance();

    if (jalaliText != null && gregorianText != null) {
      var startY;
      if (showGregorian) {
        startY = (dc.getHeight() / 2) - mediumTextHeight;
      } else {
        startY = (dc.getHeight() - mediumTextHeight) / 2;
      }

      dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
      dc.drawText(
          0,
          startY,
          Graphics.FONT_MEDIUM,
          jalaliText,
          Graphics.TEXT_JUSTIFY_LEFT
      );

      if (showGregorian) {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(
            0,
            startY + mediumTextHeight,
            Graphics.FONT_TINY,
            gregorianText,
            Graphics.TEXT_JUSTIFY_LEFT
        );
      }
    }
  }

  function shouldShowGregorianInGlance() as Boolean {
    var settingValue = Properties.getValue("showGregorianInGlance");
    return settingValue == 1 || settingValue == "1" || settingValue == 1.0;
  }
}
