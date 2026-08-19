' lcui.bi
' =====================================================================
' FreeBasic bindings for LCUI3 (https://lcui.dev / https://github.com/lc-soft/LCUI)
' Tested against lcui3-3.0.0-x64-release (LCUI 3.0.0)
'
' Usage:
'   #include once "lcui.bi"
'
' Link against the LCUI import library, e.g.:
'   fbc64 -p D:\freebasic\lcui3\lcui3-3.0.0-x64-release\lib -x app.exe app.bas
'   (the -p flag must point at the folder containing lcui.lib)
'
' At run time lcui.dll (from the bin\ folder of the LCUI release) must be
' findable, e.g. by copying it next to the .exe or adding bin\ to PATH.
'
' NOTE: all layout-sensitive types were verified against the C headers
' (struct sizes / member offsets match the x64 build 1:1).
' =====================================================================

#ifndef __LCUI_BI__
#define __LCUI_BI__

#inclib "lcui"

extern "C"
' --- opaque handles ---------------------------------------------------

Type ui_widget_t
    pvt As Any Ptr
End Type

Type ui_event_listener_t
    pvt As Any Ptr
End Type

Type ptk_window_t
    pvt As Any Ptr
End Type

Type pd_context_t
    pvt As Any Ptr
End Type

' --- ui_event_t and friends (must match C layout on x64) --------------

Type ui_mouse_event_t
    x As Single
    y As Single
    button As Long
End Type

Type ui_wheel_event_t
    delta_x As Long
    delta_y As Long
    delta_z As Long
    delta_mode As Long
End Type

Type ui_keyboard_event_t
    code As Long
    alt_key As Boolean
    ctrl_key As Boolean
    shift_key As Boolean
    meta_key As Boolean
    is_composing As Boolean
End Type

Type ui_touch_point_t
    x As Single
    y As Single
    id As Long
    state As Long
    is_primary As Boolean
End Type

Type ui_touch_event_t
    n_points As UInteger
    points As ui_touch_point_t Ptr
End Type

Type ui_textinput_event_t
    text As wstring Ptr
    length As ULong
End Type

Type ui_event_t
    etype As UInteger
    data As Any Ptr
    target As ui_widget_t Ptr
    cancel_bubble As Boolean
    Union
        mouse As ui_mouse_event_t
        wheel As ui_wheel_event_t
        key As ui_keyboard_event_t
        touch As ui_touch_event_t
        text As ui_textinput_event_t
    End Union
End Type

' --- callback signatures ----------------------------------------------

Type ui_event_handler_t As Sub(ByVal w As ui_widget_t Ptr, _
                               ByVal e As ui_event_t Ptr, _
                               ByVal arg As Any Ptr)

Type ui_widget_cb_t As Sub(ByVal w As ui_widget_t Ptr, _
                           ByVal arg As Any Ptr)

Type lcui_frame_cb_t As Sub(ByVal timestamp As ULongInt, _
                            ByVal data As Any Ptr)

' --- event type ids (ui/types.h) --------------------------------------

Enum
    UI_EVENT_NONE
    UI_EVENT_LINK
    UI_EVENT_UNLINK
    UI_EVENT_READY
    UI_EVENT_DESTROY
    UI_EVENT_FOCUS
    UI_EVENT_BLUR
    UI_EVENT_AFTERLAYOUT
    UI_EVENT_KEYDOWN
    UI_EVENT_KEYUP
    UI_EVENT_KEYPRESS
    UI_EVENT_TEXTINPUT
    UI_EVENT_MOUSEOVER
    UI_EVENT_MOUSEMOVE
    UI_EVENT_MOUSEOUT
    UI_EVENT_MOUSEDOWN
    UI_EVENT_MOUSEUP
    UI_EVENT_WHEEL
    UI_EVENT_CLICK
    UI_EVENT_DBLCLICK
    UI_EVENT_TOUCH
    UI_EVENT_TOUCHDOWN
    UI_EVENT_TOUCHUP
    UI_EVENT_TOUCHMOVE
    UI_EVENT_PASTE
    UI_EVENT_CSS_LOAD
    UI_EVENT_CSS_FONT_FACE_LOAD
    UI_EVENT_USER
