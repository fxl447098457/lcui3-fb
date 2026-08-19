' 03_dashboard.bas
' =====================================================================
' LCUI3 示例 3：仪表盘 —— 表格 + 柱状图 + 表单 + 弹层
'
' 用纯 FreeBasic 代码 + CSS 模拟 Web 常见控件：
'   - 数据表格（div flex 模拟 table，含表头/斑马纹）
'   - 柱状图（div 高度即数值，可动态刷新）
'   - field 系列表单（field-set/legend/label/content/separator）
'   - select / radio-group / checkbox / progress / textinput
'   - portal 弹层（点击按钮弹出菜单）
'   - scrollarea + scrollbar 滚动
'
' 编译 (x64):
'   fbc64 -p lib\win64 -l gdi32 -l shell32 -l imm32 -x 03_dashboard.exe 03_dashboard.bas
' =====================================================================
#include once "inc/lcui.bi"

Const UI_SCROLLBAR_VERTICAL = 1

' --- 全局 -------------------------------------------------------------
Dim Shared As ui_widget_t Ptr chart_bars(0 To 7)
Dim Shared As ui_widget_t Ptr progress_w
Dim Shared As Single       progress_value = 0
Dim Shared As Long         frame_count   = 0
Dim Shared As ULongInt     last_time     = 0
Dim Shared As Long         table_rows    = 0
Dim Shared As ui_widget_t Ptr menu_portal
Dim Shared menu_ids(0 To 4) As Long

' --- 回调 -------------------------------------------------------------

' 刷新柱状图：随机高度
Sub on_refresh_chart cdecl(ByVal self As ui_widget_t Ptr, _
                           ByVal e As ui_event_t Ptr, _
                           ByVal arg As Any Ptr)
    Dim i As Long
    Dim h As Long
    For i = 0 To 7
        h = 20 + Int(Rnd * 130)
        Dim css_h As String = h & "px"
        ui_widget_set_style_string(chart_bars(i), @"height", StrPtr(css_h))
    Next
End Sub

' 向表格追加一行
Sub on_add_table_row cdecl(ByVal self As ui_widget_t Ptr, _
                           ByVal e As ui_event_t Ptr, _
                           ByVal arg As Any Ptr)
    Dim As ui_widget_t Ptr tbody = ui_get_widget(@"table-body")
    Dim As ui_widget_t Ptr row, cell
    Dim i As Long
    Dim s As String

    table_rows += 1
    row = ui_create_widget(@"div")
    ui_widget_add_class(row, @"tbl-row")
    For i = 1 To 4
        cell = ui_create_widget(@"text")
        ui_widget_add_class(cell, @"tbl-cell")
        s = "row-" & table_rows & " cell-" & i
        ui_text_set_content(cell, StrPtr(s))
        ui_widget_append(row, cell)
    Next
    ui_widget_append(tbody, row)

    Dim status As String = "Table rows: " & table_rows
    ui_text_set_content(ui_get_widget(@"table-count"), StrPtr(status))
End Sub

' portal 菜单项点击
Sub on_menu_item cdecl(ByVal self As ui_widget_t Ptr, _
                       ByVal e As ui_event_t Ptr, _
                       ByVal arg As Any Ptr)
    Dim idx As Long
    Dim names As String
    idx = *Cast(Long Ptr, arg)
    Select Case idx
        Case 0: names = "New"
        Case 1: names = "Open..."
        Case 2: names = "Save"
        Case 3: names = "Save As..."
        Case 4: names = "Quit"
    End Select
    Dim status As String = "Menu: " & names
    ui_text_set_content(ui_get_widget(@"menu-status"), StrPtr(status))
    If menu_portal <> 0 Then
        ui_portal_close(menu_portal)
    End If
End Sub

' 打开 portal 菜单
Sub on_open_menu cdecl(ByVal self As ui_widget_t Ptr, _
                       ByVal e As ui_event_t Ptr, _
                       ByVal arg As Any Ptr)
    If menu_portal <> 0 Then
        ui_portal_open(menu_portal)
    End If
End Sub

' 帧回调：进度动画 + FPS
Sub on_frame cdecl(ByVal ts As ULongInt, ByVal user_data As Any Ptr)
    progress_value += 0.8
    If progress_value > 100 Then progress_value = 0
    ui_progress_set_value(progress_w, progress_value)

    frame_count += 1
    If ts - last_time >= 1000 Then
        Dim s As String = "FPS: " & frame_count
        ui_text_set_content(ui_get_widget(@"fps"), StrPtr(s))
        frame_count = 0
        last_time = ts
    End If
    lcui_request_frame(@on_frame, 0)
End Sub

