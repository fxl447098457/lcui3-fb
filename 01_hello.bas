' 01_hello.bas
' =====================================================================
' LCUI3 示例 1：Hello World
'
' 用纯 FreeBasic 代码构建界面（不使用 XML）：
'   - 一个文本部件 (text) 显示问候语
'   - 一个文本框 (textinput) 输入文字
'   - 一个按钮 (button)，点击后把文本框内容显示到文本部件里
'
' 编译:
'   fbc64 -p <lcui_lib目录> -x 01_hello.exe 01_hello.bas
' =====================================================================
#include once "inc/lcui.bi"

' 按钮点击事件回调
Sub on_btn_click cdecl(ByVal self As ui_widget_t Ptr, ByVal e As ui_event_t Ptr, _
                 ByVal arg As Any Ptr)
    Dim As ui_widget_t Ptr edit = ui_get_widget(@"edit")
    Dim As ui_widget_t Ptr txt  = ui_get_widget(@"text-hello")
    Dim wbuf As WString * 512

    ui_textinput_get_text_w(edit, 0, 511, @wbuf)
    ui_text_set_content_w(txt, @wbuf)
End Sub

Dim As ui_widget_t Ptr txt, edit, btn
Dim As String css

' 初始化 LCUI（创建窗口、加载设置等）
lcui_init()

' 通过 CSS 字符串定义界面样式
css = _
    "text.text-hello {" & _
    "  font-size: 18px;" & _
    "  font-family: 'Segoe UI';" & _
    "  text-align: center;" & _
    "  padding: 25px;" & _
    "  margin: 25px;" & _
    "  border: 1px solid #eee;" & _
    "  background-color: #f8f9fa;" & _
    "}" & _
    "#btn, #edit { margin: 0 0 0 25px; }"

ui_load_css_string(StrPtr(css), @"hello.bas")

' 文本部件
txt = ui_create_widget(@"text")
ui_widget_set_id(txt, @"text-hello")
ui_widget_add_class(txt, @"text-hello")
ui_text_set_content(txt, @"Hello, FreeBasic + LCUI!")
ui_root_append(txt)

' 文本框
edit = ui_create_widget(@"textinput")
ui_widget_set_id(edit, @"edit")
ui_textinput_set_text(edit, @"Type something here...")
ui_root_append(edit)

' 按钮
btn = ui_create_widget(@"button")
ui_widget_set_id(btn, @"btn")
ui_button_set_text(btn, @"Change")
ui_widget_on(btn, @"click", @on_btn_click, 0)
ui_root_append(btn)

' 进入主循环，直到窗口被关闭
Dim exit_code As Long
exit_code = lcui_main()
End