End Enum

' --- display modes (LCUI/ui.h) ----------------------------------------

Enum
    LCUI_DISPLAY_DEFAULT
    LCUI_DISPLAY_WINDOWED
    LCUI_DISPLAY_FULLSCREEN
    LCUI_DISPLAY_SEAMLESS
End Enum

' =====================================================================
' application lifecycle (LCUI/base.h, LCUI/app.h)
' =====================================================================

Declare Function lcui_get_version Lib "lcui" Alias "lcui_get_version" () As ZString Ptr
Declare Sub lcui_init Lib "lcui" Alias "lcui_init" ()
Declare Sub lcui_destroy Lib "lcui" Alias "lcui_destroy" ()
Declare Function lcui_run Lib "lcui" Alias "lcui_run" () As Long
Declare Function lcui_main Lib "lcui" Alias "lcui_main" () As Long
Declare Sub lcui_exit Lib "lcui" Alias "lcui_exit" (ByVal code As Long)
Declare Sub lcui_quit Lib "lcui" Alias "lcui_quit" ()
Declare Function lcui_set_app_id Lib "lcui" Alias "lcui_set_app_id" (ByVal app_id As ZString Ptr) As Boolean
Declare Function lcui_get_app_id Lib "lcui" Alias "lcui_get_app_id" () As ZString Ptr
Declare Function lcui_get_fps Lib "lcui" Alias "lcui_get_fps" () As UInteger
Declare Sub lcui_set_fps_cap Lib "lcui" Alias "lcui_set_fps_cap" (ByVal fps_cap As UInteger)
Declare Function lcui_request_frame Lib "lcui" Alias "lcui_request_frame" (ByVal cb As lcui_frame_cb_t, ByVal data As Any Ptr) As Long
Declare Sub lcui_cancel_frame Lib "lcui" Alias "lcui_cancel_frame" (ByVal request_id As Long)

' =====================================================================
' UI core (ui/base.h, ui/updater.h, ui/css.h, ui/events.h)
' =====================================================================

Declare Sub ui_init Lib "lcui" Alias "ui_init" ()
Declare Sub ui_destroy Lib "lcui" Alias "ui_destroy" ()
Declare Sub ui_update Lib "lcui" Alias "ui_update" ()

Declare Function ui_root Lib "lcui" Alias "ui_root" () As ui_widget_t Ptr
Declare Function ui_root_append Lib "lcui" Alias "ui_root_append" (ByVal w As ui_widget_t Ptr) As Long
Declare Function ui_create_widget Lib "lcui" Alias "ui_create_widget" (ByVal wtype As ZString Ptr) As ui_widget_t Ptr
Declare Sub ui_widget_destroy Lib "lcui" Alias "ui_widget_destroy" (ByVal w As ui_widget_t Ptr)
Declare Function ui_widget_set_title Lib "lcui" Alias "ui_widget_set_title" (ByVal w As ui_widget_t Ptr, ByVal title As wstring Ptr) As Long
Declare Sub ui_widget_set_text Lib "lcui" Alias "ui_widget_set_text" (ByVal w As ui_widget_t Ptr, ByVal text As ZString Ptr)
Declare Function ui_widget_set_id Lib "lcui" Alias "ui_widget_set_id" (ByVal w As ui_widget_t Ptr, ByVal idstr As ZString Ptr) As Long
Declare Function ui_get_widget Lib "lcui" Alias "ui_get_widget" (ByVal id As ZString Ptr) As ui_widget_t Ptr
Declare Function ui_widget_set_attr Lib "lcui" Alias "ui_widget_set_attr" (ByVal w As ui_widget_t Ptr, ByVal name As ZString Ptr, ByVal value As ZString Ptr) As Long
Declare Function ui_widget_get_attr Lib "lcui" Alias "ui_widget_get_attr" (ByVal w As ui_widget_t Ptr, ByVal name As ZString Ptr) As ZString Ptr
Declare Function ui_widget_add_class Lib "lcui" Alias "ui_widget_add_class" (ByVal w As ui_widget_t Ptr, ByVal class_name As ZString Ptr) As Long
Declare Function ui_widget_has_class Lib "lcui" Alias "ui_widget_has_class" (ByVal w As ui_widget_t Ptr, ByVal class_name As ZString Ptr) As Boolean
Declare Function ui_widget_remove_class Lib "lcui" Alias "ui_widget_remove_class" (ByVal w As ui_widget_t Ptr, ByVal class_name As ZString Ptr) As Long
Declare Function ui_widget_add_status Lib "lcui" Alias "ui_widget_add_status" (ByVal w As ui_widget_t Ptr, ByVal status_name As ZString Ptr) As Long
Declare Function ui_widget_has_status Lib "lcui" Alias "ui_widget_has_status" (ByVal w As ui_widget_t Ptr, ByVal status_name As ZString Ptr) As Boolean
Declare Function ui_widget_remove_status Lib "lcui" Alias "ui_widget_remove_status" (ByVal w As ui_widget_t Ptr, ByVal status_name As ZString Ptr) As Long
Declare Sub ui_widget_set_disabled Lib "lcui" Alias "ui_widget_set_disabled" (ByVal w As ui_widget_t Ptr, ByVal disabled As Boolean)