' --- 主程序 -----------------------------------------------------------
Dim As ui_widget_t Ptr app, header, body
Dim As ui_widget_t Ptr left_col, mid_col, right_col
Dim As ui_widget_t Ptr txt, row, cell, bar, bar_labels
Dim As ui_widget_t Ptr fset, flegend, fgroup, ffield, flabel, fcontent
Dim As ui_widget_t Ptr edit, sel, radio_group, radio_item, checkbox
Dim As ui_widget_t Ptr menu_btn, tbody_row_marker
Dim As ptk_window_t Ptr wnd
Dim As String css
Dim i As Long

lcui_init()

wnd = ui_server_get_window(ui_root())
If wnd <> 0 Then
    Dim wtitle As WString * 64
    wtitle = "LCUI3 Dashboard - table/chart/forms/portal"
    ptk_window_set_title(wnd, @wtitle)
End If

css = _
    "root { width: 940px; height: 640px; }" & _
    "#app { display: flex; flex-direction: column; width: 100%; height: 100%; padding: 12px; }" & _
    "#header { font-size: 20px; font-weight: bold; margin-bottom: 10px; }" & _
    "#body { display: flex; flex-direction: row; flex: 1; gap: 10px; }" & _
    ".panel {" & _
    "  display: flex; flex-direction: column; padding: 10px;" & _
    "  border: 1px solid #ddd; border-radius: 6px; background-color: #fff;" & _
    "}" & _
    ".panel-title { font-weight: bold; font-size: 14px; margin-bottom: 8px; color: #333; }" & _
    "#left-panel { width: 300px; }" & _
    "#mid-panel { flex: 1; }" & _
    "#right-panel { width: 300px; }" & _
    "" & _
    "/* ---------- 表格 ---------- */" & _
    ".tbl { display: flex; flex-direction: column; width: 100%; border: 1px solid #e0e0e0; }" & _
    ".tbl-row { display: flex; flex-direction: row; width: 100%; }" & _
    ".tbl-row:nth-child(even) .tbl-cell { background-color: #fafafa; }" & _
    ".tbl-row.head .tbl-cell { background-color: #f0f0f0; font-weight: bold; }" & _
    ".tbl-cell { flex: 1; padding: 5px 8px; font-size: 12px; border-right: 1px solid #eee; }" & _
    ".tbl-cell:last-child { border-right: none; }" & _
    "" & _
    "/* ---------- 柱状图 ---------- */" & _
    ".chart { display: flex; flex-direction: row; align-items: flex-end; height: 180px; margin-top: 6px; }" & _
    ".bar {" & _
    "  flex: 1; margin: 0 4px; min-height: 6px;" & _
    "  background-color: #42a5f5; border-radius: 2px 2px 0 0;" & _
    "}" & _
    ".bar:nth-child(even) { background-color: #26a69a; }" & _
    ".bar:nth-child(3n) { background-color: #ef5350; }" & _
    ".chart-labels { display: flex; flex-direction: row; margin-top: 4px; }" & _
    ".chart-labels text { flex: 1; text-align: center; font-size: 11px; color: #777; }" & _
    "" & _
    "/* ---------- 表单 ---------- */" & _
    "#right-panel > * { margin-bottom: 10px; }" & _
    "#progress { width: 100%; height: 10px; }" & _
    "#menu-status { margin-top: 6px; font-size: 12px; color: #444; }" & _
    "/* portal 菜单外观（portal-content 在全局 portal-root 下） */" & _
    ".menu-panel {" & _
    "  display: flex; flex-direction: column; min-width: 140px;" & _
    "  background-color: #fff; border: 1px solid #ccc; border-radius: 4px;" & _
    "  box-shadow: 0 2px 8px rgba(0,0,0,0.15);" & _
    "  padding: 4px 0;" & _
    "}" & _
    ".menu-item {" & _
    "  padding: 6px 12px; font-size: 13px;" & _
    "}" & _
    ".menu-item:hover { background-color: #e8f0fe; }"

ui_load_css_string(StrPtr(css), @"03_dashboard.bas")

app = ui_create_widget(@"div")
ui_widget_set_id(app, @"app")
ui_root_append(app)

header = ui_create_widget(@"text")
ui_widget_set_id(header, @"header")
ui_text_set_content(header, "Dashboard - table / chart / forms / portal")
ui_widget_append(app, header)

body = ui_create_widget(@"div")
ui_widget_set_id(body, @"body")
ui_widget_append(app, body)

' ================= 左：表格 =================
left_col = ui_create_widget(@"div")
ui_widget_set_id(left_col, @"left-panel")
ui_widget_add_class(left_col, @"panel")
ui_widget_append(body, left_col)

