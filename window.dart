library window;

import "dart:html" show Element, Point;
import "package:dquery/dquery.dart" show $, ElementQuery, QueryEvent, $document;

import "../types.dart";
import "../dqext.dart";

class OSWindow {
    string _url = "/not_found.html";
    string _name = "/not_found.html";
    string _link = "/not_found.html";
    int _id = -1;
    string _icon = "/favicon.ico";

    double _x = 0;
    double _y = 0;

    double _w = 0;
    double _h = 0;

    Point _dragOffset = new Point(0, 0);

    string get name => _name;
    int get id => _id;
    string get icon => _icon;

    OSWindow(string p_url, string p_name, string p_link, string p_icon) {
        _url = p_url;
        _name = p_name;
        _link = p_link;
        _icon = p_icon;
        
        _id = WindowManager.windowIndex;

        WindowManager.add(this);
        WindowManager.incIndex();

        __create();
        __setListeners();
        __makeDraggable();
        __makeResizable();
        focus();
    }
    
    void focus() {
        // $("#win-id-$id").css("display", "inline-block");
        int actIndex = int.parse($("#win-id-$id").css("z-index"));
        for (int i = 0; i < WindowManager.windowCount; i++) {
            int _id = WindowManager.getWindow(i).id;
            if (_id == id) {
                continue;
            }
            var $window = $("#win-id-$_id");
            int newIndex = int.parse($window.css("z-index"));
            if (actIndex < newIndex) {
                $window.css("z-index", "${newIndex - 1}");
            }
        }
        $("#win-id-$id").css("z-index", "50");
    }

    int deploy() { return 0; }
    void minimize() {}
    void maximize() {}
    void update() {}
    ElementQuery getFrame() { return $("."); }
    void close() {}
    void __setMinMax() {}

    void __create() {
        string frameID = _url.contains("?") ? "&id=$_id" : "?id=$_id";

        _x = 16 + (WindowManager.windowCount * 2);
        _y = 23 + (WindowManager.windowCount * 2);

        $("#page").append(parse('''
            <div id="win-id-$id" class="window" 
                style="position: absolute; 
                top: $_x%; 
                left: $_y%;">
                <div class="win-bar"> 
                    <div class="win-text">$_link</div>
                    <button class="win-close win-button button"></button>
                    <button class="win-full win-button button"></button>
                    <button class="win-min win-button button"></button>
                    <button class="win-upd win-button button"></button>
                </div>
                <div class="win-content">
                    <iframe class="win-frame" id="win-frame-id-$id" src="$_url$frameID"></iframe>
                </div>
                <div class="dragger"></div>
                <div class="resizerw"></div>
                <div class="resizerh"></div>
                <div class="resizer"></div>
            </div>
            '''));

        _x = ($document().width as int) * (_x / 100);
        _y = ($document().height as int) * (_y / 100);
        _w = ($document().width as int) * 0.6;
        _h = ($document().height as int) * 0.5;
    }

    void __setListeners() {
        ElementQuery $win = $("#win-id-$id");

        OSWindow w = this;

        $win.on("mousedown", (QueryEvent e) {
            w.focus();
        });

        ElementQuery $frame = $win.find(".win-frame");
        $frame.iframeTracker(() {
            w.focus();
        });

        $("#win-id-$id .win-close").on("click", (QueryEvent e) { w.close(); });
        $("#win-id-$id .win-full").on("click", (QueryEvent e) { w.maximize(); });
        $("#win-id-$id .win-min").on("click", (QueryEvent e) { w.minimize(); });
        $("#win-id-$id .win-upd").on("click", (QueryEvent e) { w.update(); });
    }

    void __makeDraggable() {
        double minX = 0;
        double minY = 0;
        double maxX = $document().width as double;
        double maxY = $document().height as double;

        ElementQuery $win = $("#win-id-" + _id.toString());

        ElementQuery $list = $win.find(".dragger");

        $list.on("mousedown", (QueryEvent e) {
            // $win.draggable(false);
            $list.cssMap({
                "width": "200%",
                "height": "200%",
                "left": "-50%",
                "top": "-50%"
            });	

            _dragOffset = new Point(
                e.pageX - ($win.offset?.x as num),
                e.pageY - ($win.offset?.y as num)
                );

            $list.on("mousemove", (QueryEvent e) {
                ElementQuery $par = $list.parent();

                _x = e.pageX - _dragOffset.x as double;
                _y = e.pageY - _dragOffset.y as double;
                $par.offset = new Point(
                    _x, _y
                );
            });
        });
        $list.on("mouseup", (QueryEvent e) {
            $list.off("mousemove");

            $list.cssMap({
                "width": "calc( 100% - 96px )",
                "height": "26px",
                "left": "0px",
                "top": "0px"
            });
        });

    }

