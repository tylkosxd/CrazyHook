--------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------- [[ Types module ]] ---------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------
-- Some data types and function definitions that doesn't fit anywhere else.

-- BYTE and PBYTE:
ffi.cdef[[
	typedef unsigned char BYTE;
	typedef BYTE* PBYTE;
]]

-- Rect and point:
ffi.cdef[[
	typedef struct Rect {
		int Left;
		int Top;
		int Right;
		int Bottom;
	} Rect;

    typedef struct Point {
		union {
			int x;
			int X;
		};
		union {
			int y;
			int Y;
		};
    } Point;
]]

ffi.metatype("Point", {
	__tostring = function(self)
		return table.concat{"Point: ", self.X, "x", self.Y}
	end
})

ffi.metatype("Rect", {
	__tostring = function(self)
		return table.concat{"Rect: ", self.Left, "x", self.Top, "x", self.Right, "x", self.Bottom}
	end
})

-- Doubly linked list's node:
ffi.cdef[[
    typedef struct node {
        struct node* next;
        struct node* prev;
        struct ObjectA* object;
    } node;
]]

-- Win32 Input structures:
ffi.cdef[[
	typedef struct MouseInput {
		int dx;
		int dy;
		unsigned int mouseData;
		unsigned int dwFlags;
		unsigned int time;
		void* dwExtraInfo;
	} MouseInput;
	
	typedef struct KeybInput {
		short wVk;
		short wScan;
		unsigned int dwFlags;
		unsigned int time;
		void* dwExtraInfo;
	} KeybInput;

	typedef struct Input {
		unsigned int iType;
		union {
			MouseInput mi;
			KeybInput ki;
		};
	} Input;
]]

-- Various C functions:
ffi.cdef[[
	bool LineTo(int, int, int);
	bool Rectangle(int, Rect);
	bool Ellipse(int, Rect);
	bool Polygon(int, Point*, int);
	bool Arc(int, int, int, int, int, int, int, int, int);
	int CombineRgn(void*, void*, void*, int);
	bool StrokePath(int);
	
	void* CreateEllipticRgn(int, int, int, int);
	void* GetStockObject(int);
	int SetDCPenColor(int, int);
	bool MoveToEx(int, int, int, Point*);
	void* CreateSolidBrush(int);
	void* CreateHatchBrush(int, int);
	bool SelectObject(int, void*);
	bool DeleteObject(void*);
	int SetBkMode(int, int);
	void* CreatePen(int, int, int);
	bool SetTextColor(int, int);
	bool TextOutA(int, int, int, const char*, int);
	int DrawTextA(int, const char*, int, Rect*, unsigned int);
	int FillRect(int, Rect*, void*);
    void* CreateFontA(int, int, int, int, int, int, int, int, int, int, int, int, int, const char*);
    void* CreateRectRgn(int, int, int, int);
	void* CreateRectRgnIndirect(Rect*);
    bool FillRgn(int, void*, void*);
	void* CreatePolygonRgn(Point*, int, int);
	bool PtInRegion(void*, int, int);
	bool RectInRegion(void*, Rect*);
  
	int GetActiveWindow();
    int GetDlgItem(int, int);
	int SetDlgItemTextA(int, int, const char*);
	int SetDlgItemInt(int, int, int, int);
	bool EndDialog(int, int);
	int SetFocus(int);
	int LoadIconA(int,const char*);
    bool GetWindowRect(int, Rect*);
    bool SetWindowPos(int, int, int, int, int, int, unsigned int);
    int CreateWindowExA(int, const char*, const char*, int, int, int, int, int, int, int, int, int);
    bool DestroyWindow(int);
    long GetWindowLongA(int, int);
    int LoadImageA(int, const char*, unsigned int, int, int, unsigned int);
    int ShowWindow(int, int);
    int EnableWindow(int, bool);
	int DialogBoxParamA(int, const char*, int, int, int);
	unsigned int GetDlgItemTextA(int, int, int, int);
	bool UpdateWindow(int);
	int MessageBoxA(void*, const char*, const char*, int);
	int MapWindowPoints(int, int, Rect*, int);
	int GetParent(int);
	bool GetClientRect(int, Rect*);

    bool GetCursorPos(Point*);
	int ShowCursor(int);
	bool GetKeyboardState(unsigned char*);
	short GetAsyncKeyState(int);
	unsigned int SendInput(unsigned int, Input*, int);

	int PostMessageA(int, int, int, int);
	int SendMessageA(int, int, int, int);

	const char* GetCommandLineA();
	int* GetProcAddress(int*, const char*);
	bool VirtualProtect(unsigned int, unsigned int, int, int*);
]]
