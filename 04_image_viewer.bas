' 04_image_viewer.bas
' =====================================================================
' LCUI3 示例 4：图像显示与查看（图片查看器基础版）
' 图片始终在居中显示
' =====================================================================
#include once "inc/lcui.bi"

' 图片文件（相对于 exe 运行目录）。换图就改这里。
Const IMG_PATH As String = "demo_image.png"

' --- 全局状态 ---------------------------------------------------------
Dim Shared As ui_widget_t Ptr view_box ' 图片显示区
Dim Shared As ui_widget_t Ptr info_line ' 状态栏
Dim Shared As Double cur_scale = 1.0 ' 当前缩放比例
Dim Shared As Long img_w = 0 ' 图片原始宽
Dim Shared As Long img_h = 0 ' 图片原始高

' 把缩放写入 CSS background-size：px 单位直接指定显示尺寸
Sub apply_scale()
    Dim s As String
    Dim ws As String = Str(Int(cur_scale * img_w)) & "px"
    Dim hs As String = Str(Int(cur_scale * img_h)) & "px"
    s = ws & " " & hs
    ui_widget_set_style_string(view_box, @"background-size", StrPtr(s))
    Dim st As String = "scale: " & Str(cur_scale) & _
        " | rendered: " & ws & " x " & hs
    ui_text_set_content(info_line, StrPtr(st))
End Sub

' --- 回调 -------------------------------------------------------------

' 放大按钮
Sub on_zoom_in cdecl(ByVal self As ui_widget_t Ptr, _
                     ByVal e As ui_event_t Ptr, _
                     ByVal arg As Any Ptr)
    cur_scale *= 1.25
    If cur_scale > 8 Then cur_scale = 8
    apply_scale()
End Sub

' 缩小按钮
Sub on_zoom_out cdecl(ByVal self As ui_widget_t Ptr, _
                      ByVal e As ui_event_t Ptr, _
                      ByVal arg As Any Ptr)
    cur_scale /= 1.25
    If cur_scale < 0.1 Then cur_scale = 0.1
    apply_scale()
End Sub

' 重置为 100%
Sub on_reset cdecl(ByVal self As ui_widget_t Ptr, _
                   ByVal e As ui_event_t Ptr, _
                   ByVal arg As Any Ptr)
    cur_scale = 1.0
    apply_scale()
End Sub

' 适应窗口：等比缩放到能在显示区内完整显示
Sub on_fit cdecl(ByVal self As ui_widget_t Ptr, _
                 ByVal e As ui_event_t Ptr, _
                 ByVal arg As Any Ptr)
    Dim As Double w = 720, h = 480 ' 显示区 CSS 尺寸
    Dim As Double s = 1.0
    If img_w > 0 AndAlso img_h > 0 Then
        Dim As Double sw = w / img_w
        Dim As Double sh = h / img_h
        s = IIf(sw < sh, sw, sh)
        If s > 1.0 Then s = 1.0
        cur_scale = s
        apply_scale()
    End If
End Sub

' --- 主程序 -----------------------------------------------------------
Dim As ui_widget_t Ptr root_w, app
Dim As ui_widget_t Ptr bar, btn, status
Dim rc As Long

lcui_init()

' 窗口标题（尺寸用 CSS 的 root 指定）
Dim wtitle As WString * 64
wtitle = "LCUI3 FreeBasic - Image Viewer"
Dim As ptk_window_t Ptr wnd = ui_server_get_window(ui_root())
If wnd <> 0 Then ptk_window_set_title(wnd, @wtitle) End If

' 布局：顶部工具条 + 图片显示区 + 状态栏
' 关键 CSS：给 #view 明确 width/height，并用 background-position: center 确保居中
Dim css As String = _
    "root { width: 800px; height: 600px; background-color: #2b2b2b; }" & _
    "#app { display: flex; flex-direction: column; width: 100%; height: 100%; }" & _
    "#bar { display: flex; flex-direction: row; padding: 8px; background-color: #3c3f41; }" & _
    "#bar button { margin-right: 8px; padding: 4px 12px; }" & _
    "#view { " & _
    " width: 720px; height: 480px; margin: 10px; border: 1px solid #555;" & _
    " background-color: #222; background-repeat: no-repeat;" & _
    " background-position: center center;" & _
    " background-image: url(" & IMG_PATH & ");" & _
    " background-size: auto;" & _
    "}" & _
    "#status { padding: 6px 10px; font-size: 12px; color: #bbb; background-color: #333; }"
ui_load_css_string(StrPtr(css), @"04_image_viewer.bas")

' --- 顶部工具条 -------------------------------------------------------
app = ui_create_widget(@"div")
ui_widget_set_id(app, @"app")
ui_root_append(app)

bar = ui_create_widget(@"div")
ui_widget_set_id(bar, @"bar")
ui_widget_append(app, bar)

btn = ui_create_widget(@"button")
ui_button_set_text(btn, @"Fit")
ui_widget_on(btn, @"click", @on_fit, 0)
ui_widget_append(bar, btn)

btn = ui_create_widget(@"button")
ui_button_set_text(btn, @"-")
ui_widget_on(btn, @"click", @on_zoom_out, 0)
ui_widget_append(bar, btn)

btn = ui_create_widget(@"button")
ui_button_set_text(btn, @"100%")
ui_widget_on(btn, @"click", @on_reset, 0)
ui_widget_append(bar, btn)

btn = ui_create_widget(@"button")
ui_button_set_text(btn, @"+")
ui_widget_on(btn, @"click", @on_zoom_in, 0)
ui_widget_append(bar, btn)

' --- 图片显示区 -------------------------------------------------------
view_box = ui_create_widget(@"div")
ui_widget_set_id(view_box, @"view")
ui_widget_append(app, view_box)

' --- 状态栏 -----------------------------------------------------------
info_line = ui_create_widget(@"text")
ui_widget_set_id(info_line, @"status")
ui_text_set_content(info_line, @"loading ...")
ui_widget_append(app, info_line)

' 初始显示状态：同步读取图片原始尺寸
Dim As Long error_code
Dim As pd_canvas_t canvas_buffer
error_code = pd_read_image_from_file(StrPtr(IMG_PATH), @canvas_buffer)
If error_code = 0 Then
    img_w = canvas_buffer.width
    img_h = canvas_buffer.height
    Dim sz_s As String = Str(img_w) & " x " & Str(img_h)
    ui_text_set_content(info_line, StrPtr(sz_s))
Else
    img_w = 480: img_h = 300
    ui_text_set_content(info_line, StrPtr("loaded: 480 x 300"))
End If

' 初始缩放：使用真实尺寸
cur_scale = 1.0
apply_scale()

Dim exit_code As Long
exit_code = lcui_main()
End
