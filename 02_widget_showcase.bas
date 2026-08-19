' 02_widget_showcase.bas
' =====================================================================
' LCUI3 示例 2：控件展示 & 动态列表
'
' 本示例在纯 FreeBasic 代码中展示以下控件与能力：
'   - 窗口标题 / 尺寸设置
'   - CSS 字符串定义控件样式 (flex 布局)
'   - textinput 文本框
'   - checkbox 复选框（"change" 事件）
'   - radio-group 单选组（"change" 事件，value 属性读写）
'   - select 下拉框（ui_select_add_item / get_value / set_value）
'   - button 按钮（"click" 事件）
'   - progress 进度条（帧回调动画）
'   - scrollarea + scrollbar 滚动区域（动态追加行）
'   - ui_widget_each 遍历子节点
'   - lcui_request_frame 帧回调
'
' 编译 (x64):
'   fbc64 -p lib\win64 -l gdi32 -l shell32 -l imm32 -x 02_widget_showcase.exe 02_widget_showcase.bas
' =====================================================================
#include once "inc/lcui.bi"

' scrollbar 方向枚举（lcui/widgets/scrollbar.h）
Const UI_SCROLLBAR_HORIZONTAL = 0
Const UI_SCROLLBAR_VERTICAL = 1

' --- 全局状态 ---------------------------------------------------------
Dim Shared As Single       progress_value = 0
Dim Shared As Long         row_count      = 0
Dim Shared As Long         frame_count    = 0
Dim Shared As ULongInt     last_time      = 0

' --- 回调 -------------------------------------------------------------

' checkbox 的 "change" 事件：读 checked 后更新状态文本
Sub on_checkbox_change cdecl(ByVal self As ui_widget_t Ptr, _
                             ByVal e As ui_event_t Ptr, _
                             ByVal arg As Any Ptr)
    Dim As ui_widget_t Ptr status = ui_get_widget(@"status-line")
    Dim checked As Long = fb_ui_checkbox_get_checked(self)
    Dim s As String = "Checkbox: " & IIf(checked <> 0, "checked", "unchecked")
    ui_text_set_content(status, StrPtr(s))
End Sub

' radio-group 的 "change" 事件：读 value 属性
Sub on_radio_change cdecl(ByVal self As ui_widget_t Ptr, _
                          ByVal e As ui_event_t Ptr, _
                          ByVal arg As Any Ptr)
    Dim As ui_widget_t Ptr status = ui_get_widget(@"status-line")
    Dim v As ZString Ptr = ui_widget_get_attr(self, @"value")
    Dim s As String = "Radio: " & IIf(v <> 0, *v, "(none)")
    ui_text_set_content(status, StrPtr(s))
End Sub

' 按钮点击：把 textinput 内容追加到滚动列表
Sub on_add_row cdecl(ByVal self As ui_widget_t Ptr, _
                     ByVal e As ui_event_t Ptr, _
                     ByVal arg As Any Ptr)
    Dim As ui_widget_t Ptr edit    = ui_get_widget(@"edit")
    Dim As ui_widget_t Ptr content = ui_get_widget(@"list-content")
    Dim As ui_widget_t Ptr row
    Dim wbuf As WString * 256
    Dim s    As String

    ui_textinput_get_text_w(edit, 0, 255, @wbuf)
    If wbuf[0] = 0 Then
        ui_textinput_set_text(edit, @"type a task first...")
        Return
    End If

    row = ui_create_widget(@"text")
    ui_widget_add_class(row, @"list-row")
    s = "#" & row_count + 1 & "  " & wbuf
    ui_text_set_content(row, StrPtr(s))
    ui_widget_append(content, row)
    row_count += 1

    ' 显示在 status-line（顺带演示 select 的取值）
    Dim As ui_widget_t Ptr sel = ui_get_widget(@"select-fruit")
    Dim sv As ZString Ptr = ui_select_get_value(sel)
    Dim status As String = "Added row " & row_count & _
        "   |   select value: " & IIf(sv <> 0, *sv, "(none)")
    ui_text_set_content(ui_get_widget(@"status-line"), StrPtr(status))
End Sub

' ui_widget_each 的回调：统计子节点个数，结果写入 arg 指向的 Long
Sub count_rows_cb cdecl(ByVal w As ui_widget_t Ptr, ByVal arg As Any Ptr)
    Dim p As Long Ptr = arg
    *p += 1
End Sub