Declare Function ui_widget_append Lib "lcui" Alias "ui_widget_append" (ByVal parent As ui_widget_t Ptr, ByVal widget As ui_widget_t Ptr) As Long
Declare Function ui_widget_prepend Lib "lcui" Alias "ui_widget_prepend" (ByVal parent As ui_widget_t Ptr, ByVal widget As ui_widget_t Ptr) As Long
Declare Function ui_widget_unwrap Lib "lcui" Alias "ui_widget_unwrap" (ByVal widget As ui_widget_t Ptr) As Long
Declare Function ui_widget_unlink Lib "lcui" Alias "ui_widget_unlink" (ByVal w As ui_widget_t Ptr) As Long
Declare Sub ui_widget_remove Lib "lcui" Alias "ui_widget_remove" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_widget_empty Lib "lcui" Alias "ui_widget_empty" (ByVal w As ui_widget_t Ptr)
Declare Function ui_widget_get_child Lib "lcui" Alias "ui_widget_get_child" (ByVal w As ui_widget_t Ptr, ByVal index As ULong) As ui_widget_t Ptr
Declare Function ui_widget_each Lib "lcui" Alias "ui_widget_each" (ByVal w As ui_widget_t Ptr, ByVal cb As ui_widget_cb_t, ByVal arg As Any Ptr) As ULong
Declare Sub ui_print_tree Lib "lcui" Alias "ui_print_tree" (ByVal w As ui_widget_t Ptr)

Declare Function ui_widget_set_style_string Lib "lcui" Alias "ui_widget_set_style_string" (ByVal w As ui_widget_t Ptr, ByVal property As ZString Ptr, ByVal css_text As ZString Ptr) As Long
Declare Sub ui_widget_show Lib "lcui" Alias "ui_widget_show" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_widget_hide Lib "lcui" Alias "ui_widget_hide" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_widget_move Lib "lcui" Alias "ui_widget_move" (ByVal w As ui_widget_t Ptr, ByVal left As Single, ByVal top As Single)
Declare Sub ui_widget_resize Lib "lcui" Alias "ui_widget_resize" (ByVal w As ui_widget_t Ptr, ByVal width As Single, ByVal height As Single)
Declare Function ui_widget_is_visible Lib "lcui" Alias "ui_widget_is_visible" (ByVal w As ui_widget_t Ptr) As Boolean

Declare Sub ui_widget_request_update Lib "lcui" Alias "ui_widget_request_update" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_widget_request_reflow Lib "lcui" Alias "ui_widget_request_reflow" (ByVal w As ui_widget_t Ptr)

