class ZCL_GLOBAL_SETTINGS_EDITOR definition
  public
  final
  create public .

public section.

  types:
    tt_description TYPE TABLE OF ztb_set_descript .
  types:
    tt_tabcfg      TYPE TABLE OF ztb_set_variable .
  types:
    BEGIN OF t_data,
        var_name TYPE tabname,
        var_type TYPE rs38l_typ,
        is_var   TYPE xfeld,
        is_table TYPE xfeld,
        datatab  TYPE REF TO data,
        old      TYPE REF TO data,
      END OF t_data .
  types:
    tt_data TYPE TABLE OF t_data .
  types:
    BEGIN OF t_stack,
        func     TYPE text10,
        var_name TYPE rs38l_par_,
        keyline  TYPE string,
        datanew  TYPE REF TO data,
        dataold  TYPE REF TO data,
      END OF t_stack .
  types:
    tt_stack TYPE TABLE OF t_stack .
  types:
    BEGIN OF t_stackmess,
        message TYPE text80,
      END OF t_stackmess .
  types:
    tt_stackmess TYPE TABLE OF t_stackmess .

  constants:
    BEGIN OF mc_func,
        exit    TYPE sy-ucomm VALUE 'EXIT',
        save    TYPE sy-ucomm VALUE 'DBSAVE',
        history TYPE sy-ucomm VALUE 'HIST',
      END OF mc_func .
  constants:
    BEGIN OF mc_status,
        main_prog TYPE sy-repid VALUE 'ZPR_GLOBAL_SETTINGS',
        main_stat TYPE sy-pfkey VALUE 'ZMAIN',
        hist_prog TYPE sy-repid VALUE 'ZPR_GLOBAL_SETTINGS',
        hist_stat TYPE sy-pfkey VALUE 'SALV_HIST',
      END OF mc_status .

  class-methods MAIN
    importing
      !IV_PROJ type AKB_PROJECT_NAME .
  class-methods PAI .
  class-methods PBO .
  methods CONSTRUCTOR
    importing
      !IV_PROJ type AKB_PROJECT_NAME .
protected section.
private section.

  data MR_GS type ref to ZCL_GS .
  class-data INSTANCE type ref to ZCL_GLOBAL_SETTINGS_EDITOR .
  data MR_LEFT_ALV type ref to CL_SALV_TABLE .
  data MR_RIGHT_ALV type ref to CL_GUI_ALV_GRID .
  data MR_BOT_ALV type ref to CL_SALV_TABLE .
  data MT_DIR type TT_TABCFG .
  data MS_CDATA type T_DATA .
  data MT_DATA type TT_DATA .
  data MT_DESCRIPTION type TT_DESCRIPTION .
  data HIST_ALV type ref to CL_SALV_TABLE .
  data HIST_DATA type ref to DATA .
  data HIST_MAX type BRF_EXPRESSION_VERSION .
  data MV_PROJ type AKB_PROJECT_NAME .
  data MR_RIGHT_CONT type ref to CL_GUI_CONTAINER .
  data MR_MAIN_CONT type ref to CL_GUI_CUSTOM_CONTAINER .
  data MV_FIRST_RUN type XFELD .

  class-methods INSTANCE_BUILD .
  methods LOAD_DATA .
  methods BUILD_ALV .
  methods HISTORY .
  methods ON_USER_COMMAND
    for event ADDED_FUNCTION of CL_SALV_EVENTS_TABLE
    importing
      !E_SALV_FUNCTION .
  methods ON_LEFT_LINK_CLICK
    for event LINK_CLICK of CL_SALV_EVENTS_TABLE
    importing
      !ROW
      !COLUMN .
  methods EXIT .
  methods SAVE .
  methods CHOOSE
    importing
      value(IV_ROW) type SALV_DE_ROW optional .
  methods EXCLUDE_TB_FUNCTIONS_TABNAME
    changing
      !PT_EXCLUDE type UI_FUNCTIONS .
