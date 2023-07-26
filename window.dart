library os.window;

import "global.dart";

import "dart:async" show Timer;

typedef ivec2 = Point<int>;
typedef vec2 = Point<double>;

/// Window class
class OSWindow {
    // public:
    /// Returns window name
    string get name => _name;
    string get originalName => _originalName;
    /// Returns window ID
    int get id => _id;
    /// Returns window icon (winbar icon)
    string get icon => _icon;

    // private:
    /// Page URL (link to html)
    string _url = "/not_found.html";
    /// Name in title bar
    string _name = "/not_found.html";
    /// Name with which window was opened
    string _originalName = "/not_found.html";
    /// Internal ID
    int _id = -1;
    /// Icons (for window bar)
    string _icon = "/favicon.ico";

    double _x = -1;
    double _y = -1;

    double _w = -1;
    double _h = -1;

    vec2 _ts = vec2(0, 0);
    vec2 _tp = vec2(0, 0);

    Point _dragOffset = new Point(0, 0);

    bool _hidden = false;
    bool _maximized = false;
    
    /// Constructs new window
    OSWindow(string p_url, string p_name, string p_icon) {
        _url = p_url;
        _name = p_name;
        _icon = p_icon;
        _originalName = p_name;
        
        _id = WindowManager.windowIndex;

        WindowManager.add(this);
        WindowManager.incIndex();

        __create();
        __setListeners();
        __makeDraggable();
        __makeResizable();
        __addTaskbarButton();
        focus();
    }

    // public:
    
    /// Makes current window topmost
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