Declare Function ui_load_css_file Lib "lcui" Alias "ui_load_css_file" (ByVal filepath As ZString Ptr) As Long
Declare Function ui_load_css_string Lib "lcui" Alias "ui_load_css_string" (ByVal str As ZString Ptr, ByVal space As ZString Ptr) As ULong

' events
Declare Function ui_widget_on Lib "lcui" Alias "ui_widget_on" (ByVal w As ui_widget_t Ptr, ByVal event_name As ZString Ptr, ByVal handler As ui_event_handler_t, ByVal data As Any Ptr) As ui_event_listener_t Ptr
Declare Function ui_widget_off Lib "lcui" Alias "ui_widget_off" (ByVal w As ui_widget_t Ptr, ByVal event_name As ZString Ptr, ByVal handler As ui_event_handler_t, ByVal data As Any Ptr) As Long
Declare Function ui_get_focus Lib "lcui" Alias "ui_get_focus" () As ui_widget_t Ptr
Declare Function ui_set_focus Lib "lcui" Alias "ui_set_focus" (ByVal w As ui_widget_t Ptr) As Long
Declare Sub ui_event_init Lib "lcui" Alias "ui_event_init" (ByVal e As ui_event_t Ptr, ByVal name As ZString Ptr)
Declare Function ui_get_event_id Lib "lcui" Alias "ui_get_event_id" (ByVal event_name As ZString Ptr) As Long

' display
Declare Sub lcui_ui_set_display Lib "lcui" Alias "lcui_ui_set_display" (ByVal mode As Long)

' =====================================================================
' built-in widgets (LCUI/widgets/*.h)
' =====================================================================

' text
Declare Function ui_text_set_content Lib "lcui" Alias "ui_text_set_content" (ByVal w As ui_widget_t Ptr, ByVal utf8_text As ZString Ptr) As Long
Declare Function ui_text_set_content_w Lib "lcui" Alias "ui_text_set_content_w" (ByVal w As ui_widget_t Ptr, ByVal text As wstring Ptr) As Long
Declare Sub ui_text_set_multiline Lib "lcui" Alias "ui_text_set_multiline" (ByVal w As ui_widget_t Ptr, ByVal enable As Boolean)
Declare Sub ui_register_text Lib "lcui" Alias "ui_register_text" ()

' button
Declare Sub ui_button_set_text Lib "lcui" Alias "ui_button_set_text" (ByVal w As ui_widget_t Ptr, ByVal str As ZString Ptr)
Declare Sub ui_button_set_text_w Lib "lcui" Alias "ui_button_set_text_w" (ByVal w As ui_widget_t Ptr, ByVal wstr As wstring Ptr)
Declare Sub ui_register_button Lib "lcui" Alias "ui_register_button" ()

' textinput
Declare Function ui_textinput_set_text Lib "lcui" Alias "ui_textinput_set_text" (ByVal w As ui_widget_t Ptr, ByVal utf8_str As ZString Ptr) As Long
Declare Function ui_textinput_get_text_w Lib "lcui" Alias "ui_textinput_get_text_w" (ByVal w As ui_widget_t Ptr, ByVal start As ULong, ByVal max_len As ULong, ByVal buf As wstring Ptr) As ULong
Declare Function ui_textinput_get_text_length Lib "lcui" Alias "ui_textinput_get_text_length" (ByVal w As ui_widget_t Ptr) As ULong
Declare Function ui_textinput_set_placeholder Lib "lcui" Alias "ui_textinput_set_placeholder" (ByVal w As ui_widget_t Ptr, ByVal str As ZString Ptr) As Long
Declare Sub ui_textinput_enable_multiline Lib "lcui" Alias "ui_textinput_enable_multiline" (ByVal w As ui_widget_t Ptr, ByVal enable As Boolean)
Declare Sub ui_textinput_clear_text Lib "lcui" Alias "ui_textinput_clear_text" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_register_textinput Lib "lcui" Alias "ui_register_textinput" ()

' label
Declare Function ui_create_label Lib "lcui" Alias "ui_create_label" () As ui_widget_t Ptr
Declare Sub ui_register_label Lib "lcui" Alias "ui_register_label" ()