' 按钮：用 ui_widget_each 遍历列表行数
Sub on_count_rows cdecl(ByVal self As ui_widget_t Ptr, _
                        ByVal e As ui_event_t Ptr, _
                        ByVal arg As Any Ptr)
    Dim As ui_widget_t Ptr content = ui_get_widget(@"list-content")
    Dim n As Long = 0
    ui_widget_each(content, @count_rows_cb, @n)
    Dim s As String = "List rows (ui_widget_each): " & n
    ui_text_set_content(ui_get_widget(@"status-line"), StrPtr(s))
End Sub

' 帧回调：驱动进度条动画 + 每秒刷新一次 FPS 文本
Sub on_frame cdecl(ByVal ts As ULongInt, ByVal user_data As Any Ptr)
    Dim As ui_widget_t Ptr progress = ui_get_widget(@"progress")
    Dim As ui_widget_t Ptr fps_txt  = ui_get_widget(@"fps")

    progress_value += 0.8
    If progress_value > 100 Then progress_value = 0
    ui_progress_set_value(progress, progress_value)

    frame_count += 1
    If ts - last_time >= 1000 Then
        Dim s As String = "FPS: " & frame_count
        ui_text_set_content(fps_txt, StrPtr(s))
        frame_count = 0
        last_time = ts
    End If

    ' 请求下一帧，形成持续动画
    lcui_request_frame(@on_frame, 0)
End Sub

' --- 主程序 -----------------------------------------------------------
Dim As ui_widget_t Ptr root, app, header, body
Dim As ui_widget_t Ptr left_col, right_col
Dim As ui_widget_t Ptr label, edit, btn_add, btn_count
Dim As ui_widget_t Ptr checkbox, radio_group, radio_item
Dim As ui_widget_t Ptr sel, progress, fps_txt, list, list_content, scrollbar
Dim As ui_widget_t Ptr status
Dim As ptk_window_t Ptr wnd
Dim As String css

lcui_init()

' 设置窗口标题（窗口尺寸通过 CSS 设置 root 来指定，见下方 css）
Dim wtitle As WString * 64
wtitle = "LCUI3 FreeBasic - Widget Showcase"
wnd = ui_server_get_window(ui_root())
If wnd <> 0 Then
    ptk_window_set_title(wnd, @wtitle)
End If

' 全局 CSS：flex 布局 + 控件外观
css = _
    "root { width: 720px; height: 520px; }" & _
    "#app {" & _
    "  display: flex;" & _
    "  flex-direction: column;" & _
    "  width: 100%; height: 100%;" & _
    "  padding: 14px;" & _
    "}" & _
    "#header { margin: 0 0 10px 0; font-size: 20px; font-weight: bold; }" & _
    "#body { display: flex; flex-direction: row; width: 100%; }" & _
    "#left-panel {" & _
    "  width: 280px;" & _
    "  padding: 10px;" & _
    "  margin-right: 12px;" & _
    "  border: 1px solid #ddd;" & _
    "  border-radius: 4px;" & _
    "}" & _
    "#left-panel > * { margin-bottom: 10px; }" & _
    "#right-panel {" & _
    "  flex: 1;" & _
    "  padding: 10px;" & _
    "  border: 1px solid #ddd;" & _
    "  border-radius: 4px;" & _
    "  display: flex; flex-direction: column;" & _
    "}" & _
    "#right-panel > * { margin-bottom: 10px; }" & _
    "label { display: block; font-size: 13px; margin-bottom: 3px; color: #555; }" & _
    "textinput {" & _
    "  display: block; width: 100%; box-sizing: border-box;" & _
    "  border: 1px solid #ccc; padding: 5px 8px;" & _
    "} " & _
    "#select-fruit, #radio-group { display: block; }" & _
    "radio-group-item { margin-right: 10px; }" & _
    "#progress { width: 100%; height: 10px; }" & _
    "#list {" & _
    "  display: block;" & _
    "  position: relative; overflow: hidden;" & _
    "  flex: 1; min-height: 120px;" & _
    "  border: 1px solid #eee;" & _
    "  background-color: #fafafa;" & _
    "}" & _
    "scrollarea { position: relative; width: 100%; height: 160px; }" & _
    "#status-line {" & _
    "  display: block; margin-top: 8px; padding: 6px 8px;" & _
    "  font-size: 12px; background-color: #f5f5f5;" & _
    "  border: 1px dashed #ccc;" & _
    "}"

ui_load_css_string(StrPtr(css), @"02_widget_showcase.bas")

root = ui_root()

' --- 应用容器 ----------------------------------------------------------
app = ui_create_widget(@"div")
ui_widget_set_id(app, @"app")
ui_root_append(app)

' 顶部标题（text 类型，class=title 控制外观）
header = ui_create_widget(@"text")
ui_widget_set_id(header, @"header")
ui_widget_add_class(header, @"title")
ui_text_set_content(header, "LCUI3 Widget Showcase (FreeBasic)")
ui_widget_append(app, header)