ENDCLASS.



CLASS ZCL_GLOBAL_SETTINGS_EDITOR IMPLEMENTATION.


  METHOD build_alv.


*** Containers


    DATA(split_cont) = NEW cl_gui_splitter_container(
                             parent  = mr_main_cont
                             rows    = 1
                             columns = 2 ).

    DATA(leftall_cont) = split_cont->get_container( row = 1 column = 1 ).

    DATA(leftsplit_cont) = NEW cl_gui_splitter_container(
                             parent  = leftall_cont
                             rows    = 2
                             columns = 1 ).

    DATA(left_cont)  = leftsplit_cont->get_container( row = 1 column = 1 ).
    DATA(bot_cont)   = leftsplit_cont->get_container( row = 2 column = 1 ).
    mr_right_cont = split_cont->get_container( row = 1 column = 2 ).

    split_cont->set_column_width( id = 1 width = 40 ). " %

*** Left alv
    TRY.
        cl_salv_table=>factory(
          EXPORTING
            r_container    = left_cont
          IMPORTING
            r_salv_table   = mr_left_alv
          CHANGING
            t_table        = mt_dir
             ).
      CATCH cx_salv_msg INTO DATA(ex).
        DATA(msg) = ex->get_message( ).
        IF msg-msgty IS INITIAL. " Очень качественный эксепшн
          msg-msgty = 'E'.
        ENDIF.
        MESSAGE ID msg-msgid TYPE msg-msgty NUMBER msg-msgno
          WITH msg-msgv1 msg-msgv2 msg-msgv3 msg-msgv4.
    ENDTRY.

    TRY .
        DATA(columns) = mr_left_alv->get_columns( ).
        columns->set_optimize( abap_true ).
        DATA(column) = CAST cl_salv_column_table( columns->get_column( 'VAR_NAME' ) ).
        column->set_cell_type( if_salv_c_cell_type=>hotspot ).
        DATA(comps) = cl_salv_ddic=>get_by_data( mt_dir ).
        IF line_exists( comps[ fieldname = 'CLNT' ] ).
          columns->get_column( CONV #( comps[ fieldname = 'CLNT' ]-fieldname )
            )->set_visible( abap_false ).
        ENDIF.
        IF line_exists( comps[ fieldname = 'PROJECT' ] ).
          columns->get_column( CONV #( comps[ fieldname = 'PROJECT' ]-fieldname )
            )->set_visible( abap_false ).
        ENDIF.


        IF line_exists( comps[ fieldname = 'SCRTEXT_M' ] ).
          columns->get_column( CONV #( comps[ fieldname = 'SCRTEXT_M' ]-fieldname )
            )->set_visible( abap_false ).
        ENDIF.


      CATCH cx_salv_not_found INTO DATA(ex1).
        msg = ex1->get_message( ).
        IF msg-msgty IS INITIAL. " Очень качественный эксепшн
          msg-msgty = 'E'.
        ENDIF.
        MESSAGE ID msg-msgid TYPE msg-msgty NUMBER msg-msgno
          WITH msg-msgv1 msg-msgv2 msg-msgv3 msg-msgv4.
    ENDTRY.

    mr_left_alv->get_functions( )->set_default( ).
    mr_left_alv->get_display_settings( )->set_list_header( 'Variables' ).
    mr_left_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>single ).

    DATA(event) = mr_left_alv->get_event( ).
    SET HANDLER on_left_link_click FOR event.



