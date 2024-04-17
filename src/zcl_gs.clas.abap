class ZCL_GS definition
  public
  final
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !IV_PROJECT type AKB_PROJECT_NAME .
  methods SAVE_OBJECT
    importing
      !IV_VAR_NAME type RS38L_PAR_
      !IV_DATA type DATA .
  methods GET_OBJECT
    importing
      !IV_VAR_NAME type RS38L_PAR_
    exporting
      value(EV_DATA) type DATA .
  methods GET_OBJECT_TABLE
    importing
      !IV_VAR_NAME type RS38L_PAR_
    exporting
      value(EV_DATA) type ref to DATA
      !EV_SINGLE_VAR type XFELD .
  methods PREPARE_HIST
    importing
      !IV_VAR_NAME type RS38L_PAR_ .
  methods GET_VERSION
    importing
      !IV_SIGN type I
    exporting
      !EV_HDR type ZTB_SET_HIST_HDR
    changing
      !CV_DATA type ref to DATA .
protected section.
private section.

  data MV_PROJECT type AKB_PROJECT_NAME .
  data MT_VAR type ZTT_SET_VARIABLE .
  data MT_HIST type ZTT_SET_HIST_HDR .
  data MV_VERSION type BRF_EXPRESSION_VERSION .
  data MV_VAR type RS38L_PAR_ .
  data MV_SINGLE_VALUE type XFELD .

  methods GET_JSON_FROM_DB
    importing
      !IV_VAR_NAME type RS38L_PAR_
    returning
      value(RV_JSON) type STRING .
  methods SAVE_JSON_TO_DB
    importing
      value(IV_JSON) type STRING
      !IV_VAR_NAME type RS38L_PAR_ .
  methods CREATE_DATA
    importing
      !IV_VAR_NAME type RS38L_PAR_
    exporting
      value(EV_DATA) type ref to DATA
      !EV_SINGLE_VAR type XFELD .
  methods GET_JSON_FROM_DB_HIST
    importing
      !IV_GUID type GUID
    returning
      value(RV_JSON) type STRING .
ENDCLASS.