' 主体：左右两栏
body = ui_create_widget(@"div")
ui_widget_set_id(body, @"body")
ui_widget_append(app, body)

' --- 左栏：表单控件 ------------------------------------------------
left_col = ui_create_widget(@"div")
ui_widget_set_id(left_col, @"left-panel")
ui_widget_append(body, left_col)

' label + textinput
label = ui_create_widget(@"label")
ui_text_set_content(label, "Text input")
ui_widget_append(left_col, label)

edit = ui_create_widget(@"textinput")
ui_widget_set_id(edit, @"edit")
ui_textinput_set_text(edit, @"Add a task...")
ui_widget_append(left_col, edit)

' checkbox
checkbox = ui_create_checkbox()
ui_widget_set_id(checkbox, @"checkbox")
fb_ui_checkbox_set_checked(checkbox, 0)
ui_widget_on(checkbox, @"change", @on_checkbox_change, 0)
ui_widget_append(left_col, checkbox)

' radio-group
radio_group = ui_create_radio_group()
ui_widget_set_id(radio_group, @"radio-group")
ui_widget_set_attr(radio_group, @"value", @"red")

radio_item = ui_create_radio_group_item()
ui_widget_set_attr(radio_item, @"value", @"red")
ui_widget_append(radio_group, radio_item)

radio_item = ui_create_radio_group_item()
ui_widget_set_attr(radio_item, @"value", @"green")
ui_widget_append(radio_group, radio_item)

radio_item = ui_create_radio_group_item()
ui_widget_set_attr(radio_item, @"value", @"blue")
ui_widget_append(radio_group, radio_item)

ui_radio_group_update(radio_group)
ui_widget_on(radio_group, @"change", @on_radio_change, 0)
ui_widget_append(left_col, radio_group)

' select 下拉框
sel = ui_create_select()
ui_widget_set_id(sel, @"select-fruit")
ui_select_set_placeholder(sel, "Pick a fruit...")
ui_select_add_item(sel, @"Apple",  @"apple")
ui_select_add_item(sel, @"Banana", @"banana")
ui_select_add_item(sel, @"Cherry", @"cherry")
ui_select_set_value(sel, @"apple")
ui_widget_append(left_col, sel)

' 按钮
btn_add = ui_create_widget(@"button")
ui_widget_set_id(btn_add, @"btn-add")
ui_button_set_text(btn_add, @"Add to list")
ui_widget_on(btn_add, @"click", @on_add_row, 0)
ui_widget_append(left_col, btn_add)

btn_count = ui_create_widget(@"button")
ui_widget_set_id(btn_count, @"btn-count")
ui_button_set_text(btn_count, @"Count rows")
ui_widget_on(btn_count, @"click", @on_count_rows, 0)
ui_widget_append(left_col, btn_count)

' --- 右栏：进度 + 滚动列表 -----------------------------------------
right_col = ui_create_widget(@"div")
ui_widget_set_id(right_col, @"right-panel")
ui_widget_append(body, right_col)

' progress
progress = ui_create_progress()
ui_widget_set_id(progress, @"progress")
ui_progress_set_value(progress, 0)
ui_widget_append(right_col, progress)

fps_txt = ui_create_widget(@"text")
ui_widget_set_id(fps_txt, @"fps")
ui_text_set_content(fps_txt, @"FPS: -")
ui_widget_append(right_col, fps_txt)

' scrollarea（含纵向滚动条）
list = ui_create_scrollarea()
ui_widget_set_id(list, @"list")
ui_widget_append(right_col, list)

list_content = ui_create_scrollarea_content()
ui_widget_set_id(list_content, @"list-content")
ui_widget_append(list, list_content)

scrollbar = ui_create_scrollbar()
ui_scrollbar_set_orientation(scrollbar, UI_SCROLLBAR_VERTICAL)
ui_widget_append(list, scrollbar)

' 预置几行
Dim i As Long
For i = 1 To 12
    Dim As ui_widget_t Ptr row = ui_create_widget(@"text")
    ui_widget_add_class(row, @"list-row")
    Dim s As String = "seed row #" & i & " (use the text input to add more, then scroll)"
    ui_text_set_content(row, StrPtr(s))
    ui_widget_append(list_content, row)
Next
row_count = 12

' 状态栏
status = ui_create_widget(@"text")
ui_widget_set_id(status, @"status-line")
ui_text_set_content(status, @"Ready - interact with the controls above.")
ui_widget_append(app, status)

' 启动 FPS/进度动画（回调内部会持续请求下一帧）
lcui_request_frame(@on_frame, 0)

Dim exit_code As Long
exit_code = lcui_main()
End