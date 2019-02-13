//
//  stubs.h
//  Tabboz Simulator
//
//  Created by Antonio Malara on 11/02/2019.
//  Copyright © 2019 Antonio Malara. All rights reserved.
//

#ifndef stubs_h
#define stubs_h

#define FAR
#define NEAR
#define PASCAL

#define TABBOZ_WIN
#define TABBOZ_WIN32

#define random tabboz_random
#define openlog tabboz_openlog

// -
// Type definitions
// -

//

typedef int bc;

typedef int WORD;
typedef int DWORD;
typedef int LONG;
typedef int HDC;
typedef int HKEY;
typedef int HBITMAP;
typedef int COLORREF;

typedef struct {
    int bmWidth;
    int bmHeight;
} BITMAP;

typedef char * LPSTR;
typedef int LPCREATESTRUCT;
typedef int ATOM;

typedef struct {
    int lpfnWndProc;
    int hInstance;
    int hCursor;
    int hbrBackground;
    int lpszClassName;
} WNDCLASS;

typedef struct {
    int right;
    int left;
    int bottom;
    int top;
} RECT;

typedef int LPRECT;
typedef int HICON;

typedef struct {
    int lStructSize;
    int hwndOwner;
    int hInstance;
    int lpstrFile;
    int nMaxFile;
    int lpstrDefExt;
    int lpstrFilter;
    int Flags;
} OPENFILENAME;

typedef int PAINTSTRUCT;

//

struct TabbozHANDLE {};

typedef struct TabbozHANDLE * HANDLE;
typedef struct TabbozHANDLE * HWND;

typedef struct TabbozDialogProc * DialogProc;

typedef BOOL (*DialogProcFunc)(HANDLE, LONG, LONG, LONG);

struct TabbozFARPROC {
    DialogProcFunc proc;
};

typedef struct TabbozFARPROC FARPROC;

struct TabbozINTRESOURCE {
    int number;
    char * n;
};

typedef struct TabbozINTRESOURCE INTRESOURCE;

// -
// Constants Definitions
// -

static const int SRCAND = 0;
static const int SRCPAINT = 0;
static const int SRCCOPY = 0;

static const int SC_CLOSE = 0;
static const int BM_SETCHECK = 0;

static const int MF_BYCOMMAND = 0;
static const int MF_STRING = 0;
static const int MF_SEPARATOR = 0;

static const int MB_OK = 0;
static const int MB_YESNO = 0;
static const int MB_ICONQUESTION = 0;
static const int MB_ICONINFORMATION = 0;
static const int MB_ICONCONFIRMATION = 0;
static const int MB_ICONSTOP = 0;
static const int MB_ICONHAND = 0;

static const int WM_INITDIALOG = 0;
static const int WM_COMMAND = 1;
static const int WM_CREATE = 2;
static const int WM_DESTROY = 3;
static const int WM_PAINT = 4;
static const int WM_LBUTTONDOWN = 5;
static const int WM_TIMER = 5;
static const int WM_ENDSESSION = 6;
static const int WM_QUERYDRAGICON = 7;
static const int WM_SYSCOMMAND = 8;

static const int IDCANCEL = 0;
static const int IDOK = 1;
static const int IDNO = 2;
static const int IDYES = 3;

static const int SM_CXSCREEN = 0;
static const int SM_CYSCREEN = 0;

static const int SW_HIDE = 0;
static const int SW_SHOWNORMAL = 0;

static const int MAX_PATH = 512;

static const int OFN_HIDEREADONLY = 0;
static const int OFN_FILEMUSTEXIST = 0;
static const int OFN_OVERWRITEPROMPT = 0;
static const int OFN_NOTESTFILECREATE = 0;

static const int SWP_NOMOVE = 0;
static const int SWP_NOZORDER = 0;

static const INTRESOURCE IDC_ARROW = { .number = 0 };
static const int COLOR_WINDOW = 0;

static const int REG_OPTION_NON_VOLATILE = 0;
static const int KEY_ALL_ACCESS = 0;
static const int HKEY_CURRENT_USER = 0;
static const int HKEY_ALL_ACCESS = 0;

static const int SND_ASYNC = 0;
static const int SND_NODEFAULT = 0;

extern char * _argv[];
extern int _argc;
extern HANDLE hWndMain;
extern HANDLE hInst;
extern HANDLE tipahDlg;
extern int ps;

HICON LoadIcon(HANDLE h, INTRESOURCE r);
void BWCCRegister(HANDLE _);
void randomize(void);
int tabboz_random(int x);
void LoadString(HANDLE hinst, int b, LPSTR ptr, int size);
int LoadCursor(HANDLE hinst, INTRESOURCE b);
ATOM RegisterClass(WNDCLASS * wc);

INTRESOURCE MAKEINTRESOURCE_Real(int a, char * n);

#define STRINGY(s) #s
#define MAKEINTRESOURCE(x) MAKEINTRESOURCE_Real(x, STRINGY(x) )

void new_reset_check(void);
int new_check_i(int x);
u_long new_check_l(u_long x);
int DialogBox(HWND hinst, INTRESOURCE b, void * c, FARPROC proc);
FARPROC MakeProcInstance(DialogProcFunc proc, HWND hinst);
void FreeProcInstance(FARPROC proc);
int GetDlgItem(HWND hDlg, int x);
int LOWORD(int x);
void EnableWindow(int x, int a);
void SendMessage(int dlg, int msg, int value, int x);
void EndDialog(HANDLE dlg, int x) ;
void ShowWindow(HANDLE h, int flags);
void SetDlgItemText(HANDLE h, int d, char * str);
int GetMenu(HANDLE h);
void DeleteMenu(int menu, int item, int flags);
int GetSubMenu(int menu, int i);
void AppendMenu(int menu, int type, int cmd, char * label);
int GetSystemMenu(HANDLE h, int menu);
void DrawMenuBar(HANDLE h);
void SetTimer(HANDLE h, int msg, int msec, void *);
void KillTimer(HANDLE h, int msg);
void PlaySound(void *, void *, int);
int MessageBox(HANDLE h, char * msg, char * title, int flags);
void GetDlgItemText(HANDLE h, int param, char * buf, size_t size);
void sndPlaySound(char * filename, int flags);
int GetSystemMetrics(int x);
void MoveWindow(HANDLE handle, int x, int y, int w, int h, int q);
void SetFocus(int dlg);

LONG RegOpenKeyEx(int a, char * keyName, int c, int d, HKEY * hkey);
LONG RegCreateKeyEx(int hkey,
                    char * name,
                    int c,
                    void * d,
                    int opt,
                    int access,
                    void * g,
                    HKEY *xKey,
                    LONG *disposition);


extern BOOL enableDialogTrace;
extern BOOL shouldEndDialog;

extern BOOL log_window;
extern BOOL didLog;

#endif /* stubs_h */