' checkbox
Declare Function ui_create_checkbox Lib "lcui" Alias "ui_create_checkbox" () As ui_widget_t Ptr
Declare Sub ui_register_checkbox Lib "lcui" Alias "ui_register_checkbox" ()

' progress
Declare Function ui_create_progress Lib "lcui" Alias "ui_create_progress" () As ui_widget_t Ptr
Declare Sub ui_progress_set_value Lib "lcui" Alias "ui_progress_set_value" (ByVal w As ui_widget_t Ptr, ByVal value As Single)
Declare Function ui_progress_get_value Lib "lcui" Alias "ui_progress_get_value" (ByVal w As ui_widget_t Ptr) As Single
Declare Sub ui_register_progress Lib "lcui" Alias "ui_register_progress" ()

' select
Declare Function ui_create_select Lib "lcui" Alias "ui_create_select" () As ui_widget_t Ptr
Declare Sub ui_select_set_placeholder Lib "lcui" Alias "ui_select_set_placeholder" (ByVal w As ui_widget_t Ptr, ByVal placeholder As ZString Ptr)
Declare Function ui_select_get_placeholder Lib "lcui" Alias "ui_select_get_placeholder" (ByVal w As ui_widget_t Ptr) As ZString Ptr
Declare Sub ui_select_set_value Lib "lcui" Alias "ui_select_set_value" (ByVal w As ui_widget_t Ptr, ByVal value As ZString Ptr)
Declare Function ui_select_get_value Lib "lcui" Alias "ui_select_get_value" (ByVal w As ui_widget_t Ptr) As ZString Ptr
Declare Sub ui_select_open Lib "lcui" Alias "ui_select_open" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_select_close Lib "lcui" Alias "ui_select_close" (ByVal w As ui_widget_t Ptr)
Declare Function ui_select_add_item Lib "lcui" Alias "ui_select_add_item" (ByVal w As ui_widget_t Ptr, ByVal label As ZString Ptr, ByVal value As ZString Ptr) As ui_widget_t Ptr
Declare Sub ui_select_clear_items Lib "lcui" Alias "ui_select_clear_items" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_register_select Lib "lcui" Alias "ui_register_select" ()

' radio group
Declare Function ui_create_radio_group Lib "lcui" Alias "ui_create_radio_group" () As ui_widget_t Ptr
Declare Function ui_create_radio_group_item Lib "lcui" Alias "ui_create_radio_group_item" () As ui_widget_t Ptr
Declare Sub ui_radio_group_update Lib "lcui" Alias "ui_radio_group_update" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_register_radio_group Lib "lcui" Alias "ui_register_radio_group" ()

' scrollarea
Declare Function ui_create_scrollarea Lib "lcui" Alias "ui_create_scrollarea" () As ui_widget_t Ptr
Declare Function ui_create_scrollarea_content Lib "lcui" Alias "ui_create_scrollarea_content" () As ui_widget_t Ptr
Declare Sub ui_scrollarea_update Lib "lcui" Alias "ui_scrollarea_update" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_scrollarea_set_wheel_scroll_direction Lib "lcui" Alias "ui_scrollarea_set_wheel_scroll_direction" (ByVal w As ui_widget_t Ptr, ByVal direction As Long)
Declare Sub ui_scrollarea_set_scroll_top Lib "lcui" Alias "ui_scrollarea_set_scroll_top" (ByVal w As ui_widget_t Ptr, ByVal value As Single)
Declare Sub ui_scrollarea_set_scroll_left Lib "lcui" Alias "ui_scrollarea_set_scroll_left" (ByVal w As ui_widget_t Ptr, ByVal value As Single)
Declare Function ui_scrollarea_get_scroll_top Lib "lcui" Alias "ui_scrollarea_get_scroll_top" (ByVal w As ui_widget_t Ptr) As Single
Declare Function ui_scrollarea_get_scroll_left Lib "lcui" Alias "ui_scrollarea_get_scroll_left" (ByVal w As ui_widget_t Ptr) As Single
Declare Sub ui_register_scrollarea Lib "lcui" Alias "ui_register_scrollarea" ()

