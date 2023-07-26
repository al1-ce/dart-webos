library os.desktop;

import "dart:html";

import "global.dart";

import "window.dart";

const int ICON_SIZE = 64;

/**
Adds desktop link that opens new window
@arg p_url - Url of opened window
@arg p_name - Name in title bar
@arg p_icon - Icon to use
*/
void addDesktopApp(string p_url, string p_name, string p_icon, int x, int y, {bool single = false}) {

    // TODO: replace spaces with _
    Element icon = parse('''
        <div class="dLink" id="dLink-$p_name"><button class="button">
            <div class="dIcon" style="background-image: url('$p_icon');"></div>
            $p_name
        </button></div>
    ''');

    icon.onDoubleClick.listen((Event e) {
        if (single && WindowManager.hasName(p_name)) {
            WindowManager.getWindowNamed(p_name).focus();
            return null;
        }

        new OSWindow(p_url, p_name, p_icon);
    });

    int xpos = x * ICON_SIZE;
    int ypos = y * ICON_SIZE;

    icon.style.top = "${ypos}px";
    icon.style.left = "${xpos}px";

    $("#icons").append(icon);
}

/**
Adds desktop hyperlink
@arg p_url - Url for new tab
@arg p_name - Name in title bar
@arg p_icon - Icon to use
*/
void addDesktopLink(string p_url, string p_name, string p_icon, int x, int y) {
    Element icon = parse('''
        <div class="dLink" id="dLink-$p_name">
            <button class="button" ondblclick="window.open('$p_url', '_blank')">
                <div class="dIcon" style="background-image: url('$p_icon');">
                    <img src="assets/images/oc-img/link.png" >
                </div>
                $p_name
            </button>
        </div>
    ''');

    int xpos = x * ICON_SIZE;
    int ypos = y * ICON_SIZE;

    icon.style.top = "${ypos}px";
    icon.style.left = "${xpos}px";

    $("#icons").append(icon);

}

void init() {
    loadTheme();

    addStartMenu();
}

/// Loads theme
void loadTheme() {
    string theme = getOrInitCookie("theme", "neon");
    $("#theme-css").attr({"href": "/css/themes/${theme}.css"});
}

/// Adds start menu and callbacks
void addStartMenu() {
    Element menu = parse('''
        <div id="startmenu-menu">
            <div> App 1 </div>
            <div> App 1 </div>
            <div> App 1 </div>
            <div> App 1 </div>
            <div> App 1 </div>
            <div> App 1 </div>
        </div>
    ''');

    $("#startmenu").on("click", (QueryEvent e) {
        $("body").append(menu);

        $("#startmenu-menu").on("mouseout", (QueryEvent e) {
            $("#startmenu-menu").detach();
        });
    });
}