    void __makeResizable() {
        // TODO: take full page for resize
        
        double minWidth = 500;
        double minHeight = 200;
        ElementQuery $win = $("#win-id-" + _id.toString());

        ElementQuery $resizer = $win.find(".resizer");

        $resizer.on("mousedown", (QueryEvent e) {
            $resizer.cssMap({
                "width": "600px",
                "height": "600px",
                "right": "-300px",
                "bottom": "-300px"
            });

            $resizer.on("mousemove", (QueryEvent e) {
                Point offset = new Point($resizer.offset?.x as num, $resizer.offset?.y as num);
                num x = e.pageX - offset.x;
                num y = e.pageY - offset.y;
                ElementQuery $par = $resizer.parent();
                num newWidth = ($par.width as int) + (x - 300);
                num newHeight = ($par.height as int) + (y - 300);
                if (newWidth >= minWidth) {
                    $par.css("width", "${newWidth}px");
                }
                if (newHeight >= minHeight) {
                    $par.css("height", "${newHeight}px");
                }

                _w = newWidth as double;
                _h = newHeight as double;
            });
        });
        $resizer.on("mouseup", (QueryEvent e) {
            $resizer.off("mousemove");

            $resizer.cssMap({
                "width": "10px",
                "height": "10px",
                "right": "-5px",
                "bottom": "-5px"
            });
        });

        ElementQuery $resizerW = $win.find(".resizerw");

        $resizerW.on("mousedown", (QueryEvent e) {
            $resizerW.cssMap({
                "width": "600px",
                "right": "-300px",
            });

            $resizerW.on("mousemove", (QueryEvent e) {
                Point offset = new Point($resizerW.offset?.x as num, $resizerW.offset?.y as num);
                num x = e.pageX - offset.x;
                ElementQuery $par = $resizerW.parent();
                num newWidth = ($par.width as int) + (x - 300);
                if (newWidth >= minWidth) {
                    $par.css("width", "${newWidth}px");
                }

                _w = newWidth as double;
            });
        });
        $resizerW.on("mouseup", (QueryEvent e) {
            $resizerW.off("mousemove");

            $resizerW.cssMap({
                "width": "10px",
                "right": "-5px",
            });
        });

        ElementQuery $resizerH = $win.find(".resizerh");

        $resizerH.on("mousedown", (QueryEvent e) {
            $resizerH.cssMap({
                "height": "600px",
                "bottom": "-300px"
            });

            $resizerH.on("mousemove", (QueryEvent e) {
                Point offset = new Point($resizerH.offset?.x as num, $resizerH.offset?.y as num);
                num y = e.pageY - offset.y;
                ElementQuery $par = $resizerH.parent();
                num newHeight = ($par.height as int) + (y - 300);
                if (newHeight >= minHeight) {
                    $par.css("height", "${newHeight}px");
                }

                _h = newHeight as double;
            });
        });
        $resizerH.on("mouseup", (QueryEvent e) {
            $resizerH.off("mousemove");

            $resizerH.cssMap({
                "height": "10px",
                "bottom": "-5px"
            });
        });
    }

}

class WindowManager {
    static List<OSWindow> _windows = [];
    static int _windowIndex = 0;
    
    /// Returns amount of managed windows
    static int get windowCount => _windows.length;

    /// Returns unique ID for new window
    static int get windowIndex => _windowIndex;
    
    /// Increments window index
    static void incIndex() {
        ++_windowIndex;
    }
    
    /// Adds window to manager if it's not already contained
    static void add(OSWindow w) {
        if (!_windows.contains(w)) {
            _windows.add(w);
        }
    }
    
    /// Stops managing window
    static void remove(OSWindow w) {
        if (_windows.contains(w)) {
            _windows.remove(w);
        }
    }
    
    /// Stops managing window at index
    static void removeIndex(int idx) {
        if (idx >= windowCount || idx < 0) return;
        _windows.removeAt(idx);
    }
    
    /// Returns window at index
    static OSWindow getWindow(int idx) {
        if (idx >= windowCount || idx < 0) throw new IndexError.withLength(idx, windowCount);
        return _windows[idx];
    }
    
    /// Removes all windows
    static void clear() {
        _windows = [];
    }
}