' scrollbar
Declare Function ui_create_scrollbar Lib "lcui" Alias "ui_create_scrollbar" () As ui_widget_t Ptr
Declare Sub ui_scrollbar_update Lib "lcui" Alias "ui_scrollbar_update" (ByVal w As ui_widget_t Ptr)
Declare Sub ui_scrollbar_set_orientation Lib "lcui" Alias "ui_scrollbar_set_orientation" (ByVal w As ui_widget_t Ptr, ByVal orientation As Long)
Declare Sub ui_register_scrollbar Lib "lcui" Alias "ui_register_scrollbar" ()

' portal（弹层）
Declare Function ui_create_portal Lib "lcui" Alias "ui_create_portal" () As ui_widget_t Ptr
Declare Sub ui_portal_set_content Lib "lcui" Alias "ui_portal_set_content" (ByVal portal As ui_widget_t Ptr, ByVal content As ui_widget_t Ptr)
Declare Function ui_portal_get_content Lib "lcui" Alias "ui_portal_get_content" (ByVal portal As ui_widget_t Ptr) As ui_widget_t Ptr
Declare Sub ui_portal_set_anchor Lib "lcui" Alias "ui_portal_set_anchor" (ByVal portal As ui_widget_t Ptr, ByVal anchor As ui_widget_t Ptr)
Declare Sub ui_portal_set_side Lib "lcui" Alias "ui_portal_set_side" (ByVal portal As ui_widget_t Ptr, ByVal side As ZString Ptr)
Declare Sub ui_portal_set_side_offset Lib "lcui" Alias "ui_portal_set_side_offset" (ByVal portal As ui_widget_t Ptr, ByVal offset As Long)
Declare Sub ui_portal_set_align Lib "lcui" Alias "ui_portal_set_align" (ByVal portal As ui_widget_t Ptr, ByVal align As ZString Ptr)
Declare Sub ui_portal_set_align_offset Lib "lcui" Alias "ui_portal_set_align_offset" (ByVal portal As ui_widget_t Ptr, ByVal offset As Long)
Declare Sub ui_portal_open Lib "lcui" Alias "ui_portal_open" (ByVal portal As ui_widget_t Ptr)
Declare Sub ui_portal_close Lib "lcui" Alias "ui_portal_close" (ByVal portal As ui_widget_t Ptr)
Declare Function ui_get_portal_root Lib "lcui" Alias "ui_get_portal_root" () As ui_widget_t Ptr
Declare Sub ui_register_portal Lib "lcui" Alias "ui_register_portal" ()

' field 系列（表单字段）
Declare Function ui_create_field Lib "lcui" Alias "ui_create_field" () As ui_widget_t Ptr
Declare Sub ui_register_field Lib "lcui" Alias "ui_register_field" ()
Declare Function ui_create_field_set Lib "lcui" Alias "ui_create_field_set" () As ui_widget_t Ptr
Declare Sub ui_register_field_set Lib "lcui" Alias "ui_register_field_set" ()
Declare Function ui_create_field_legend Lib "lcui" Alias "ui_create_field_legend" () As ui_widget_t Ptr
Declare Sub ui_register_field_legend Lib "lcui" Alias "ui_register_field_legend" ()
Declare Function ui_create_field_group Lib "lcui" Alias "ui_create_field_group" () As ui_widget_t Ptr
Declare Sub ui_register_field_group Lib "lcui" Alias "ui_register_field_group" ()
Declare Function ui_create_field_label Lib "lcui" Alias "ui_create_field_label" () As ui_widget_t Ptr
Declare Sub ui_register_field_label Lib "lcui" Alias "ui_register_field_label" ()
Declare Function ui_create_field_description Lib "lcui" Alias "ui_create_field_description" () As ui_widget_t Ptr
Declare Sub ui_register_field_description Lib "lcui" Alias "ui_register_field_description" ()
Declare Function ui_create_field_separator Lib "lcui" Alias "ui_create_field_separator" () As ui_widget_t Ptr
Declare Sub ui_register_field_separator Lib "lcui" Alias "ui_register_field_separator" ()
Declare Function ui_create_field_content Lib "lcui" Alias "ui_create_field_content" () As ui_widget_t Ptr
Declare Sub ui_register_field_content Lib "lcui" Alias "ui_register_field_content" ()
Declare Function ui_create_field_title Lib "lcui" Alias "ui_create_field_title" () As ui_widget_t Ptr
Declare Sub ui_register_field_title Lib "lcui" Alias "ui_register_field_title" ()

