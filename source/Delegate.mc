using Toybox.WatchUi as Ui;

class PersianCalendarDelegate extends Ui.InputDelegate {
    var view as PersianCalendarView;

    function initialize(viewInstance as PersianCalendarView) {
        Ui.InputDelegate.initialize();
        view = viewInstance;
    }

    // On tap, toggle between Gregorian and Jalali calendar views
    function onTap(clickEvent as Ui.ClickEvent) {
        view.toggleDisplayMode();
        return true;
    }

    // On swipe up or down, show the next or previous month
    function onSwipe(swipeEvent as Ui.SwipeEvent) {
        if (swipeEvent.getDirection() == Ui.SWIPE_UP) {
            view.showNextMonth();
        } else if (swipeEvent.getDirection() == Ui.SWIPE_DOWN) {
            view.showPreviousMonth();
        } else if (swipeEvent.getDirection() == Ui.SWIPE_RIGHT) {
            // close the view
            Ui.popView(Ui.SLIDE_RIGHT);
        }
        return true;
    }

    function onKey(keyEvent as Ui.KeyEvent) {
        if (keyEvent.getKey() == Ui.KEY_ENTER) {
            view.toggleDisplayMode();
            return true;
        } else if (keyEvent.getKey() == Ui.KEY_UP) {
            view.showPreviousMonth();
            return true;
        } else if (keyEvent.getKey() == Ui.KEY_DOWN) {
            view.showNextMonth();
            return true;
        } else if (keyEvent.getKey() == Ui.KEY_ESC) {
            // minimize the view
            Ui.popView(Ui.SLIDE_RIGHT);
            return true;
        }
        return false;
    }
}
