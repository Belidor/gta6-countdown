import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

//! One app, two entry points: the glance in the glance list and the full screen from the apps menu.
(:glance)
class GTA6App extends Application.AppBase {

    public function initialize() {
        AppBase.initialize();
    }

    public function onStart(state as Dictionary?) as Void {
    }

    public function onStop(state as Dictionary?) as Void {
    }

    //! Called only when the full app starts, never in glance mode, so the foreground view is safe here.
    (:typecheck(disableGlanceCheck))
    public function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new GTA6View()];
    }

    public function getGlanceView() as [GlanceView] or [GlanceView, GlanceViewDelegate] or Null {
        return [new GTA6GlanceView()];
    }
}