*** Bottom alv
    TYPES: BEGIN OF t_tmp,
             line TYPE string,
           END OF t_tmp.

    DATA temp2 TYPE TABLE OF t_tmp.
    TRY.
        cl_salv_table=>factory(
          EXPORTING
            r_container    = bot_cont
          IMPORTING
            r_salv_table   = mr_bot_alv
          CHANGING
            t_table        = temp2
             ).
      CATCH cx_salv_msg INTO ex.
        msg = ex->get_message( ).
        IF msg-msgty IS INITIAL. " Очень качественный эксепшн
          msg-msgty = 'E'.
        ENDIF.
        MESSAGE ID msg-msgid TYPE msg-msgty NUMBER msg-msgno
          WITH msg-msgv1 msg-msgv2 msg-msgv3 msg-msgv4.
    ENDTRY.

    mr_bot_alv->get_display_settings( )->set_list_header( 'Description' ).
    mr_bot_alv->get_columns( )->set_headers_visible( abap_false ).

    mr_left_alv->display( ).
    mr_bot_alv->display( ).

  ENDMETHOD.


  METHOD choose.
    DATA
        : lt_comp_tab    TYPE cl_abap_structdescr=>component_table
        , ls_comp        LIKE LINE OF lt_comp_tab
        , lr_struct_type TYPE REF TO cl_abap_structdescr
        , lr_dref_tmp TYPE REF TO data

        , lt_fcat TYPE lvc_t_fcat
        , lr_tabletype  TYPE REF TO cl_abap_tabledescr
        , lr_rowtype    TYPE REF TO cl_abap_structdescr
        , lr_test       TYPE REF TO cl_abap_datadescr
        , lt_ddict TYPE  dd_x031l_table

        , lt_fields TYPE ddfields

        , ls_layout   TYPE lvc_s_layo
        , lt_exclude  TYPE ui_functions

        , idetails TYPE abap_compdescr_tab
        , lv_struct_name TYPE dd02l-tabname
        , lv_field_name TYPE fieldname
        .



    FIELD-SYMBOLS
                   : <fs_struct> TYPE any
                   .

    IF iv_row = 0.
      mr_left_alv->get_metadata( ). " Вызывать перед запросом выделения...
      DATA(cells) = mr_left_alv->get_selections( )->get_selected_cells( ).
      IF lines( cells ) = 0.
        MESSAGE 'Chose variable' TYPE 'S' DISPLAY LIKE 'W'.
        EXIT.
      ELSEIF lines( cells ) > 1.
        MESSAGE 'Chose one variable' TYPE 'S' DISPLAY LIKE 'W'.
        EXIT.
      ENDIF.
      iv_row = cells[ 1 ]-row.
    ENDIF.
    DATA(var_name) = mt_dir[ iv_row ]-var_name.
    DATA(var_type) = mt_dir[ iv_row ]-var_type.


    FIELD-SYMBOLS: <tabdata> TYPE table,
                   <tdline>  TYPE t_data,
                   <old>     TYPE table.
    IF line_exists( mt_data[ var_name = var_name ] ).
      ASSIGN mt_data[ var_name = var_name ] TO <tdline>.

    ELSE.
      APPEND INITIAL LINE TO mt_data ASSIGNING <tdline>.

      mr_gs->get_object_table( EXPORTING iv_var_name = var_name
                               IMPORTING ev_data = <tdline>-datatab
                                 ev_single_var = <tdline>-is_var ).

      ASSIGN <tdline>-datatab->* TO <tabdata>.
      CREATE DATA <tdline>-old LIKE <tabdata>.
      ASSIGN <tdline>-old->* TO <old>.

      <old> = <tabdata>.
    ENDIF.

    ASSIGN <tdline>-datatab->* TO <tabdata>.

    <tdline>-var_name = var_name.
    <tdline>-var_type = var_type.
    <tdline>-is_table = mt_dir[ iv_row ]-is_table.

    ms_cdata = <tdline>.

    IF mr_right_alv IS BOUND.
      mr_right_alv->free( ).
      FREE mr_right_alv.
    ENDIF.

    CREATE OBJECT mr_right_alv
      EXPORTING
        i_appl_events = 'X'
        i_parent      = mr_right_cont.

    CALL METHOD mr_right_alv->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter.


    lr_tabletype ?= cl_abap_typedescr=>describe_by_data( <tabdata> ).
    lr_rowtype   ?= lr_tabletype->get_table_line_type( ).


    IF ms_cdata-is_var IS INITIAL.
      lv_struct_name = ms_cdata-var_type.
    ELSE.

      SELECT SINGLE tabname fieldname
        FROM dd03l
        INTO (lv_struct_name, lv_field_name)
        WHERE rollname = ms_cdata-var_type.

    ENDIF.

    CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
      EXPORTING
        i_structure_name   = lv_struct_name
        i_bypassing_buffer = 'X'
      CHANGING
        ct_fieldcat        = lt_fcat.

    IF ms_cdata-is_var IS NOT INITIAL..

      DELETE lt_fcat WHERE fieldname NE lv_field_name.

      READ TABLE lt_fcat INDEX 1 ASSIGNING FIELD-SYMBOL(<fs_fcat>).
      <fs_fcat>-fieldname = 'TABLELINE'.
      <fs_fcat>-ref_field = lv_field_name.

    ENDIF.

    LOOP AT lt_fcat ASSIGNING <fs_fcat>.
      <fs_fcat>-edit = 'X'.
    ENDLOOP.



    ls_layout-cwidth_opt = 'X'.
    ls_layout-grid_title = var_name.
    ls_layout-sel_mode   = 'A'.
    ls_layout-zebra      = 'X'.

    exclude_tb_functions_tabname( CHANGING pt_exclude = lt_exclude ).

    CALL METHOD mr_right_alv->set_table_for_first_display
      EXPORTING
        it_toolbar_excluding = lt_exclude
        is_layout            = ls_layout
      CHANGING
        it_outtab            = <tabdata>
        it_fieldcatalog      = lt_fcat.


    REFRESH mt_description.

    SELECT  * INTO TABLE mt_description
      FROM ztb_set_descript
      WHERE project = mv_proj
      AND var_name = var_name
      ORDER BY npp.


    TRY.
        mr_bot_alv->set_data( CHANGING t_table = mt_description ).
        DATA(comps) = cl_salv_ddic=>get_by_data( mt_description ).

        DATA(columns) = mr_bot_alv->get_columns( ).

        columns->get_column( CONV #( comps[ fieldname = 'CLNT' ]-fieldname )
           )->set_visible( abap_false ).

        columns->get_column( CONV #( comps[ fieldname = 'PROJECT' ]-fieldname )
           )->set_visible( abap_false ).

        columns->get_column( CONV #( comps[ fieldname = 'VAR_NAME' ]-fieldname )
           )->set_visible( abap_false ).
        columns->get_column( CONV #( comps[ fieldname = 'NPP' ]-fieldname )
           )->set_visible( abap_false ).

        mr_bot_alv->get_display_settings( )->set_list_header(
          |Description: { ms_cdata-var_name }| ).
        mr_bot_alv->get_columns( )->set_optimize( ).
      CATCH cx_salv_error INTO DATA(ex2).
        DATA(msg) = ex2->get_message( ).
        MESSAGE ID msg-msgid TYPE 'I' NUMBER msg-msgno DISPLAY LIKE 'E'
          WITH msg-msgv1 msg-msgv2 msg-msgv3 msg-msgv4.
        EXIT.
    ENDTRY.

    mr_bot_alv->refresh( ).

  ENDMETHOD.


  METHOD constructor.

    mv_proj = iv_proj.
    mr_main_cont = NEW #( 'CONT_100' ).

  ENDMETHOD.


  METHOD exclude_tb_functions_tabname.
    APPEND '&CHECK' TO pt_exclude.
    APPEND '&REFRESH' TO pt_exclude.
    APPEND '&LOCAL&CUT' TO pt_exclude.
    APPEND '&LOCAL#' TO pt_exclude.
    APPEND '&LOCAL&PASTE' TO pt_exclude.
    APPEND '&LOCAL&UNDO' TO pt_exclude.
    APPEND '&DETAIL' TO pt_exclude.
    APPEND '&LOCAL&COPY_ROW' TO pt_exclude.
    APPEND '&LOCAL&INSERT_ROW' TO pt_exclude.
    APPEND '&SORT_ASC' TO pt_exclude.
    APPEND '&SORT_DSC' TO pt_exclude.
    APPEND '&FIND' TO pt_exclude.
    APPEND '&FIND_MORE' TO pt_exclude.
    APPEND '&MB_FILTER' TO pt_exclude.
    APPEND '&MB_SUM' TO pt_exclude.
    APPEND '&MB_SUBTOT' TO pt_exclude.
    APPEND '&PRINT_BACK' TO pt_exclude.
    APPEND '&MB_VIEW' TO pt_exclude.
    APPEND '&MB_EXPORT' TO pt_exclude.
    APPEND '&MB_VARIANT' TO pt_exclude.
    APPEND '&GRAPH' TO pt_exclude.
    APPEND '&INFO' TO pt_exclude.
  ENDMETHOD.


  METHOD exit.

    DATA    : lv_mess_return(1)
            , lv_changed(1)
            .


    FIELD-SYMBOLS
                   : <old> TYPE table
                   , <tabdata> TYPE table
                   .
    LOOP AT mt_data ASSIGNING FIELD-SYMBOL(<fs_data>) .
      ASSIGN <fs_data>-old->* TO <old>.
      ASSIGN <fs_data>-datatab->* TO <tabdata>.

      IF <old> NE <tabdata>.
        lv_changed = 'X'.
      ENDIF.
    ENDLOOP.

    IF lv_changed IS NOT INITIAL.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Данные изменены'
          text_question         = 'Сохранить изменения?'
          text_button_1         = 'Да'
          text_button_2         = 'Нет'
          default_button        = '1'
          display_cancel_button = abap_false
          start_column          = 25
          start_row             = 6
          popup_type            = 'ICON_MESSAGE_WARNING'
        IMPORTING
          answer                = lv_mess_return
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.

      IF lv_mess_return = '1'.
        save( ).
      ENDIF.

    ENDIF.

    SET SCREEN 0.
  ENDMETHOD.


  METHOD history.
    FIELD-SYMBOLS
                      : <fs_data> TYPE STANDARD TABLE
                      , <fs_hist> TYPE STANDARD TABLE
                      .

    DATA
          : ls_hdr TYPE ztb_set_hist_hdr
          .

    IF ms_cdata IS INITIAL.
      MESSAGE 'Выберите таблицу для редактирования' TYPE 'S' DISPLAY LIKE 'W'.
      EXIT.
    ENDIF.


    ASSIGN ms_cdata-datatab->* TO  <fs_data>.


    CREATE DATA hist_data LIKE <fs_data>.
    ASSIGN hist_data->* TO  <fs_hist>.

    mr_gs->prepare_hist( ms_cdata-var_name ).

     mr_gs->get_version(
      EXPORTING
        iv_sign = 1
      IMPORTING
        ev_hdr  = ls_hdr
      CHANGING
        cv_data = hist_data ).

    hist_max = ls_hdr-version.



    cl_salv_table=>factory( IMPORTING r_salv_table  = hist_alv
                            CHANGING  t_table       = <fs_hist> ).

    hist_alv->set_screen_status( report        = mc_status-hist_prog
                                pfstatus      = mc_status-hist_stat
                                set_functions = cl_salv_model_base=>c_functions_all ).


    SET HANDLER on_user_command FOR hist_alv->get_event( ).


    hist_alv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).

    DATA l_title TYPE lvc_title.

    l_title = |{ ms_cdata-var_name } { ls_hdr-cruser  } { ls_hdr-crdate DATE = ENVIRONMENT } { ls_hdr-crtime TIME = ENVIRONMENT } { ls_hdr-version }/{ hist_max }|.
    hist_alv->get_display_settings( )->set_list_header( l_title ).
    hist_alv->get_display_settings( )->set_striped_pattern( abap_true ).
    hist_alv->get_columns( )->set_optimize( abap_true ).

    hist_alv->display( ).

    FREE
    : hist_data
    , hist_alv
    .
  ENDMETHOD.


  METHOD instance_build.

    CHECK instance->mv_first_run IS INITIAL.
    instance->mv_first_run = 'X'.

    instance->load_data( ).
    instance->build_alv( ).

  ENDMETHOD.


  method LOAD_DATA.

    mr_gs = NEW  zcl_gs( mv_proj ).

    SELECT *
      FROM ztb_set_variable
      INTO CORRESPONDING FIELDS OF TABLE mt_dir
      WHERE project  = mv_proj.

  endmethod.


  METHOD main.

    CLEAR instance.
    instance = NEW #( iv_proj ).

  ENDMETHOD.


  METHOD on_left_link_click.
    IF instance IS BOUND.
      IF instance->mr_right_alv IS BOUND.
        instance->mr_right_alv->check_changed_data( ).
      ENDIF.
    ENDIF.

    choose( row ).
  ENDMETHOD.


  METHOD on_user_command.

    DATA
              : lv_i TYPE i
              , l_title TYPE lvc_title
              , ls_hdr TYPE ztb_set_hist_hdr
              .

    FIELD-SYMBOLS
                   : <fs_data> TYPE STANDARD TABLE
                   .

    CASE e_salv_function.
      WHEN 'PREV'.
        lv_i = -1.
      WHEN 'NEXT'.
        lv_i = 1.

    ENDCASE.

    CALL METHOD mr_gs->get_version
      EXPORTING
        iv_sign = lv_i
      IMPORTING
        ev_hdr  = ls_hdr
      CHANGING
        cv_data = hist_data.

    ASSIGN hist_data->* TO <fs_data>.


    l_title = |{ ms_cdata-var_name } { ls_hdr-cruser  } { ls_hdr-crdate DATE = ENVIRONMENT } { ls_hdr-crtime TIME = ENVIRONMENT } { ls_hdr-version }/{ hist_max }|.
    hist_alv->get_display_settings( )->set_list_header( l_title ).
    hist_alv->get_display_settings( )->set_striped_pattern( abap_true ).