txt = ui_create_widget(@"text")
ui_widget_add_class(txt, @"panel-title")
ui_text_set_content(txt, "Data Table")
ui_widget_append(left_col, txt)

Dim As ui_widget_t Ptr tbl = ui_create_widget(@"div")
ui_widget_add_class(tbl, @"tbl")
ui_widget_append(left_col, tbl)

' 表头
row = ui_create_widget(@"div")
ui_widget_add_class(row, @"tbl-row")
ui_widget_add_class(row, @"head")
For i = 1 To 4
    cell = ui_create_widget(@"text")
    ui_widget_add_class(cell, @"tbl-cell")
    Dim htxt As String = "Header-" & i
    ui_text_set_content(cell, StrPtr(htxt))
    ui_widget_append(row, cell)
Next
ui_widget_append(tbl, row)

' 表体
Dim As ui_widget_t Ptr tbody = ui_create_widget(@"div")
ui_widget_set_id(tbody, @"table-body")
ui_widget_append(tbl, tbody)
' 预置 6 行
For i = 1 To 6
    table_rows += 1
    row = ui_create_widget(@"div")
    ui_widget_add_class(row, @"tbl-row")
    For j As Long = 1 To 4
        cell = ui_create_widget(@"text")
        ui_widget_add_class(cell, @"tbl-cell")
        Dim cs As String = "row-" & table_rows & " cell-" & j
        ui_text_set_content(cell, StrPtr(cs))
        ui_widget_append(row, cell)
    Next
    ui_widget_append(tbody, row)
Next

txt = ui_create_widget(@"text")
ui_widget_set_id(txt, @"table-count")
ui_widget_add_class(txt, @"panel-title")
Dim count_s As String = "Table rows: " & table_rows
ui_text_set_content(txt, StrPtr(count_s))
ui_widget_append(left_col, txt)

Dim As ui_widget_t Ptr btn_add = ui_create_widget(@"button")
ui_button_set_text(btn_add, @"Add row")
ui_widget_on(btn_add, @"click", @on_add_table_row, 0)
ui_widget_append(left_col, btn_add)

' ================= 中：柱状图 =================
mid_col = ui_create_widget(@"div")
ui_widget_set_id(mid_col, @"mid-panel")
ui_widget_add_class(mid_col, @"panel")
ui_widget_append(body, mid_col)

txt = ui_create_widget(@"text")
ui_widget_add_class(txt, @"panel-title")
ui_text_set_content(txt, "Bar Chart (click Refresh)")
ui_widget_append(mid_col, txt)

Dim As ui_widget_t Ptr chart = ui_create_widget(@"div")
ui_widget_add_class(chart, @"chart")
ui_widget_append(mid_col, chart)

For i = 0 To 7
    bar = ui_create_widget(@"div")
    ui_widget_add_class(bar, @"bar")
    Dim bh As String = (40 + Int(Rnd * 130)) & "px"
    ui_widget_set_style_string(bar, @"height", StrPtr(bh))
    chart_bars(i) = bar
    ui_widget_append(chart, bar)
Next

bar_labels = ui_create_widget(@"div")
ui_widget_add_class(bar_labels, @"chart-labels")
ui_widget_append(mid_col, bar_labels)
For i = 1 To 8
    txt = ui_create_widget(@"text")
    Dim lb As String = "S" & i
    ui_text_set_content(txt, StrPtr(lb))
    ui_widget_append(bar_labels, txt)
Next

Dim As ui_widget_t Ptr btn_chart = ui_create_widget(@"button")
ui_button_set_text(btn_chart, @"Refresh chart")
ui_widget_on(btn_chart, @"click", @on_refresh_chart, 0)
ui_widget_append(mid_col, btn_chart)

' ================= 右：表单 + 弹层 =================
right_col = ui_create_widget(@"div")
ui_widget_set_id(right_col, @"right-panel")
ui_widget_add_class(right_col, @"panel")
ui_widget_append(body, right_col)

txt = ui_create_widget(@"text")
ui_widget_add_class(txt, @"panel-title")
ui_text_set_content(txt, "Settings (field widgets)")
ui_widget_append(right_col, txt)

' field-set 表单
fset = ui_create_field_set()
ui_widget_append(right_col, fset)

flegend = ui_create_field_legend()
ui_text_set_content(flegend, "Profile")
ui_widget_append(fset, flegend)

fgroup = ui_create_field_group()
ui_widget_append(fset, fgroup)

' --- 文本字段 ---
ffield = ui_create_field()
ui_widget_append(fgroup, ffield)
flabel = ui_create_field_label()
ui_text_set_content(flabel, "Display name")
ui_widget_append(ffield, flabel)
fcontent = ui_create_field_content()
edit = ui_create_widget(@"textinput")
ui_textinput_set_text(edit, @"LCUI user")
ui_widget_append(fcontent, edit)
ui_widget_append(ffield, fcontent)