' =====================================================================
' window (ui_server.h, ptk/window.h)
' =====================================================================

Declare Function ui_server_get_window Lib "lcui" Alias "ui_server_get_window" (ByVal w As ui_widget_t Ptr) As ptk_window_t Ptr
Declare Sub ptk_window_set_title Lib "lcui" Alias "ptk_window_set_title" (ByVal wnd As ptk_window_t Ptr, ByVal title As wstring Ptr)
Declare Sub ptk_window_set_size Lib "lcui" Alias "ptk_window_set_size" (ByVal wnd As ptk_window_t Ptr, ByVal width As Long, ByVal height As Long)
Declare Function ptk_window_get_width Lib "lcui" Alias "ptk_window_get_width" (ByVal wnd As ptk_window_t Ptr) As Long
Declare Function ptk_window_get_height Lib "lcui" Alias "ptk_window_get_height" (ByVal wnd As ptk_window_t Ptr) As Long

' =====================================================================
' image / canvas (LCUI/widgets/canvas.h, pandagl/canvas.h, ui/image.h)
' =====================================================================
' 注意：FreeBasic 64 位下 Integer/UInteger 是 8 字节，而 C 的 int/unsigned 是
' 4 字节，必须用 Long/ULong（fbc64 里为 32 位）。以下结构体经 offsetof 核对，
' 与 x64 C 布局一致。

Type pd_rect_t field = 1
    x As Long
    y As Long
    width As Long
    height As Long
End Type

Type pd_color_t field = 1
    value As ULong
End Type

Type pd_canvas_quote_t field = 1
    top As Long
    left As Long
    is_valid As Boolean
    pad(0 To 6) As Byte
    source As Any Ptr
End Type

Type pd_canvas_t field = 1
    width As ULong
    height As ULong
    opacity As Single
    padq(0 To 3) As Byte
    quote As pd_canvas_quote_t
    bytes As Any Ptr
    color_type As Long
    bytes_per_pixel As ULong
    bytes_per_row As ULong
    padm(0 To 3) As Byte
    mem_size As ULongInt
End Type

' 图像状态/事件（ui/image.h）
Enum
    UI_IMAGE_STATE_PENDING
    UI_IMAGE_STATE_LOADING
    UI_IMAGE_STATE_COMPLETE
End Enum

Enum
    UI_IMAGE_EVENT_LOAD
    UI_IMAGE_EVENT_PROGRESS
    UI_IMAGE_EVENT_ERROR
End Enum

Type ui_image_t field = 1
    data As pd_canvas_t
    error As Long
    state As Long
    path As Any Ptr
    progress As Single
    pad(0 To 3) As Byte
End Type

Type ui_image_event_t field = 1
    type As Long
    pad(0 To 3) As Byte
    image As ui_image_t Ptr
    data As Any Ptr
End Type

Type ui_image_event_handler_t As Sub CDecl(ByVal e As ui_image_event_t Ptr)

' 画布绘制上下文（LCUI/widgets/canvas.h）
Type ui_canvas_context_t field = 1
    available As Boolean
    padv(0 To 2) As Byte
    fill_color As pd_color_t
    buffer As pd_canvas_t
    canvas As Any Ptr
    node_next As Any Ptr
    node_prev As Any Ptr
    scale As Single
    width As Long
    height As Long
    padf(0 To 3) As Byte
    fill_rect_fn As Any Ptr
    clear_rect_fn As Any Ptr
    release_fn As Any Ptr
End Type