*    hist_alv->set_data( CHANGING t_table = <fs_data> ).
    hist_alv->get_columns( )->set_optimize( abap_true ).
    hist_alv->refresh( refresh_mode = if_salv_c_refresh=>full ).

  ENDMETHOD.


  METHOD pai.

    IF instance IS BOUND.
      IF instance->MR_RIGHT_ALV IS BOUND.
        instance->MR_RIGHT_ALV->check_changed_data( ).
      ENDIF.
    ENDIF.


    CASE sy-ucomm.
      WHEN mc_func-exit.
        instance->exit( ).

      WHEN mc_func-save.
        instance->save( ).

      WHEN mc_func-history.
        instance->history( ).


      WHEN OTHERS.
    ENDCASE.

  ENDMETHOD.


  METHOD pbo.

    CHECK instance IS  BOUND.
    instance_build(   ).

  ENDMETHOD.


  METHOD save.

    FIELD-SYMBOLS
                     : <fs_table> TYPE STANDARD TABLE
                     , <old> TYPE STANDARD TABLE
                     .

    LOOP AT mt_data ASSIGNING FIELD-SYMBOL(<fs_data>) .

      ASSIGN <fs_data>-datatab->* TO <fs_table>.
      ASSIGN <fs_data>-old->* TO <old>.

      CHECK <fs_table> NE <old>.

      mr_gs->save_object( iv_var_name = <fs_data>-var_name
                          iv_data     =  <fs_table> ).

      <old> = <fs_table>.

    ENDLOOP.

    load_data( ).
    mr_left_alv->refresh( ).

  ENDMETHOD.
ENDCLASS.