' --- select 字段 ---
ffield = ui_create_field()
ui_widget_append(fgroup, ffield)
flabel = ui_create_field_label()
ui_text_set_content(flabel, "Region")
ui_widget_append(ffield, flabel)
fcontent = ui_create_field_content()
sel = ui_create_select()
ui_select_add_item(sel, @"East",  @"east")
ui_select_add_item(sel, @"West",  @"west")
ui_select_add_item(sel, @"North", @"north")
ui_select_set_value(sel, @"east")
ui_widget_append(fcontent, sel)
ui_widget_append(ffield, fcontent)

' --- radio 字段 ---
ffield = ui_create_field()
ui_widget_append(fgroup, ffield)
flabel = ui_create_field_label()
ui_text_set_content(flabel, "Theme")
ui_widget_append(ffield, flabel)
fcontent = ui_create_field_content()
radio_group = ui_create_radio_group()
ui_widget_set_attr(radio_group, @"value", @"dark")
radio_item = ui_create_radio_group_item()
ui_widget_set_attr(radio_item, @"value", @"light")
ui_widget_append(radio_group, radio_item)
radio_item = ui_create_radio_group_item()
ui_widget_set_attr(radio_item, @"value", @"dark")
ui_widget_append(radio_group, radio_item)
radio_item = ui_create_radio_group_item()
ui_widget_set_attr(radio_item, @"value", @"auto")
ui_widget_append(radio_group, radio_item)
ui_radio_group_update(radio_group)
ui_widget_append(fcontent, radio_group)
ui_widget_append(ffield, fcontent)

' --- checkbox 字段 ---
ffield = ui_create_field()
ui_widget_append(fgroup, ffield)
flabel = ui_create_field_label()
checkbox = ui_create_checkbox()
fb_ui_checkbox_set_checked(checkbox, 1)
ui_widget_append(flabel, checkbox)
txt = ui_create_widget(@"text")
ui_text_set_content(txt, @"Enable notifications")
ui_widget_append(flabel, txt)
ui_widget_append(ffield, flabel)

' --- 分隔线 + 进度 ---
Dim As ui_widget_t Ptr fsep = ui_create_field_separator()
ui_widget_append(right_col, fsep)

progress_w = ui_create_progress()
ui_widget_set_id(progress_w, @"progress")
ui_progress_set_value(progress_w, 0)
ui_widget_append(right_col, progress_w)

txt = ui_create_widget(@"text")
ui_widget_set_id(txt, @"fps")
ui_text_set_content(txt, @"FPS: -")
ui_widget_append(right_col, txt)

' --- portal 弹层菜单 ---
Dim As ui_widget_t Ptr fsep2 = ui_create_field_separator()
ui_widget_append(right_col, fsep2)

menu_btn = ui_create_widget(@"button")
ui_button_set_text(menu_btn, @"Open menu (portal)")
ui_widget_on(menu_btn, @"click", @on_open_menu, 0)
ui_widget_append(right_col, menu_btn)

txt = ui_create_widget(@"text")
ui_widget_set_id(txt, @"menu-status")
ui_text_set_content(txt, @"Menu: -")
ui_widget_append(right_col, txt)

' 构造 portal 内容（菜单面板）
Dim As ui_widget_t Ptr menu_panel = ui_create_widget(@"div")
ui_widget_add_class(menu_panel, @"menu-panel")
Dim items As String
For i = 0 To 4
    Dim As ui_widget_t Ptr mi = ui_create_widget(@"text")
    ui_widget_add_class(mi, @"menu-item")
    Select Case i
        Case 0: items = "New"
        Case 1: items = "Open..."
        Case 2: items = "Save"
        Case 3: items = "Save As..."
        Case 4: items = "Quit"
    End Select
    ui_text_set_content(mi, StrPtr(items))
    menu_ids(i) = i
    ui_widget_on(mi, @"click", @on_menu_item, @menu_ids(i))
    ui_widget_append(menu_panel, mi)
Next

menu_portal = ui_create_portal()
ui_portal_set_content(menu_portal, menu_panel)
ui_portal_set_anchor(menu_portal, menu_btn)
ui_portal_set_side(menu_portal, @"bottom")
ui_portal_set_side_offset(menu_portal, 4)
ui_portal_set_align(menu_portal, @"start")
ui_widget_append(ui_root(), menu_portal)

' 启动动画
lcui_request_frame(@on_frame, 0)

Dim exit_code As Long
exit_code = lcui_main()
End