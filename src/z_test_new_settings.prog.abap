*&---------------------------------------------------------------------*
*& Report  Z_TEST_NEW_SETTINGS
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT Z_TEST_NEW_SETTINGS.

DATA
      : lr_gs TYPE REF TO zcl_gs " settings object

*        variable to hold settings data
      , lv_data  TYPE datum
      , lv_struct TYPE SCARR
      , lt_table_of_date  TYPE TABLE OF datum
      , lt_table_of_struct TYPE TABLE OF SCARR
      .

START-OF-SELECTION.
*create object
  lr_gs  = NEW zcl_gs( 'FIRST_PROJECT' ).
*read settings
  lr_gs->get_object( EXPORTING iv_var_name =  'DATE'
                     IMPORTING ev_data     =   lv_data ).

  lr_gs->get_object( EXPORTING iv_var_name =  'STRUCT'
                     IMPORTING ev_data     =   lv_struct ).

  lr_gs->get_object( EXPORTING iv_var_name =  'TABLE_OF_DATE'
                     IMPORTING ev_data     =   lt_table_of_date ).

  lr_gs->get_object( EXPORTING iv_var_name =  'TABLE_OF_STRUCT'
                     IMPORTING ev_data     =   lt_table_of_struct ).
*обрабатываем
  cl_demo_output=>write( lv_data ).
  cl_demo_output=>write( lv_struct ).
  cl_demo_output=>write( lt_table_of_date ).
  cl_demo_output=>write( lt_table_of_struct ).

  cl_demo_output=>display( ).