CLASS ZCL_GS IMPLEMENTATION.


  METHOD constructor.

    mv_project = iv_project.

    SELECT * INTO TABLE mt_var
      FROM  ztb_set_variable
      WHERE project = iv_project.

  ENDMETHOD.


  METHOD create_data.

    DATA
          : lt_comp_tab    TYPE cl_abap_structdescr=>component_table
          , ls_comp        LIKE LINE OF lt_comp_tab
          , lr_struct_type TYPE REF TO cl_abap_structdescr
          , lr_dref_tmp TYPE REF TO data
          , lr_data TYPE REF TO data
          , lv_count type i

          .

    FIELD-SYMBOLS
                   : <fs_struct> TYPE any
                   .

    READ TABLE mt_var ASSIGNING FIELD-SYMBOL(<fs_var>) WITH KEY var_name = iv_var_name.
    CHECK sy-subrc = 0.

    DATA(lr_typedescr) = cl_abap_typedescr=>describe_by_name( <fs_var>-var_type ).

    select count( * )
      from  dd02l
      into lv_count
      where tabname = <fs_var>-var_type.

    IF sy-subrc ne 0.

      EV_SINGLE_VAR = 'X'.

      REFRESH lt_comp_tab.
      ls_comp-name = 'TABLELINE'.
      ls_comp-type ?= lr_typedescr.

      APPEND ls_comp TO lt_comp_tab.
      lr_struct_type = cl_abap_structdescr=>get( lt_comp_tab ).

      CREATE DATA lr_dref_tmp TYPE HANDLE lr_struct_type.
      ASSIGN lr_dref_tmp->* TO <fs_struct>.

      CREATE DATA lr_data LIKE TABLE OF <fs_struct>.

      EV_DATA = lr_data.


    ELSE.

      TRY .
          CREATE DATA lr_data TYPE TABLE OF (<fs_var>-var_type).
          EV_DATA = lr_data.
        CATCH cx_sy_create_data_error INTO DATA(ex).
          MESSAGE ex->get_text( ) TYPE 'I' DISPLAY LIKE 'E'.
          EXIT.
      ENDTRY.

    ENDIF.

  ENDMETHOD.


  METHOD get_json_from_db.

    DATA
          : lt_val TYPE TABLE OF ztb_set_values
          .

    SELECT * INTO TABLE lt_val
      FROM ztb_set_values
      WHERE project = mv_project
      AND var_name = iv_var_name
      ORDER BY npp.

    LOOP AT lt_val ASSIGNING FIELD-SYMBOL(<fs_val>).
      rv_json = |{ rv_json }{ <fs_val>-value }|.
    ENDLOOP.

  ENDMETHOD.


  METHOD GET_JSON_FROM_DB_HIST.

    DATA
          : lt_val TYPE TABLE OF ZTB_SET_HIST_VAL
          .

    SELECT * INTO TABLE lt_val
      FROM ZTB_SET_HIST_VAL
      WHERE guid = iv_guid
      ORDER BY npp.

    LOOP AT lt_val ASSIGNING FIELD-SYMBOL(<fs_val>).
      rv_json = |{ rv_json }{ <fs_val>-value }|.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_object.

    DATA
          : lv_single_val TYPE xfeld
          , lr_data TYPE REF TO data
          , lr_tmp_data TYPE REF TO data
          .

    FIELD-SYMBOLS
                   : <fs_data> TYPE STANDARD  TABLE
                   .

    READ TABLE mt_var ASSIGNING FIELD-SYMBOL(<fs_var>) WITH KEY var_name = iv_var_name.
    CHECK sy-subrc = 0.

    get_object_table( EXPORTING iv_var_name = iv_var_name
                      IMPORTING ev_data  = lr_data
                                ev_single_var = lv_single_val ).

    ASSIGN lr_data->* TO <fs_data>.

    IF <fs_var>-is_table IS NOT INITIAL.
      ev_data = <fs_data>.
      RETURN.
    ENDIF.

    READ TABLE <fs_data> ASSIGNING FIELD-SYMBOL(<fs_line>) INDEX 1.

    IF sy-subrc NE 0.

      CREATE DATA lr_tmp_data LIKE LINE OF <fs_data>.
      ASSIGN lr_tmp_data->* TO <fs_line>.

    ENDIF.

    IF lv_single_val IS INITIAL .
      ev_data = <fs_line>.
      RETURN.
    ENDIF.

    ASSIGN COMPONENT 1 OF STRUCTURE <fs_line> TO  FIELD-SYMBOL(<fs_value>).
    ev_data = <fs_value>.

  ENDMETHOD.


  METHOD get_object_table.

    DATA
          : lv_single_val TYPE xfeld
          , lv_json TYPE string
          .

    FIELD-SYMBOLS
                   : <fs_data> TYPE STANDARD  TABLE
                   .

    READ TABLE mt_var ASSIGNING FIELD-SYMBOL(<fs_var>) WITH KEY var_name = iv_var_name.
    CHECK sy-subrc = 0.

    create_data( EXPORTING iv_var_name = iv_var_name
                 IMPORTING ev_data = ev_data
                           ev_single_var = ev_single_var ).


    ASSIGN ev_data->* TO <fs_data>.


    lv_json  = get_json_from_db( iv_var_name ).

    CHECK lv_json IS NOT INITIAL.

    /ui2/cl_json=>deserialize(
  EXPORTING
    json = lv_json
    pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
  CHANGING
    data =   <fs_data> ).

  ENDMETHOD.


  METHOD get_version.

    FIELD-SYMBOLS
               : <fs_data> TYPE STANDARD  TABLE
               .

    DATA
          : lv_version  TYPE brf_expression_version
          , lv_json TYPE string
          .


    ASSIGN cv_data->* TO <fs_data>.
    REFRESH <fs_data>.


    lv_version = mv_version + iv_sign.

    READ TABLE mt_hist ASSIGNING FIELD-SYMBOL(<fs_hist>) WITH KEY version = lv_version.

    IF sy-subrc = 0 .
      mv_version = lv_version.
    ELSE.
      READ TABLE mt_hist ASSIGNING <fs_hist> WITH KEY version = mv_version.
    ENDIF.

    CHECK sy-subrc = 0.

    ev_hdr = <fs_hist>.

    lv_json = get_json_from_db_hist( <fs_hist>-guid ).

    CHECK lv_json IS NOT INITIAL.

    /ui2/cl_json=>deserialize(
  EXPORTING
    json = lv_json
    pretty_name      = /ui2/cl_json=>pretty_mode-camel_case
  CHANGING
    data =   <fs_data> ).

  ENDMETHOD.


  METHOD prepare_hist.

    REFRESH mt_hist.

    CLEAR : mv_version
          , mv_var
          .


    READ TABLE mt_var ASSIGNING FIELD-SYMBOL(<fs_var>) WITH KEY var_name = iv_var_name.
    CHECK sy-subrc = 0.


    SELECT * INTO TABLE mt_hist
      FROM ztb_set_hist_hdr
      WHERE project = mv_project AND
            var_name  = iv_var_name.


    SELECT SINGLE version INTO mv_version
      FROM ztb_set_variable
      WHERE project = mv_project AND
          var_name  = iv_var_name.

    mv_var = iv_var_name.



  ENDMETHOD.


  METHOD save_json_to_db.


    DATA
          : lt_val TYPE TABLE OF ztb_set_values
          , lv_npp TYPE i
          , ls_set_variable TYPE ztb_set_variable
          , ls_hdr TYPE ztb_set_hist_hdr
          , lt_hist TYPE TABLE OF ztb_set_hist_val
          .

    SELECT SINGLE * INTO ls_set_variable
      FROM ztb_set_variable
      WHERE project = mv_project AND
            var_name = iv_var_name.


    ls_set_variable-version = ls_set_variable-version + 1.


    ls_hdr-project = mv_project.
    ls_hdr-var_name = iv_var_name.
    ls_hdr-version =  ls_set_variable-version.

    TRY.
        ls_hdr-guid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
    ENDTRY.

    ls_hdr-cruser = sy-uname.
    ls_hdr-crdate = sy-datum.
    ls_hdr-crtime = sy-uzeit.

    WHILE strlen( iv_json ) > 255.
      ADD 1 TO lv_npp.
      APPEND INITIAL LINE TO lt_val ASSIGNING FIELD-SYMBOL(<fs_val>).
      <fs_val>-project = mv_project.
      <fs_val>-var_name = iv_var_name.
      <fs_val>-npp = lv_npp.
      <fs_val>-value = iv_json.

      APPEND INITIAL LINE TO lt_hist ASSIGNING FIELD-SYMBOL(<fs_hist>).

      <fs_hist>-guid = ls_hdr-guid.
      <fs_hist>-npp = lv_npp.
      <fs_hist>-value = iv_json.

      iv_json = iv_json+255.
    ENDWHILE.

    IF strlen( iv_json ) > 0.
      ADD 1 TO lv_npp.
      APPEND INITIAL LINE TO lt_val ASSIGNING <fs_val>.
      <fs_val>-project = mv_project.
      <fs_val>-var_name = iv_var_name.
      <fs_val>-npp = lv_npp.
      <fs_val>-value = iv_json.

      APPEND INITIAL LINE TO lt_hist ASSIGNING <fs_hist>.
      <fs_hist>-guid = ls_hdr-guid.
      <fs_hist>-npp = lv_npp.
      <fs_hist>-value = iv_json.

    ENDIF.

    DELETE FROM ztb_set_values
    WHERE project = mv_project
    AND   var_name = iv_var_name.


    MODIFY ztb_set_variable FROM ls_set_variable.
    INSERT ztb_set_values FROM TABLE lt_val.
    INSERT ztb_set_hist_hdr FROM ls_hdr.
    INSERT ztb_set_hist_val FROM TABLE lt_hist.

    COMMIT WORK.

  ENDMETHOD.


  METHOD save_object.

    DATA(lv_json) = /ui2/cl_json=>serialize( data        = iv_data
                                       pretty_name = /ui2/cl_json=>pretty_mode-camel_case ).

    save_json_to_db( iv_json    = lv_json
                    iv_var_name = iv_var_name ).

  ENDMETHOD.
ENDCLASS.