' 脏矩形盒类型（ui/types.h）
Enum
    UI_BOX_TYPE_CONTENT_BOX
    UI_BOX_TYPE_PADDING_BOX
    UI_BOX_TYPE_BORDER_BOX
    UI_BOX_TYPE_GRAPH_BOX
End Enum

Declare Sub ui_register_canvas Lib "lcui" Alias "ui_register_canvas" ()
Declare Function ui_canvas_get_context Lib "lcui" Alias "ui_canvas_get_context" (ByVal w As ui_widget_t Ptr) As ui_canvas_context_t Ptr

Declare Function ui_widget_mark_dirty_rect Lib "lcui" Alias "ui_widget_mark_dirty_rect" (ByVal w As ui_widget_t Ptr, ByVal in_rect As Any Ptr, ByVal box_type As Long) As Boolean

' pandagl canvas 基础操作（lib/pandagl/include/pandagl/canvas.h）
Declare Sub pd_canvas_init Lib "lcui" Alias "pd_canvas_init" (ByVal canvas As pd_canvas_t Ptr)
Declare Function pd_canvas_create Lib "lcui" Alias "pd_canvas_create" (ByVal canvas As pd_canvas_t Ptr, ByVal width As ULong, ByVal height As ULong) As Long
Declare Sub pd_canvas_destroy Lib "lcui" Alias "pd_canvas_destroy" (ByVal canvas As pd_canvas_t Ptr)
Declare Function pd_canvas_fill Lib "lcui" Alias "pd_canvas_fill" (ByVal canvas As pd_canvas_t Ptr, ByVal color As pd_color_t) As Long
Declare Function pd_canvas_mix Lib "lcui" Alias "pd_canvas_mix" (ByVal back As pd_canvas_t Ptr, ByVal fore As pd_canvas_t Ptr, ByVal left As Long, ByVal top As Long, ByVal with_alpha As Boolean) As Long
Declare Function pd_read_image_from_file Lib "lcui" Alias "pd_read_image_from_file" (ByVal filepath As ZString Ptr, ByVal out_canvas As pd_canvas_t Ptr) As Long
Declare Function pd_write_png_file Lib "lcui" Alias "pd_write_png_file" (ByVal file_name As ZString Ptr, ByVal graph As pd_canvas_t Ptr) As Long

' 图像加载（ui/image.h）—— lcui_init 后 lcui 会自动启动加载线程
Declare Function ui_image_create Lib "lcui" Alias "ui_image_create" (ByVal path As ZString Ptr) As ui_image_t Ptr
Declare Function ui_get_image Lib "lcui" Alias "ui_get_image" (ByVal path As ZString Ptr) As ui_image_t Ptr
Declare Sub ui_image_destroy Lib "lcui" Alias "ui_image_destroy" (ByVal image As ui_image_t Ptr)
Declare Function ui_image_add_event_listener Lib "lcui" Alias "ui_image_add_event_listener" (ByVal image As ui_image_t Ptr, ByVal type As Long, ByVal handler As ui_image_event_handler_t, ByVal data As Any Ptr) As Boolean

' =====================================================================
' FreeBasic helper macros
' =====================================================================

' ui_checkbox_set_checked / ui_checkbox_get_checked are static-inline in
' the C headers (not exported), so they are re-implemented here.
Private Function fb_ui_checkbox_set_checked(ByVal w As ui_widget_t Ptr, ByVal checked As Long) As Long
    Return ui_widget_set_attr(w, @"checked", IIf(checked <> 0, @"true", @"false"))
End Function

Private Function fb_ui_checkbox_get_checked(ByVal w As ui_widget_t Ptr) As Long
    Dim v As ZString Ptr = ui_widget_get_attr(w, @"checked")
    If (v <> 0) AndAlso (*v <> 0) Then
        If (*v = Asc("t")) Then Return 1
    End If
    Return 0
End Function

' UTF-8 encoded string helper: embeds the bytes of a source string
' verbatim.  Pass the result to any LCUI function expecting const char*.
Private Function fb_utf8(ByRef s As Const String) As ZString Ptr
    Static As ZString * 4096 buf
    buf = s
    Return @buf
End Function
end extern
#endif