        $(".taskbar-button").removeClass("taskbar-button-focused");
        $("#taskbar-button-id-$id").addClass("taskbar-button-focused");

    }
    
    /// Minimizes window to winbar
    void minimize() {
        if (_hidden) {
            $("#win-id-$id").css("display", "block");
            focus();
        } else {
            $("#win-id-$id").css("display", "none");
            $("#taskbar-button-id-$id").removeClass("taskbar-button-focused");
        }

        _hidden = !_hidden;
    }
    /// Makes window take entire screen
    void maximize() {
        _maximized = !_maximized;
        bool toMax = _maximized;
        
        new Timer(new Duration(milliseconds: 16), () => __maximize(toMax));
    }

    void __maximize(bool toMax) {
        ElementQuery w = $("#win-id-$id");
        // ElementQuery p = $document;

        // Element e = $("#win-id-$id").first;

        ivec2 displaySize = ivec2($document().width?.toInt() as int, ($document().height?.toInt() as int) - 30);
        
        ivec2 lerpSize = toMax ? displaySize : ivec2(_w.toInt(), _h.toInt());
        ivec2 lerpPos = toMax ? ivec2(0, 0) : ivec2(_x.toInt(), _y.toInt());

        vec2 newPos = vec2(
            lerp(_tp.x, lerpPos.x as double, 0.2),
            lerp(_tp.y, lerpPos.y as double, 0.2)
        );

        vec2 newSize = vec2(
            lerp(_ts.x, lerpSize.x as double, 0.2),
            lerp(_ts.y, lerpSize.y as double, 0.2)
        );
        
        print("");
        print("");
        print(_tp);
        print(_ts);

        print("");
        print(lerpPos);
        print(lerpSize);

        print("");
        print(newPos);
        print(newSize);

        _tp = newPos;
        _ts = newSize;
        
        w.offset = newPos;
        w.css("width", newSize.x.toString() + "px");
        w.css("height", newSize.y.toString() + "px");

        if (toMax && newPos.x < 1 && newPos.y < 1 && 
            newSize.x > displaySize.x - 1 && newSize.y > displaySize.y - 1) {
            // w.offset = new Point(0, 0);
            // w.css("width", displaySize.x.toString() + "px");
            // w.css("height", displaySize.y.toString() + "px");

            return;
        }

        if (!toMax && abs(newSize.x - _w) < 1 ) print("W");
        if (!toMax && abs(newSize.y - _h) < 1) print("H");
        if (!toMax && abs(newPos.x - _x) < 1 && abs(newPos.y - _y) < 1 && 
            abs(newSize.x - _w) < 1 && abs(newSize.y - _h) < 1) {
            print("A");
            return;
        }

        new Timer(new Duration(milliseconds: 16), () => __maximize(toMax));
    }

    /// Refreshes inner page
    void refresh() {
        $("#win-frame-id-$id")
                .forEach((Element e) => e.setAttribute("src", e.getAttribute("src") as string));
    }

    /// Returns IFrame (content) of window
    ElementQuery getFrame() { return $("#win-frame-id-$id"); }
    /// Closes window
    void close() {
        $("#win-id-$id").forEach((Element e) => e.remove());
        $("#taskbar-button-id-$id").forEach((Element e) => e.remove());
        WindowManager.remove(this);
    }

    void setTitle(string title) {
        $("#win-id-$id .win-text").text = title;
        $("#taskbar-button-id-$id span").text = title;
    }

    // private:
    
    /// Creates window and appends it to page
    void __create() {
        string frameID = _url.contains("?") ? "&id=$_id" : "?id=$_id";

        _x = 16 + (WindowManager.windowCount * 2);
        _y = 23 + (WindowManager.windowCount * 2);

        _x = ($document().width as int) * (_x / 100);
        _y = ($document().height as int) * (_y / 100);
        _w = ($document().width as int) * 0.6;
        _h = ($document().height as int) * 0.5;

        _tp = vec2(_x, _y);
        _ts = vec2(_w, _h);


        $("#windows").append(parse('''
            <div id="win-id-$id" class="window" style="
                left: ${_x}px;
                top: ${_y}px;
                width: ${_w}px;
                height: ${_h}px;
            ">
                <div class="win-bar"> 
                    <div class="win-text">$_name</div>
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
    }
    
    /// Sets event listeners (iframe and buttons)
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
        $("#win-id-$id .win-upd").on("click", (QueryEvent e) { w.refresh(); });
    }
    
    /// Adds listeners to window bar
    void __makeDraggable() {
        double minX = 0;
        double minY = 0;
        double maxX = $document().width as double;
        double maxY = $document().height as double;

        ElementQuery $win = $("#win-id-" + _id.toString());

        ElementQuery $list = $win.find(".dragger");

        $list.on("mousedown", (QueryEvent e) {
            if (this._maximized) return;
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
    
    /// Adds listeners to resizers (rb corner and sides)
    void __makeResizable() {
        double minWidth = 500;
        double minHeight = 200;
        ElementQuery $win = $("#win-id-" + _id.toString());

        ElementQuery $resizer = $win.find(".resizer");

        $resizer.on("mousedown", (QueryEvent e) {
            if (this._maximized) return;
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
            if (this._maximized) return;
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
            if (this._maximized) return;
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
    
    /// Adds clickable button to taskbar
    void __addTaskbarButton() {
        Element b = parse('''
            <button id="taskbar-button-id-$id" class="styled-button taskbar-button button">
                <image class="taskbar-icon" src="$_icon"/>
                <span>$_name</span>
            </button>
        ''');

        $("#taskbar").append(b);

        $("#taskbar-button-id-$id").on("click", (QueryEvent e) {
            bool isFocused = $("#taskbar-button-id-$id").hasClass("taskbar-button-focused");
            if (this._hidden || isFocused) {
                this.minimize();
            } else {
                this.focus();
            }
        });
    }

}

/// Global window manager
class WindowManager {
    // public:
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

    /// Check if window is already opened
    static bool hasName(string originalName) {
        for (int i = 0; i < windowCount; ++i) {
            if (getWindow(i).originalName == originalName) {
                return true;
            }
        }
        return false;
    }

    /// Check if window is already opened
    static OSWindow getWindowNamed(string originalName) {
        for (int i = 0; i < windowCount; ++i) {
            if (getWindow(i).originalName == originalName) {
                return getWindow(i);
            }
        }
        throw new Exception("Unknown window name $originalName.");
    }
}
